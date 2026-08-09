#!/bin/bash
# 


if [ $# -lt 1 ]; then
    echo "Numero de argumento incorrectos :- ("
    echo "***** Debes de indicar *****"
    echo "**\n Numero_Iteracion     **"
    exit 1
fi

#Funcion de stop until proceso finalice del todo
function function_Endding_Procces() {
    local container=$1
    echo "Codificacion en proceso..."
    sleep 1
    while docker top ${container} | grep -q "ffmpeg"; do
        sleep 0.5
    done
    sleep 1
    echo "Codificacion Finalizada"
}

#Funcion para saber si el contenedor de scaphandre esta arrancado

function function_container_status() {
    local container=$1
    echo "Arrancando contenedor ${container}...."
    while ! docker ps --format json | grep -q "${container}"; do
        sleep 0.5
    done
    sleep 15
    echo "Contenedor ${container} arrancado"

}


# +++++++++++ Toma de Medidas de scaphandre +++++++++++++++++++++++++
iteracion=$1
fem="em/cpu/em_scp_cpu_${iteracion}.json"
dir="scp/cpu" # Ubicacion del ARCHIVO final
scapfile="$dir/zdirty_raw_scp_cpu_${iteracion}.metrics" # RAW Data
final_results_csv="$dir/scp_10_it_cpu.csv" #Nombre del arcohivo final resultante
container=("ffmpeg-encoder")
delta_t=1

for c in ${container[@]}; do
    if ! docker ps --filter "name=${c}" --format "{{.Names}}" | grep -q "${c}"; then
        echo " *** ERROR: Contenedor ${c} apagado ***"
        exit 1
    fi
done

docker start scaphandre
function_container_status "scaphandre"

docker exec -d scaphandre sh -c "scaphandre stdout -s ${delta_t} -t 200 --raw-metrics > out.metrics"
sleep 1

curl -s http://localhost:6000/api/start
echo "EM start...."; echo ""

codec="libx264" #h264_nvenc libx264
for c in ${container[@]}; do
    docker exec ${c} ffmpeg -y -i /config/SkLab_3840x2160_crf0.mp4 -c:v ${codec} -b:v 4M -vf scale=1280:720 -c:a copy /config/output.mp4 > /dev/null 2>&1 &
done  

#Funcion de stop until proceso finalice del todo
for c in ${container[@]}; do
    function_Endding_Procces ${c}
done

echo "EM stop...."; echo ""
curl -s http://localhost:6000/api/stop | jq . > "${fem}"
docker exec scaphandre sh -c "pkill -f scaphandre"

# ALMACENAMIENTO Y PROCESAMIENTO DE DATOS

# Get data from scaphandre
docker cp scaphandre:/app/out.metrics "${scapfile}"
# Change owner of file
sudo chown clouduser:clouduser "${scapfile}"
# Stop scaphandre container
docker stop scaphandre


exit 0
