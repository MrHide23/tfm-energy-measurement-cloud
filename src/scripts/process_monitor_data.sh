#!/bin/bash
base=$(pwd)/data
case="$2"
sub_cont="ffmpeg-$case/rep$1"
workdir="${base}/${sub_cont}"
path_file=($(ls ${workdir} | grep "csv"))
global_path_file="${workdir}/$(ls ${workdir} | grep "json")"
global_info=${workdir}/$(ls ${workdir} | grep "txt")
final_workdir="ffmpeg-$case-processed.csv"



if [[ ! -f ${final_workdir} ]]; then 
    head="tool,case,em_host,gpu_process_joules,node_total_joufig:exp1-kepeler-csv_headerles"
    for i in "${!path_file[@]}";do
        indice=$i
        indice=$((indice + 1))
        head="$head,process${indice}_energy_joules"
    done 
    echo "${head}" >> ${final_workdir}
fi

    e_pkg=$(cat "${workdir}/${path_file[0]}" | cut -d ';' -f4 | sed '1d' | st-console --sum)
    e_drm=$(cat "${workdir}/${path_file[0]}" | cut -d ';' -f10 | sed '1d' | st-console --sum)
    gpu_energy=($(cat ${global_info} | grep Output |  sed 's/^Output: //' | jq -r '.energy_per_gpu.[]'))
    total_sum=$(echo "${e_pkg}+${e_drm}" | bc -l)
    em_total_energy=$(cat "${global_path_file}" | jq -r '.total')
    result="monitor,${case},${em_total_energy},${gpu_energy[0]},${total_sum}"
    
    for pf in "${path_file[@]}";do
        c_e_pkg=$(cat "${workdir}/$pf" | cut -d ';' -f9 | sed '1d' | st-console --sum)
        c_e_drm=$(cat "${workdir}/$pf" | cut -d ';' -f14 | sed '1d' | st-console --sum)
        total_sum_cont=$(echo "${c_e_pkg}+${c_e_drm}" | bc -l)
        result="${result},${total_sum_cont}"
    done 
    
    echo "${result}" >> ${final_workdir}
    echo "Iteracion $1 procesada ==> ${result}"
