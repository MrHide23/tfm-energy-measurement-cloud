#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Numero de argumento incorrectos :- ("
    echo "***** Debes de indicar *****"
    echo "**\n Numero_Iteracion     **"
    exit 1
fi

#Funcion de stop until proceso finalice del todo
function function_Endding_Procces() {
    local container=$1
    echo "Codificacion en proceso en ${container}..."
    sleep 1
    while docker top ${container} | grep -q "ffmpeg"; do
        sleep 0.5
    done
    sleep 1
    echo "Codificacion Finalizada"
}


# +++++++++++ Toma de Medidas de Kepler +++++++++++++++++++++++++
iteracion=$1
kind_iter="cpu" 
dir="kepler/${kind}" # Ubicacion del ARCHIVO final
fem="em/${kind_iter}/em_kepler_${kind_iter}_${iteracion}.json" # Ubicacion archivos finales em
kepler_raw_results="$dir/zdirty_raw_kepler_${kind_iter}_${iteracion}.metrics" # RAW Data
final_results_csv="$dir/kepler_10_it_${kind_iter}.csv" #Nombre del arcohivo final resultante
container=("ffmpeg-encoder")

for c in ${container[@]}; do
    if ! docker ps --filter "name=${c}" --format "{{.Names}}" | grep -q "${c}"; then
        echo " *** ERROR: Contenedor ${c} apagado ***"
        exit 1
    else
        echo "Working ${c}"
    fi
done

sudo kepler --metrics=container --monitor.interval=1s --metrics=node --experimental.gpu.enabled > /dev/null &
sleep 1

# Iniciar metricas con EM
curl -s http://localhost:6000/api/start
echo "EM start...."; echo ""
codec="libx264" #h264_nvenc  libx264
for c in ${container[@]}; do
    echo "$c docker working"
    docker exec ${c} ffmpeg -y -i /config/SkLab_3840x2160_crf0.mp4 -c:v ${codec} -b:v 4M -vf scale=1280:720 -c:a copy /config/output.mp4 > /dev/null 2>&1 &
done       
#Funcion de stop until proceso finalice del todo
for c in "${container[@]}"; do
    function_Endding_Procces ${c}
done

echo "EM stop...."; echo ""
curl -s http://localhost:6000/api/stop | jq . > "${fem}"

curl -s http://localhost:28282/metrics > "$kepler_raw_results"

sudo pkill kepler 2>&1 &
exit 0
