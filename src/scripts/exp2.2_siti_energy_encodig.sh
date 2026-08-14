#!/bin/bash

source base.sh

function sanity_check_compose() {
    # Para capturar un array pasado como argumento, capturamos todos los argumentos a partir del $2
    experiment_name=$1
    shift # Eliminamos el primer argumento ($1)
        containerList=("$@") # Ahora containerList vuelve a ser un array con el resto de parámetros
    if [ -z "$experiment_name" ]; then
        echo "!!! Especifica un nombre de experimento !!!!"
        exit 1
    fi

    for container in "${containerList[@]}"; do
        if ! sanity_check $container; then
            echo "Container $container not running"
            echo "Stopping the script..."
            exit 1
        fi
    done
    
    container_compose=$(docker ps --format json | grep compose | jq -r '.Names')
    # Nota: Corregido operador OR para evaluar correctamente las exclusiones
    if [[ "${container_compose}" != *mongodb* && "${container_compose}" != *global-energy-mon* && "${container_compose}" != *container-energy-mon* ]]; then
        echo "Toolkit Compose No Encendida"
        exit 1
    fi
}


function codification_experiment() {
    nombre_video=$1
    codec=$2
    bitrate=$3
    results_path=$4
    videoTranscodingPath="/config/transcoding-results"
    shift 4
    containerList=("$@")
    
    slime_video_name=$(echo "$nombre_video" | cut -d '_' -f1,4,6,7 | cut -d '.' -f1)
    hw_aceleration=$([[ "${results_path}" != *cpu* ]] && echo "gpu" || echo "cpu")
    base_file_name="${slime_video_name}-${hw_aceleration}-${codec}-bitrate_${bitrate}"
    
    infoFile="${results_path}/${base_file_name}-info.txt"
    globalFile="${results_path}/${base_file_name}-global.json"
    
    
    # CODIFICATION WORKLOAD
    workload_command="sleep 1.5; ffmpeg -y -i /config/${nombre_video} -c:v ${codec} -b:v ${bitrate}M -c:a copy ${videoTranscodingPath}/${base_file_name}-transcoded.mp4; sleep 1.5"
 
    # Global energy capture
    curl -s http://localhost:6000/api/start 
    echo ""
    

    idList=()
    uuidList=()
    csvFileList=()
    payloadsList=()
    
    for container in "${containerList[@]}"; do
        csvFile="${results_path}/${base_file_name}-${container}-samples.csv"
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
        sleep 2
        
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
        echo "Command: $workload_command" > ${infoFile}
        docker exec ${containerList[$i]} sh -c "ls -al ${videoTranscodingPath}/${base_file_name}-transcoded.mp4" >> ${infoFile}
        echo "Output: $output" >> ${infoFile}
        docker exec ${containerList[$i]} sh -c "ffprobe -v error -select_streams v -of default=noprint_wrappers=1:nokey=1 -show_entries stream=r_frame_rate,width,height,duration,bit_rate ${videoTranscodingPath}/${base_file_name}-transcoded.mp4" >> ${infoFile}
        curl -s http://localhost:5000/api/monitor/workload/${uuidList[$i]}/samples > ${csvFileList[$i]}
    done
}


containerList=("ffmpeg-encoder")
sanity_check_compose "$1" "${containerList[@]}"

#BIT RATE DE CODIFICACION
bitrate_264=(10 20 25 30 35 40 50) 
bitrate_265=(10 15 20 25 30 35 40)
#bitrate_264=(40) 
#bitrate_265=(40)
#CODECS A UTILIZAR
codecs_cpu_list=("libx264" "libx265")
codecs_gpu_list=("h264_nvenc" "hevc_nvenc")

#ESQUEMA DE DIRECTORIO DE RESULTADOS
experiment_name="$1" # NOMBRE DEL EXPERIMENTO 
workdir_results="$(pwd)/metricas"
kind_codificacion=("gpu" "cpu" )
video_test=($(ls $HOME/Documentos/Experiments/exp2/videos/siti-videos | grep -v 'transcoding-results'))
#video_test=(LifeUntouched_CableLabs_3840x2160_chunk0000_10s_LTI_LSI.mp4 LifeUntouched_CableLabs_3840x2160_chunk0048_10s_LTI_LSI.mp4 LifeUntouched_CableLabs_3840x2160_chunk0053_10s_LTI_LSI.mp4 LifeUntouched_CableLabs_3840x2160_chunk0055_10s_LTI_LSI.mp4 LifeUntouched_CableLabs_3840x2160_chunk0056_10s_LTI_LSI.mp4 LifeUntouched_CableLabs_3840x2160_chunk0075_10s_LTI_LSI.mp4)

echo "***  EXPERIMENTO ${experiment_name} ***"
#EXPERIMENTACION
for kind in "${kind_codificacion[@]}"; do 
    codec_iter=(${codecs_cpu_list[@]})

    if [ "$kind" == "gpu" ]; then
        codec_iter=(${codecs_gpu_list[@]})
    fi

    for codec in "${codec_iter[@]}"; do 
        for video in "${video_test[@]}"; do
            
            #DIFINICON BIT RATE SEGUN CODEC
            bitrate_list=("${bitrate_264[@]}")
            if [[ "$codec" == "libx265" || "$codec" == "hevc_nvenc" ]]; then
                bitrate_list=("${bitrate_265[@]}")
            fi
            for bitrate in "${bitrate_list[@]}"; do 
                slime_video_name=$(echo "$video" | cut -d '_' -f1,2,4,6,7 | cut -d '.' -f1)
                results_path="${workdir_results}/${experiment_name}/${kind}/${slime_video_name}/${codec}/Bitrate-${bitrate}"
                echo "${results_path}"
                mkdir -p "${results_path}"
                
                echo ""
                echo "*** CODIFCANDO VIDEOS ${slime_video_name} con ${codec} a ${bitrate} Mbps usando ${kind} ***"
                codification_experiment "${video}" "${codec}" "${bitrate}" "${results_path}" "${containerList[@]}"
                echo "*** FIN CODIFICACION ***"
                echo ""
                sleep 10
            done
        done

    done
    
done
$HOME/.own-code/remote-alerts/telegra-alerts.sh "Fin Life Experiment"

exit 0
