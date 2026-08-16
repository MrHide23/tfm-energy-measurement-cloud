#!/bin/bash

source ./base.sh

function sanity_check_compose() {
    containerList=("$@") # Ahora containerList vuelve a ser un array con el resto de parámetros
    
    for container in "${containerList[@]}"; do
        if ! sanity_check $container; then
            echo "*** Container $container not running ***"
            echo "*** - Stopping the script... ***"
            exit 1
        fi
    done

    container_compose=$(docker ps --format json | grep compose | jq -r '.Names')
    # Nota: Corregido operador OR para evaluar correctamente las exclusiones
    if [[ "${container_compose}" != *mongodb* && "${container_compose}" != *global-energy-mon* && "${container_compose}" != *container-energy-mon* ]]; then
        echo "*** Toolkit Compose No Encendida ***"
        exit 1
    fi
}

function wake_up_containers() {
    num_containers=$1
    cpus=$2
    workdir_videos="${VIDEOS_EXP2}"
    echo "${workdir_videos}"
    num_containers=$(seq 1 ${num_containers})
    for n in "${num_containers[@]}"; do
        #NO del TOdo COrrecto
        name="ffmpeg-encoder-${cpus}cores-nc${n}"
        if ! docker inspect ${name} >/dev/null 2>&1; then
            total_cores="$(lscpu -e=CPU -J | jq -r '.cpus.[-1].cpu')"
            first=${LAST_CPU_ASIGNED}
            last=$((LAST_CPU_ASIGNED + cpus))
            
            #En caso de no requerir limitaciones de CPU
            if [[ ${cpus} -eq 0 ]]; then
                docker run -d \
                    --name "$name" \
                    -v "${workdir_videos}:/config" \
                    --runtime=nvidia \
                    --entrypoint sleep \
                    linuxserver/ffmpeg:8.0.1 \
                    432000
                    lsat=$((total_cores-1))
            else 
                cpuset="${first}-${last}"
                
                # Comprobar si quedan cores suficientes
                if (( ${LAST_CPU_ASIGNED} + cpus > total_cores )); then
                    echo "ERROR: No hay suficientes cores para ${name}"
                    echo "Necesita ${cpus}, quedan $((total_cores-LAST_CPU_ASIGNED))"
                    exit 1
                fi
                
                docker run -d \
                    --name "$name" \
                    --cpus="$cpus" \
                    --cpuset-cpus="$cpuset" \
                    -v "${workdir_videos}:/config" \
                    --runtime=nvidia \
                    --entrypoint sleep \
                    linuxserver/ffmpeg:8.0.1 \
                    432000
                
            fi
            export LAST_CPU_ASIGNED=$(( last + 1 ))
        else
            docker start "$name"
        fi

        containerList+=("${name}")
        echo "*** Container ${name} arrancado -> cores ${cpus} ***"
    done
    sleep 1
}

function kill_container() {
    container_name="$1"
    docker stop ${container_name}
    docker rm ${container_name}
    sleep 1
}

function codification_experiment() {
    final_data_path=$1
    shift
    containerList=("$@")

    videoTranscodingPath="/config/transcoded"
    
    #EXTRACCION Informacion
    codec="$(cut -d '/' -f13 <<< ${final_data_path})"
    bitrate="$(grep -oE "Bitrate-[[:digit:]]{2,4}" <<< ${final_data_path} | tr -d 'Bitrate-' )"
    nombre_video="$(cut -d '/' -f11 <<< ${final_data_path})"
    slime_video_name=$(cut -d '_' -f1,4,5,6 <<< ${nombre_video} | cut -d '.' -f1)
    thr="$(grep -oE '[[:digit:]]{1,4}cores' <<< ${final_data_path} | tr -d 'cores')"
    final_data_path="$(sed "s/${nombre_video}/${slime_video_name}/g" <<< ${final_data_path})"

    hw_aceleration=$([[ "${final_data_path}" != *cpu* ]] && echo "gpu" || echo "cpu")
    base_file_name="${slime_video_name}-${hw_aceleration}-${thr}cores-${codec}-bitrate_${bitrate}"

    infoFile="${final_data_path}/${base_file_name}-info.txt"
    globalFile="${final_data_path}/${base_file_name}-global.json"

    #Create final path data
    mkdir -p ${final_data_path}

    # CODIFICATION WORKLOAD
    workload_command="sleep 1.5; ffmpeg -y -i /config/${nombre_video} -c:v ${codec}"
    
    if [ $thr -gt 0 ]; then
        if [[ $codec == "libx264" ]]; then
            workload_command+=" -threads ${thr}"
        elif [[ $codec == "libx265" ]]; then
            workload_command+=" -x265-params pools=${thr}"
        else
            workload_command+=" -cpucount ${thr}"
        fi
    fi
    
    workload_command+=" -b:v ${bitrate}M -c:a copy ${videoTranscodingPath}/${base_file_name}-transcoded.mp4; sleep 1.5"

    # Global energy capture
    curl -s http://localhost:6000/api/start
    echo ""

    idList=()
    uuidList=()
    csvFileList=()
    payloadsList=()

    for container in "${containerList[@]}"; do
        csvFile="${final_data_path}/${base_file_name}-${container}-samples.csv"
        uuidKey=$(uuid)
        payload="{
            \"workload_id\":\"${uuidKey}\",
            \"container\":\"${container}\",
            \"gpu_indices\":[0],
            \"persist_data\":0
        }"
        response=$(curl -s -H "Content-Type: application/json" -X POST -d "$payload" http://localhost:5000/api/monitor)
        id=$(echo "$response" | jq -r '.id')
        echo "  * Monitoring container -- $id || PROCES: ${uuidKey}"

        docker exec -d $container sh -c "$workload_command"

        idList+=("${id}")
        uuidList+=("${uuidKey}")
        csvFileList+=("${csvFile}")
        payloadsList+=("${payload}")
    done

    sleep 2
    # Esperando finalizacion
    for cont in "${containerList[@]}"; do
        wait_to_finish $cont ffmpeg
    done

    curl -s http://localhost:6000/api/stop > ${globalFile}
    
    for i in "${!idList[@]}"; do
        output=$(curl -s -X DELETE http://localhost:5000/api/monitor\?id\=${idList[$i]})
        echo "Command: ${workload_command}" > ${infoFile}
        docker exec ${containerList[$i]} sh -c "ls -al ${videoTranscodingPath}/${base_file_name}-transcoded.mp4" >> ${infoFile}
        echo "Output: ${output}" >> ${infoFile}
        docker exec ${containerList[$i]} sh -c "ffprobe -v error -select_streams v -of default=noprint_wrappers=1:nokey=1 -show_entries stream=r_frame_rate,width,height,duration,bit_rate -of default=noprint_wrappers=1 ${videoTranscodingPath}/${base_file_name}-transcoded.mp4" >> ${infoFile}
        curl -s http://localhost:5000/api/monitor/workload/${uuidList[$i]}/samples > ${csvFileList[$i]}
    done
}

n_containers=1 #Numero de Contenedores que van a ser lanzados
bitrate_264=(10 30)
bitrate_265=(10 30)

#CODECS A UTILIZAR
codecs_cpu_list=("libx264" "libx265")
codecs_gpu_list=("h264_nvenc" "hevc_nvenc")

#ESQUEMA DE DIRECTORIO DE RESULTADOS
experiment_name="$1" # NOMBRE DEL EXPERIMENTO
workdir_results="$(pwd)/metricas"
hw_base=("cpu" "gpu")

# 0 --> No limitacion de CPU
# N --> Limitacion de N cpus y N threads
cpu_threads=(0 1 3 6 7) 

video_test=($(ls "${VIDEOS_EXP2}" | grep -v 'transcoded'))
#video_test=(Eldorado_CableLabs_3840x2160_chunk0010_30fps_30s_HTI_HSI.mp4)
echo "***  EXPERIMENTO ${experiment_name} ***"
#EXPERIMENTACION
for hw in "${hw_base[@]}"; do
    for thr in "${cpu_threads[@]}"; do
        containerList=()
        export LAST_CPU_ASIGNED=0 #Ultima CPU asignada
        wake_up_containers "${n_containers}" "${thr}"

        codec_iter=(${codecs_cpu_list[@]})

        if [ "$hw" == "gpu" ]; then
            codec_iter=(${codecs_gpu_list[@]})
        fi

        echo "*** ITERACION ${experiment_name} CON ${thr} treads y cores START ***"
        for codec in "${codec_iter[@]}"; do
            for video in "${video_test[@]}"; do

                #DIFINICON BIT RATE SEGUN CODEC
                bitrate_list=("${bitrate_264[@]}")
                if [[ "$codec" == "libx265" || "$codec" == "hevc_nvenc" ]]; then
                    bitrate_list=("${bitrate_265[@]}")
                fi
                for bitrate in "${bitrate_list[@]}"; do
                    results_path="${workdir_results}/${experiment_name}/${hw}/${video}/${thr}cores/${codec}/Bitrate-${bitrate}"
                    echo ""
                    echo "*** CODIFCANDO VIDEOS ${video} con ${codec} a ${bitrate} Mbps usando ${hw} - Con ${thr} cores ***"
                    codification_experiment "${results_path}" "${containerList[@]}"
                    echo "*** FIN CODIFICACION ***"
                    echo ""
                    sleep 10
                    sanity_check_compose "${containerList[@]}"
                done
            done

        done

        echo "*** ITERACION ${experiment_name} CON ${thr} threads y cores END ***"
        echo ""
        for c in "${containerList[@]}"; do
            kill_container "$c"
        done

    done



done


exit 0
