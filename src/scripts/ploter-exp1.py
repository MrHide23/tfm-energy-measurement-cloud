import os
import sys
import subprocess
import random
from typing import cast
import pandas as pd
import seaborn as sns
import ObjData as obj
import matplotlib.pyplot as plt
from matplotlib.container import BarContainer


def find_csv(dir_proyecto, black_list_files):
    if not os.path.exists(dir_proyecto):
        print(f"Route {dir_proyecto} not found")
        sys.exit(1)

    name_files_list=subprocess.run(f"ls -LR {dir_proyecto} | grep '.csv'" , shell=True, capture_output=True, text=True).stdout.splitlines()
    files_csv_list=[]

    for i in name_files_list:

        if i not in black_list_files:
            dir_file=subprocess.run(f"find {dir_proyecto} -name '{i}'" , shell=True, capture_output=True, text=True).stdout.splitlines()[0]
            files_csv_list.append(obj.FilesCSV(i,dir_file))
    return files_csv_list

def get_file_case(file):
    case="full"
    if "cores" in file:
        case="limited"
    elif "containers" in file:
        case="limited-container"
    elif "cpu" in file:
        case="cpu"

    return case

def get_total_energy_process(tool,df):
    lista=[]
    if(tool != "monitor"):
        grouped="container"
        if(tool == "scp"):
            grouped="iter"
            df[grouped]=df.groupby("IT").cumcount()

        lista=df.groupby(grouped)["total_process_joules"].mean().tolist()
    else:
        head=df.head()
        for i in head:
            if("process" in i and "gpu" not in i):
                lista.append(df[i].mean())

    return lista

def get_gpu_energy_process(tool,df):
    gpu_node_jouls=0.0
    if (tool != "scp"):
        gpu_node_jouls=df['gpu_process_joules'].mean()

    return gpu_node_jouls

def processing_saving_data(files_csv_list, name_data_file):
    data_obj_list = []

    for obj_file in files_csv_list:
        df = pd.read_csv(obj_file.dir_archivo)

        node_energy,tool=['total_node_joules', 'kepler']
        if 'scp' in obj_file.nombre_archivo:
            node_energy,tool=['total_energy_host', 'scp']
        elif 'monitor' in obj_file.nombre_archivo:
            node_energy,tool=['node_total_joules', 'monitor']

        total_energy_process_list = get_total_energy_process(tool,df)
        gpu_node_jouls=get_gpu_energy_process(tool,df)

        # Guardamos el objeto pasando la lista obtenida
        data_obj_list.append(obj.DataProcessed(
                tool,
                get_file_case(obj_file.nombre_archivo),
                df['em_host'].mean(),
                df[node_energy].mean(),
                gpu_node_jouls,
                total_energy_process_list))

    # Convertimos la lista de objetos a una lista de diccionarios ya aplanados dinámicamente
    dict_rows = [d.as_dict() for d in data_obj_list]

    # Creamos el DataFrame de Pandas
    df_write = pd.DataFrame(dict_rows)
    df_write.to_csv(name_data_file,index=False)


    return name_data_file

def plot_bar_label(ax):
    for cont in ax.containers:
        r=random.choice([4,15])
        ax.bar_label(cast(BarContainer, cont), fmt='%.3f', padding=r,fontsize=12)
    return ax


if __name__ == "__main__":
    # Proyecto Main Route
    dir_proyecto=f"{os.getenv('HOME')}/Documents/TWCAM/2do/TFM/Experiments/0_test_herramientas"
    name_metrics_file="exp1_energy_metrics.csv"
    # Black list of csv files which i don't want to use in my plots
    black_list=["nvidia-smi-metrics.csv", name_metrics_file]
    file_csv_list = find_csv(dir_proyecto, black_list)

   # name_data_file = processing_saving_data(file_csv_list, name_metrics_file)


    # PLOTS X = METRIC

    dt_clean = pd.read_csv(name_metrics_file)


    # -------------------------------------------------------------
    # FIGURE 1: Comparation CPU + GPU Process Mesurement
    # -------------------------------------------------------------
    dynamic_process_cols_fig1 = [col for col in dt_clean.columns if "process1" in col] #Limited to one Figure
    metricas_a_graficar_fig1 = ["em_total_energy", "node_total_joules"] + dynamic_process_cols_fig1+["gpu_node_jouls"]

    plt.figure(figsize=(20, 12))
    plt.rcParams.update({
    "font.size": 15,
    "axes.titlesize": 20,
    "axes.labelsize": 16,
    "xtick.labelsize": 17,
    "ytick.labelsize": 17,
    "legend.fontsize": 13,
    "legend.title_fontsize": 13
    })
    dt_clean_full = dt_clean.loc[dt_clean["case"] == "full"]

    dt_clean_melted_full = pd.melt(
        dt_clean_full,
        id_vars="tool",
        value_vars=metricas_a_graficar_fig1,
        var_name="metrica",
        value_name="energy"
    )
    ax1=sns.barplot(
        x="tool", y="energy", hue="metrica", data=dt_clean_melted_full
    )
   
    plot_bar_label(ax1)
    plt.title("Codificacion usando CPU + GPU")
    plt.xlabel("Tool Used")
    plt.ylabel("Total Energy (J)")

    # -------------------------------------------------------------
    # FIGURE 2: Compare only CPU coding data
    # -------------------------------------------------------------

    plt.figure(figsize=(20, 12))
    metricas_a_graficar_fig2 = [col for col in dt_clean.columns if "process" in col]
    metricas_a_graficar_fig2 = ["em_total_energy", "node_total_joules"] + metricas_a_graficar_fig2
    # Corrección del filtrado: Usamos filtrado booleano directo en lugar de iloc con lambda
    dt_clean_cpu = dt_clean.loc[dt_clean["case"] == "cpu"]

    dt_clean_melted_cpu = pd.melt(
        dt_clean_cpu,
        id_vars="tool",
        value_vars=metricas_a_graficar_fig2,
        var_name="metrica",
        value_name="energy"
    )

    ax1=sns.barplot(
        x="tool", y="energy", hue="metrica", data=dt_clean_melted_cpu
    )

    plot_bar_label(ax1)

    plt.title("Codificacion usando CPU")
    plt.xlabel("Tool Used")
    plt.ylabel("Total Energy (J)")

    # -------------------------------------------------------------
    # FIGURE 3: One Containers Limited (case == "limited")
    # -------------------------------------------------------------
    plt.figure(figsize=(20, 12))
    dt_clean_limited = dt_clean.loc[dt_clean["case"] == "limited"]

    dt_clean_melted_lim = pd.melt(
        dt_clean_limited,
        id_vars="tool",
        value_vars=metricas_a_graficar_fig2,
        var_name="metrica",
        value_name="energy"
    )

    ax2=sns.barplot(
        x="tool", y="energy", hue="metrica", data=dt_clean_melted_lim
    )

    plot_bar_label(ax2)

    plt.title("Codificaion usando CPU con limite de 3 Cores")
    plt.xlabel("Tool Used")
    plt.ylabel("Total Energy (J)")

    # -------------------------------------------------------------
    # FIGURE 4: One Containers Limited (case == "multicontainers-limited")
    # -------------------------------------------------------------

    plt.figure(figsize=(20, 12))
    dt_clean_lim_cont = dt_clean.loc[dt_clean["case"] == "limited-container"]

    dt_clean_melted_cont = pd.melt(
    dt_clean_lim_cont,
        id_vars="tool",
        value_vars=metricas_a_graficar_fig2,
        var_name="metrica",
        value_name="energy"
    )
    ax1=sns.barplot(
        x="tool", y="energy", hue="metrica", data=dt_clean_melted_cont
    )

    ax1=plot_bar_label(ax1)
    plt.title("2 Containers Limited Simultaneously")
    plt.xlabel("Tool Used")
    plt.ylabel("Total Energy (J)")

    # Ajustar el diseño para que no se solapen los títulos ni las leyendas
    plt.tight_layout()
    plt.show()
