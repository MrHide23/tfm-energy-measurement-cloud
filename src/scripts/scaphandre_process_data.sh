#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Numero de argumento incorrectos :- ("
    echo "***** Debes de indicar *****"
    echo "**\n Numero_Iteracion     **"
    exit 1
fi

iteracion=$1
herramienta="scp"
dir_root="$HOME/Documentos/Experiments/0_test_herramientas"
sub_dir="${dir_root}/${herramienta}/cpu"
kind_iter="cpu"

scapfile="$sub_dir/zdirty_raw_${herramienta}_${kind_iter}_${iteracion}.metrics" # RAW Data
final_results_csv="$sub_dir/${herramienta}_10_it_${kind_iter}.csv" #Nombre del arcohivo final resultante
fem="${dir_root}/em/cpu/em_${herramienta}_${kind_iter}_${iteracion}.json"
codec="libx264" #libx264 h264_nvenc
pids_list=$(cat ${scapfile} | grep scaph_process_power_consumption_microwatts |  grep "${codec}" | grep -v dockerexec | cut -d ' ' -f4 | jq -r ".pid" | sort -u)

if [[ ! -f "$final_results_csv" ]]; then
    echo "IT,pid,em_host,total_energy_host,cpu_usage_percentage,total_process_joules" > "$final_results_csv"
fi

echo "Processing Data...."
#Determinar Numero de procesos lanzados

for pid in ${pids_list[@]}; do
    # Porcentaje de Global segun EM
    em_host=$(cat $fem | jq ".total")
    # Porcentaje de CPU Usado en proceso
    cpu_usage=$(cat ${scapfile} | grep scaph_process_cpu_usage_percentage | grep "${codec}" | grep "${pid}" | grep -v dockerexec| cut -d '{' -f1 | cut -d '=' -f2 | tr -d ' ' | st-console --mean)
    # Consumo del Host
    scp_host=$(cat ${scapfile} | grep scaph_host_power_microwatts | cut -d '{' -f1 | cut -d '=' -f2 | tr -d ' ' | xargs -i echo "1*{}/1000000" | bc -l | st-console --sum)
    # Consumo del Proceso FFMPEG
    scp_process=$(cat ${scapfile} | grep scaph_process_power_consumption_microwatts | grep "${codec}" | grep "${pid}"  | grep -v dockerexec | cut -d '{' -f1 | cut -d '=' -f2 | tr -d ' ' | xargs -i echo "1*{}/1000000" | bc -l | st-console --sum )

    echo "${iteracion},${pid},${em_host},${scp_host},${cpu_usage},${scp_process}" >> "${final_results_csv}"

    echo "Resultados de proceso ${pid} en Iteracion $iteracion almacenados en $final_results_csv"
done
