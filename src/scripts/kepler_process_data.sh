#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Numero de argumento incorrectos :- ("
    echo "***** Debes de indicar *****"
    echo "**\n Numero_Iteracion     **"
    exit 1
fi

# function get_name_containers(){
#     containers_list=$1
#     name_all_containers_list=($(docker ps -a --format=json  | jq -r '.Names' | tr -d '/' ))
#     container_name_used_list=()
#     for cont_all in "${name_all_containers_list[@]}"; do
#         for cont in "${containers_list[@]}"; do
#             cont_all_id=$(docker inspect $i | jq -r '.[].Id')
#             if [[ $cont == $cont_all_id ]]; then
#                 container_name_used+=($cont_all)
#             fi
#         done
#     done
#     echo "${container_name_used_list[@]}"

# }

iteracion=$1
herramienta="kepler"
dir_root="$HOME/Documentos/Experiments/0_test_herramientas"
sub_dir="${dir_root}/${herramienta}/full" # Ubicacion del ARCHIVO final
kind_iter="full"

fem="${dir_root}/em/full/em_${herramienta}_${iteracion}.json" # Ubicacion archivos finales em
kepler_raw_results="${sub_dir}/zdirty_raw_${herramienta}_${kind_iter}_${iteracion}.metrics" # RAW Data
final_results_csv="${sub_dir}/${herramienta}_10_it_${kind_iter}.csv" #Nombre del arcohivo final resultante
#container=($(cat ${kepler_raw_results} | grep kepler_container_cpu_joules_total | grep -v '#' | grep 'zone="core"'| cut -d ',' -f1 | cut -d '=' -f2 | tr -d '"' | sort -u))
#container=($(get_name_containers $container))
container=("ffmpeg-encoder")

if [[ ! -f "${final_results_csv}" ]]; then
    echo "Creating FINAL RESULTS FILES ${final_results_csv}...."
    echo "IT,container,em_host,gpu_process_joules,core_process_joules,dram_process_joules,package_process_joules,total_process_joules,total_node_joules" > "${final_results_csv}"

fi

echo "Processing Data...."

for c in ${container[@]}; do
    id=$(docker inspect ${c} | jq -r '.[0].Id')
    # Porcentaje de Global segun EM
    em_host=$(cat $fem | jq -r '.total')
    exp_time=$(cat $fem | jq -r '.time')
    # Consumo del Host
    gpu_process="$(cat ${kepler_raw_results} | grep "kepler_node_gpu_watts" | grep -v "#" | cut -d ' ' -f3 | tr -d ' ' )"
    gpu_process_joules="$(echo "${gpu_process}*${exp_time}" | bc -l)"
    # Consumo CORE Process
    core_process="$(cat ${kepler_raw_results} |  grep -i $id | grep -v "#" | grep "kepler_container_cpu_joules_total" | grep 'zone="core"' | cut -d ' ' -f2 | tr -d " ")"
    # Consumo DRAM Process
    dram_process="$(cat ${kepler_raw_results} |  grep -i $id | grep -v "#" | grep "kepler_container_cpu_joules_total" | grep 'zone="dram"' | cut -d ' ' -f2 | tr -d " ")"
    # Consumo PKG Process
    package_process="$(cat ${kepler_raw_results} |  grep -i $id | grep -v "#" | grep "kepler_container_cpu_joules_total" | grep 'zone="package"' | cut -d ' ' -f2 | tr -d " ")"
    # Consumo Total del Processo
    total_process="$(echo "${dram_process}+${package_process}" | bc -l)"
    #Consumo Total del Nodo/Host
    total_node_joules_pkg="$(cat ${kepler_raw_results} | grep -v "#" | grep "kepler_node_cpu_active_joules_total"  | grep 'zone="package"' | cut -d ' ' -f2 | st-console --sum)"
    total_node_dram="$(cat ${kepler_raw_results} | grep -v "#" | grep "kepler_node_cpu_active_joules_total"  | grep 'zone="dram"' | cut -d ' ' -f2 | st-console --sum)"
    total_node_joules="$(echo "${total_node_joules_pkg}+${total_node_dram}" | bc -l)"

    echo "${iteracion},${c},${em_host},${gpu_process},${core_process},${dram_process},${package_process},${total_process},${total_node_joules}" >> "${final_results_csv}"

    echo "${c} -- Resultados de Iteracion ${iteracion} almacenados en ${final_results_csv}"
done
