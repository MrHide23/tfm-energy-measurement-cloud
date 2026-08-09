#!/bin/bash

sanity_check() {
    local container="$1"

    id=$(docker inspect "$container" 2>/dev/null | jq -r '.[0].Id')

    [[ -n "$id" && "$id" != "null" ]]
}

wait_to_finish() {
    local container="$1"
    local app="$2"

    echo "Waiting for $app to finish in container $container"

    while docker container top "$container" 2>/dev/null | grep -q "$app"; do
        sleep 0.5
    done
}

container1="ffmpeg-encoder-limited-1"
container2="ffmpeg-encoder-limited-2"

if ! sanity_check "$container1" || ! sanity_check "$container2"; then
    echo "Some container isn't running"
    echo "Stopping the script..."
    exit 1
fi

repetition="$1"

expName="ffmpeg-2_containers-limited-3_cores"

folder="data/${expName}/rep${repetition}"
mkdir -p "$folder"

fname="$expName"

infoFile="${folder}/${fname}-info.txt"
globalFile="${folder}/${fname}-global.json"

csvFile1="${folder}/${fname}-${container1}-samples.csv"
csvFile2="${folder}/${fname}-${container2}-samples.csv"

# Bit rate
br=6

uid1=$(uuid)
uid2=$(uuid)
echo "UUID 1 --> ${uid1} || UUID2 --> ${uid2}}"

payload1=$(cat <<EOF
{
    "workload_id":"$uid1",
    "container":"$container1",
    "gpu_indices":[0],
    "persist_data":0
}
EOF
)

payload2=$(cat <<EOF
{
    "workload_id":"$uid2",
    "container":"$container2",
    "gpu_indices":[0],
    "persist_data":0
}
EOF
)

# Global energy capture
curl -s http://localhost:6000/api/start

# Monitorización contenedor 1
response1=$(curl -s \
    -H "Content-Type: application/json" \
    -X POST \
    -d "$payload1" \
    http://localhost:5000/api/monitor)

id1=$(echo "$response1" | jq -r '.id')

echo "Response -- $response1"
echo "Monitoring container $container1 (id=$id1)"

# Monitorización contenedor 2
response2=$(curl -s \
    -H "Content-Type: application/json" \
    -X POST \
    -d "$payload2" \
    http://localhost:5000/api/monitor)

id2=$(echo "$response2" | jq -r '.id')

echo "Response -- $response2"
echo "Monitoring container $container2 (id=$id2)"

# Ejecución de tarea
workload_command="sleep 1.5; ffmpeg -y -i /config/SkLab_3840x2160_crf0.mp4 -c:v libx264 -b:v 4M -vf scale=1280:720 -c:a copy /config/output.mp4 ; sleep 1.5"

docker exec -d "$container1" sh -c "$workload_command"
docker exec -d "$container2" sh -c "$workload_command"

sleep 2

# Espera activa
wait_to_finish "$container1" ffmpeg
output1=$(curl -s -X DELETE "http://localhost:5000/api/monitor?id=${id1}")

wait_to_finish "$container2" ffmpeg
output2=$(curl -s -X DELETE "http://localhost:5000/api/monitor?id=${id2}")

# Global energy capture stop
curl -s http://localhost:6000/api/stop > "$globalFile"

# Guardar información
{
    echo "Command: $workload_command"
    echo

    echo "Container: $container1"
    docker exec "$container1" sh -c "ls -al /config/output.mp4"
    echo "Output: $output1"
    docker exec "$container1" sh -c \
        "ffprobe -v error \
        -select_streams v \
        -show_entries stream=r_frame_rate,width,height,duration,bit_rate \
        -of default=noprint_wrappers=1 \
        /config/output.mp4"

    echo
    echo "Container: $container2"
    docker exec "$container2" sh -c "ls -al /config/output.mp4"
    echo "Output: $output2"
    docker exec "$container2" sh -c \
        "ffprobe -v error \
        -select_streams v \
        -show_entries stream=r_frame_rate,width,height,duration,bit_rate \
        -of default=noprint_wrappers=1 \
        /config/output.mp4"

} > "$infoFile"

# Descargar muestras
echo "---1--- $csvFile1 -----"
curl -s \
    "http://localhost:5000/api/monitor/workload/${uid1}/samples" \
    > "$csvFile1"

echo "---2--- $csvFile2 -----"
curl -s \
    "http://localhost:5000/api/monitor/workload/${uid2}/samples" \
    > "$csvFile2"