

import sys,os,re,subprocess
from turtle import pd
import _dataobj as obj
import pandas as pd
import json
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
import seaborn as sns

def sanity_check(args):
    if(len(args)<1):
        print(f"*** ERROR ARGUMENTS: DEBES INDICAR UN NOMBRE DE EXPERIMENTO ***")
        exit(1)


def plot_point_labels(ax, df, x="SI", y="TI", label="chunck"):
    for _, row in df.iterrows():
        ax.annotate(
            f"{row[label]}",
            (row[x], row[y]),
            xytext=(5, 5),          # desplazamiento respecto al punto
            textcoords="offset points",
            fontsize=12,
            weight="bold",
            alpha=0.8
        )
    return ax
    
def process_data(data_path, result_data_path): 
    list_data_obj=[]
    codecs_list=["libx264", "libx265", "hevc_nvenc", "h264_nvenc"]
    category_mapping = {
            'LifeUntouched_chunk0053': 'LSI_LTI',
            'LifeUntouched_chunk0056': 'LSI_LTI',
            'Sintel_chunk0027': 'HSI_LTI',
            'TearsOfSteel_chunk0235': 'HSI_LTI',
            'Eldorado_chunk0015': 'LSI_HTI',
            'IndoorSoccer_chunk0004': 'LSI_HTI',
            'Skateboarding_chunk0020': 'HSI_HTI',
            'Eldorado_chunk0010': 'HSI_HTI',
        }
    
    #GET TREE DIRECTORIS
    tree_path_dir=subprocess.run(["find", data_path,"-name","*.txt"], check=False, capture_output=True, text=True).stdout.splitlines()

    for metrics_file in tree_path_dir:
        data_obj=obj.DataObject()
        
        #PROCESS CONTENT
        path_chunck=re.split(r'/', metrics_file)
        
        name=[vname for vname in path_chunck if re.search('chunk', vname)][0]
        name_video = name + (f"_{category_mapping[k]}" if (k := next((k for k in category_mapping if k in name), None)) else "")
        cores=(
            int(m.group(1))
            if (
                m := next(
                    (
                        match
                        for item in path_chunck
                        if (match := re.search(r'(\d+)cores', item))
                    ),
                    None,
                )
            )
            else 0
        )
        hw = (
            "cpu"
            if any("cpu" in item for item in reversed(path_chunck))
            else "gpu"
        )
        codec="libx264"
        for cod in codecs_list:
            iter=[c for c in reversed(path_chunck) if re.search(f"{cod}", c)]
            if len(iter)>0:
                codec=iter[-1]

        bitrate = (
            m.group(1)
            if (
                m := next(
                    (
                        match
                        for item in reversed(path_chunck)
                        if (match := re.search(r'Bitrate-(\d+)', item))
                    ),
                    None,
                )
            )
            else "0"
        )
        
        #GET DATA Consumption and Containers
        for line in open(f'{metrics_file}'):
            if 'Output' in line:
                clean_line=re.sub(r'Output:','',line)
                #FORMATEAR MEDINATE json librari
                json_content=json.loads(clean_line)
                data_obj.ex_time.append(f"{json_content['computation_time']}")
                data_obj.consumo_process_j.append(json_content['total_energy'])
                print(f" VIdeos: {name_video} - {bitrate} - {codec} - {cores} -- consumo: {json_content['total_energy']} -- tiempo: {json_content['computation_time']}")
            
        data_obj.nombre_video= name_video
        data_obj.hw= hw
        data_obj.n_cores=(cores if cores > 0 else 8)
        data_obj.codec=codec
        data_obj.bitrate_Mbps=f"{bitrate}Mbps"
        
        #SAVE VALUES
        
        list_data_obj.append(data_obj)
    
    #SAVE FILE CSV
    print(list_data_obj[1].as_dict())
    os.makedirs(os.path.dirname(result_data_path), exist_ok=True)
    dict_rows = [d.as_dict() for d in list_data_obj]
    
    df = pd.DataFrame(dict_rows)
    df.drop_duplicates(inplace=True)
    df.to_csv(result_data_path, index=False)
    print(f"Archivo guardado con {len(df)} filas en {result_data_path}")

def plot_consumoxcores(data_csv_file, grafics_save='./grafics/consumoxcores'):
    df=pd.read_csv(data_csv_file)
    os.makedirs(grafics_save, exist_ok=True)
    codec_bitrate_dict=dict()
    
    for codec in df["codec"].unique():
        codec_bitrate_dict[codec]=df.loc[df["codec"] == codec, "bitrate_Mbps"].unique()
        print(f"{codec} - {codec_bitrate_dict[codec]}")
        
        
    for codec, bitrate_list in codec_bitrate_dict.items():
        for bitrate in bitrate_list:
            data = df.loc[(df["codec"] == codec) & (df["bitrate_Mbps"] == bitrate)]
            
            fig= plt.figure(figsize=(25, 10))
            ax=plt.subplot()
            
            sns.lineplot(
                data=data,
                x="n_cores",
                y="consumo_container0_j",
                hue="nombre_video",
                style="nombre_video",
                marker="o",
                ax=ax
            )
            
            ax.set_xlabel("Numero de Cores", fontsize=15, weight='bold')
            ax.set_ylabel("Julios(J)",fontsize=15, weight='bold') 
            ax.set_title(f'{codec} - {bitrate}')
            ax.grid(True)
            plot_params = {
                "figure.dpi": "250",
                "axes.labelsize": 24,           # Aumentado (antes 20)
                "axes.linewidth": 1.5,
                "axes.titlesize": 24,           # Aumentado (antes 20)
                "xtick.labelsize": 20,          # Aumentado (antes 16)
                "ytick.labelsize": 20,          # Aumentado (antes 16)
                "legend.title_fontsize": 16,    # Aumentado (antes 15)
                "legend.fontsize": 14,          # Aumentado (antes 13)
                "xtick.major.size": 3.5,
                "xtick.major.width": 1.5,
                "xtick.minor.size": 2.5,
                "xtick.minor.width": 1.5,
                "ytick.major.size": 3.5,
                "ytick.major.width": 1.5,
                "ytick.minor.size": 2.5,
                "ytick.minor.width": 1.5,
                # "legend.loc": "upper right", # NUEVO: evita que la leyenda esté en el centro
            }
            plt.rcParams.update(plot_params)
            
            plt.savefig(f"{grafics_save}/{codec}-{bitrate}_ConsumoxCores.png", dpi=220)
            #plt.show()
            plt.close()
    
def plot_consumoxcores_gpusvscpu(data_csv_file, grafics_save='./grafics/gpusvscpu'):
    df=pd.read_csv(data_csv_file)
    os.makedirs(grafics_save, exist_ok=True)
    codec_bitrate_dict=dict()

    comparison = {
        "H264": ["libx264", "h264_nvenc"],
        "H265": ["libx265", "hevc_nvenc"]
    }
    
    subplot_rows=5
    subplot_colums=2

    for family, codecs in comparison.items():
    
            for bitrate in sorted(df["bitrate_Mbps"].unique()):
    
                data = df[
                    (df["codec"].isin(codecs)) &
                    (df["bitrate_Mbps"] == bitrate)
                ]
    
                videos = data["nombre_video"].unique()
    
                fig, ax = plt.subplots(
                    subplot_rows,
                    subplot_colums,
                    figsize=(20, 22),
                    sharex=True,
                    sharey=True
                )
    
                ax = ax.flatten()
    
                for idx, video in enumerate(videos):
                    video_data = data.loc[data["nombre_video"] == video]
    
                    sns.lineplot(
                        data=video_data,
                        x="n_cores",
                        y="consumo_container0_j",
                        hue="codec",
                        style="codec",
                        marker="o",
                        ax=ax[idx]
                    )
    
                    ax[idx].set_title(video)
                    ax[idx].set_xlabel("Número de cores")
                    ax[idx].set_ylabel("Consumo (J)")
                    ax[idx].grid(True)
    
                # Ocultar ejes no utilizados
                for i in range(len(videos), len(ax)):
                    ax[i].set_visible(False)
                    
    
                fig.suptitle(
                    f"{family} - {bitrate}"
                )
    
                plot_params = { "figure.dpi": "220", 
                    "axes.labelsize": 20, 
                    "axes.linewidth": 1.5, 
                    "axes.titlesize": 20, 
                    "xtick.labelsize": 16, 
                    "ytick.labelsize": 16, 
                    "legend.title_fontsize": 12, 
                    "legend.fontsize": 12, 
                    "xtick.major.size": 3.5, 
                    "xtick.major.width": 1.5, 
                    "xtick.minor.size": 2.5, 
                    "xtick.minor.width": 1.5, 
                    "ytick.major.size": 3.5, 
                    "ytick.major.width": 1.5, 
                    "ytick.minor.size": 2.5, 
                    "ytick.minor.width": 1.5, } 
                fig.tight_layout()
                plt.rcParams.update(plot_params) 
                plt.savefig(
                    f"{grafics_save}/{family}-{bitrate}_GPUvsCPU.png",
                    dpi=250,
                    bbox_inches="tight"
                )
                
                #plt.show()
                plt.close(fig)

def plot_tiempoxcores(data_csv_file, grafics_save='./grafics/tiempoxcores'):
    df = pd.read_csv(data_csv_file)
    os.makedirs(grafics_save, exist_ok=True)

    # Agrupar los códecs en dos conjuntos
    codec_groups = {
        'h264_hevc': ['h264_nvenc', 'hevc_nvenc'],
        'libx264_libx265': ['libx264', 'libx265']
    }

    # Obtener valores únicos de nombre_video y bitrate
    for nombre in df["nombre_video"].unique():
        for bitrate in df.loc[df["nombre_video"] == nombre, "bitrate_Mbps"].unique():
           
            data = df.loc[(df["nombre_video"] == nombre) & (df["bitrate_Mbps"] == bitrate)]

            for group_name, codec_list in codec_groups.items():
                data_group = data[data["codec"].isin(codec_list)]

                if data_group.empty:
                    print(f"Advertencia: No hay datos para {group_name} en {nombre}-{bitrate}")
                    continue

                fig = plt.figure(figsize=(25, 10))
                ax = plt.subplot()

                # Gráfico de líneas
                sns.lineplot(
                    data=data_group,
                    x="n_cores",
                    y="ex_time_cont0_s",
                    hue="codec",
                    style="codec",
                    marker="o",
                    ax=ax
                )

                # Etiquetas y título
                ax.set_xlabel("Número de Cores", fontsize=15, weight='bold')
                ax.set_ylabel("Tiempo de Codificación (s)", fontsize=15, weight='bold')
                ax.set_title(f'{nombre} - {bitrate} Mbps - {group_name.replace("_", " vs ")}')
                ax.grid(True)

                # Parámetros de estilo
                plot_params = {
                    "figure.dpi": "250",
                    "axes.labelsize": 24,
                    "axes.linewidth": 1.5,
                    "axes.titlesize": 24,
                    "xtick.labelsize": 20,
                    "ytick.labelsize": 20,
                    "legend.title_fontsize": 16,
                    "legend.fontsize": 14,
                    "xtick.major.size": 3.5,
                    "xtick.major.width": 1.5,
                    "xtick.minor.size": 2.5,
                    "xtick.minor.width": 1.5,
                    "ytick.major.size": 3.5,
                    "ytick.major.width": 1.5,
                    "ytick.minor.size": 2.5,
                    "ytick.minor.width": 1.5,
                }
                plt.rcParams.update(plot_params)

                # Guardar y mostrar
                filename = f"{grafics_save}/{nombre}-{bitrate}_{group_name}_TiempoxCores.png"
                plt.savefig(filename, dpi=220)
                #plt.show()
                plt.close()

            # (Opcional) Mostrar los datos completos para depuración
            print(f"Datos para {nombre} - {bitrate}:\n{data}")

def plot_consumoxtiempo(data_csv_file, grafics_save='./grafics/consumoxtiempo'):
    df = pd.read_csv(data_csv_file)
    os.makedirs(grafics_save, exist_ok=True)

    # Agrupar los códecs en dos conjuntos
    codec_groups = {
        'h264_hevc': ['h264_nvenc', 'hevc_nvenc'],
        'libx264_libx265': ['libx264', 'libx265']
    }

    # Obtener valores únicos de nombre_video y bitrate
    for nombre in df["nombre_video"].unique():
        for bitrate in df.loc[df["nombre_video"] == nombre, "bitrate_Mbps"].unique():
           
            data = df.loc[(df["nombre_video"] == nombre) & (df["bitrate_Mbps"] == bitrate)]

            for group_name, codec_list in codec_groups.items():
                data_group = data[data["codec"].isin(codec_list)]

                if data_group.empty:
                    print(f"Advertencia: No hay datos para {group_name} en {nombre}-{bitrate}")
                    continue

                fig = plt.figure(figsize=(20, 10))
                ax = plt.subplot()

                # Gráfico de líneas
                ax=sns.scatterplot(
                    data=data_group,
                    x="ex_time_cont0_s",
                    y="consumo_container0_j",
                    s=100,
                    hue="codec",
                    style="codec",
                    marker="o",
                    ax=ax
                )
                
                plot_point_labels(ax, data_group, x="ex_time_cont0_s", y="consumo_container0_j", label="n_cores")

                # Etiquetas y título
                ax.set_xlabel("Tiempo (s)", fontsize=15, weight='bold')
                ax.set_ylabel("Consumo Energetico (j)", fontsize=15, weight='bold')
                ax.set_title(f'{nombre} - {bitrate} Mbps - {group_name.replace("_", " vs ")}')
                ax.grid(True)

                # Parámetros de estilo
                plot_params = {
                    "figure.dpi": "250",
                    "axes.labelsize": 24,
                    "axes.linewidth": 1.5,
                    "axes.titlesize": 24,
                    "xtick.labelsize": 20,
                    "ytick.labelsize": 20,
                    "legend.title_fontsize": 16,
                    "legend.fontsize": 14,
                    "xtick.major.size": 3.5,
                    "xtick.major.width": 1.5,
                    "xtick.minor.size": 2.5,
                    "xtick.minor.width": 1.5,
                    "ytick.major.size": 3.5,
                    "ytick.major.width": 1.5,
                    "ytick.minor.size": 2.5,
                    "ytick.minor.width": 1.5,
                }
                plt.rcParams.update(plot_params)

                # Guardar y mostrar
                filename = f"{grafics_save}/{nombre}-{bitrate}_{group_name}_ConsumoxTiempo.png"
                plt.savefig(filename, dpi=220)
                #plt.show()
                plt.close()

            # (Opcional) Mostrar los datos completos para depuración
            print(f"Datos para {nombre} - {bitrate}:\n{data}")

        
    
if __name__ == "__main__":
    args = sys.argv
    sanity_check(args)
    
    name_experiment=args[1]
    data_path=f"{os.getenv('EXP2')}/exp2.3-limited_cores_threads/metricas/{name_experiment}"
    result_data_path=f"{os.getcwd()}/data/epx2.3_process_data.csv"
    num_containers=1

    # FLAGS ALTERNATIVAS
    if any(re.search(r'--data-results', arg) for arg in args):
        index = [ i for i, word in enumerate(args) if '--data-results' in word ][-1]
        result_data_path=re.split(r'=',args[index])[1]

    if any(re.search(r'--data-path', arg) for arg in args):
        index = [ i for i, word in enumerate(args) if '--data-path' in word ][-1]
        data_path=re.split(r'=',args[index])[1]
        
    if any(re.search(r'--number-containers', arg) for arg in args):
        index = [ i for i, word in enumerate(args) if '--number-containers' in word ][-1]
        containers=re.split(r'=',args[index])[-1]

    # GRAFICAS Y ACCIONES
    if 'process' in args:
        process_data(data_path, result_data_path)
        
    if 'plot-consumoxcores' in args:
        plot_consumoxcores(result_data_path)
        
    if 'plot-consumoxcores-gpuvscpu' in args:
        plot_consumoxcores_gpusvscpu(result_data_path)

    if 'plot-tiempoxcores' in args:
        plot_tiempoxcores(result_data_path)

    if 'plot-consumoxtiempo' in args:
        plot_consumoxtiempo(result_data_path)
       