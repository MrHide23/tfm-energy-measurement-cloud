#!/bin/bash

function sanity_check() {
    container=$1
    id=$(docker inspect $container 2> /dev/null | jq -r '.[0].Id' )
    [[ "$id" == "null"  ]] && return 1 || return 0
}

function wait_to_finish(){
    container=$1
    app=$2
    echo "Waiting for $app to finish in container $container"
    while [ -n "$(docker container top $container | grep $app)" ]; do
        sleep 0.5
    done
}

container="ffmpeg-encoder"

if ! sanity_check $container; then
    echo "Container $container not running"
    echo "Stopping the script..."
    exit 1
fi

repetition=$1

expName="ffmpeg-cpu"

folder="data/${expName}/rep${repetition}"
mkdir -p $folder

fname=$expName

# Names of the files
infoFile=${folder}/${fname}-info.txt
globalFile=${folder}/${fname}-global.json
csvFile=${folder}/${fname}-samples.csv

# Bit rate
br=6

uid=$(uuid)

payload='{"workload_id": "'$uid'",
   "container": "'$container'",
   "gpu_indices": [0],
   "persist_data": 0}'


# Global energy capture
curl -s http://localhost:6000/api/start

# Petición de monitorizacion

response=$(curl -s -H "Content-Type: application/json" -X POST -d "$payload" http://localhost:5000/api/monitor)
echo "Response -- ${response}"


id=$(echo "$response" | jq -r '.id')

echo "Monitoring container $id"

# Ejecución de tarea de codificación de vídeo
#libx264 hvenc_264
workload_command="sleep 1.5; ffmpeg -y -i /config/SkLab_3840x2160_crf0.mp4 -c:v libx264 -b:v 4M -vf scale=1280:720 -c:a copy /config/output.mp4 ; sleep 1.5"


docker exec -d $container sh -c "$workload_command"
sleep 5

# Espera activa
wait_to_finish $container ffmpeg

output="$(curl -s -X DELETE http://localhost:5000/api/monitor\?id\=$id)"

# Global energy capture stop
curl -s http://localhost:6000/api/stop > ${globalFile}

echo "Command: $workload_command" > ${infoFile}
docker exec $container sh -c "ls -al /config/output.mp4" >> ${infoFile}
echo "Output: $output" >> ${infoFile}
docker exec $container sh -c "ffprobe -v error -select_streams v -of default=noprint_wrappers=1:nokey=1 -show_entries stream=r_frame_rate,width,height,duration,bit_rate -of default=noprint_wrappers=1 /config/output.mp4" >> ${infoFile}

curl -s http://localhost:5000/api/monitor/workload/$uid/samples > ${csvFile}
