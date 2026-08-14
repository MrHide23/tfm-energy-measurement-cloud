import sys
import os
import re
from matplotlib import container
import pandas as pd
import _object as obj
import subprocess
import matplotlib.pyplot as plt
from matplotlib.gridspec import GridSpec
from matplotlib.lines import Line2D


def get_global_consum(file_info_name):
    with open(file_info_name, "r", encoding="utf-8") as f:
        info_content = f.read()
    return [float(x) for x in re.findall(r'"total_energy":([0-9.]+)', info_content)]

def process_data(subpath_metrics, process_data_final):
    siti_data = (
        f"{os.getenv('HOME')}/Documentos/Experiments/exp2/exp2.1-siti/siti-calculator/data/chuncks/video_10s_results.csv"
    )
    metrics_path = (
        f"{os.getenv('HOME')}/Documentos/Experiments/exp2/exp2.2-bitrate_codecs-pruebas/metricas/{subpath_metrics}"
    )

    # Listar directorios de primer nivel (cpu/gpu)
    result = subprocess.run(["ls", metrics_path], capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error listando {metrics_path}: {result.stderr.strip()}")
        sys.exit(1)

    data_object_list = []
    siti_list = pd.read_csv(siti_data)

    for cpu_gpu in result.stdout.splitlines():
        # Listar videos dentro de cpu/gpu
        videos = subprocess.run(
            ["ls", f"{metrics_path}/{cpu_gpu}"], capture_output=True, text=True
        )

        for video_path in videos.stdout.splitlines():
            
            # Parsear información del nombre del video
            partes = video_path.split("_")
            kind_video = "_".join(partes[-2:])              # KIND
            chunk = partes[2].replace("chunk", "")         # NumberChunck
            nombre = partes[0]                              # NombreVideo
            nombre_chunck = f"{nombre}_{chunk}"

            # Obtener SI y TI del DataFrame
            pd_single = siti_list.loc[siti_list['chunck'] == nombre_chunck]
            if pd_single.empty:
                continue  # o manejar el error

            # Listar codecs para este video
            codecs = subprocess.run(
                ["ls", f"{metrics_path}/{cpu_gpu}/{video_path}"],
                capture_output=True, text=True
            ).stdout.splitlines()

            for codec in codecs:
                # Listar bitrates para este codec
                bitrates = subprocess.run(
                    ["ls", f"{metrics_path}/{cpu_gpu}/{video_path}/{codec}"],
                    capture_output=True, text=True
                ).stdout.splitlines()

                for bitrate in bitrates:
                    # Buscar el archivo que contiene "info"
                    find_res = subprocess.run(
                        [
                            "find",
                            f"{metrics_path}/{cpu_gpu}/{video_path}/{codec}/{bitrate}",
                            "-maxdepth", "1",
                            "-name", "*info*",
                            "-type", "f"
                        ],
                        capture_output=True, text=True
                    )
                    info_files = find_res.stdout.splitlines()
                    if not info_files:
                        continue  # o error

                    global_metrics_filename = info_files[0]
                    data_obj = obj.DataObject()
                    data_obj.hw = cpu_gpu
                    data_obj.nombre_video = nombre_chunck
                    data_obj.kind = kind_video
                    data_obj.si = pd_single['SI'].iloc[0]
                    data_obj.ti = pd_single['TI'].iloc[0]
                    data_obj.codec = codec
                    data_obj.bitrate_Mbps = re.split("-", bitrate)[1]
                    data_obj.consumo_process_j = get_global_consum(global_metrics_filename)

                    data_object_list.append(data_obj)

    # Guardar resultados
    dict_rows = [d.as_dict() for d in data_object_list]
    pd.DataFrame(dict_rows).to_csv(
        process_data_final, index=False
    )

#FUNCIONES PARA PLOTEAR
def plot_si_ti_consumo(process_data_final, container='consumo_container0_j', figs_save_path=f'{os.getcwd()}/grafics/plot3d'):
    print(f"*** Plotting 3D SI-TI-Consumo para container {container} ***")
    df = pd.read_csv(process_data_final)
    os.makedirs(figs_save_path, exist_ok=True)
    
    codec_bitrate_dict=dict()
    for codec in df["codec"].unique():
        codec_bitrate_dict[codec]=df.loc[df["codec"] == codec, "bitrate_Mbps"].unique()

    for codec, bitrate_list in codec_bitrate_dict.items():
        for bitrate in bitrate_list:
            data = df.loc[(df["codec"] == codec) & (df["bitrate_Mbps"] == bitrate)]
            fig = plt.figure(figsize=(18, 10))
            gs = GridSpec(1, 2, width_ratios=[2, 1])  # gráfico 3D + tabla
            
            ax = fig.add_subplot(gs[0], projection='3d')
            for i, row in data.iterrows():
                ax.scatter(row['TI'], row['SI'], row[container], c=f'{kind_colors.get(row["kind"])}', s=30)
            ax.set_xlabel('TI')
            ax.set_ylabel('SI')
            ax.set_zlabel('Consumo (J)')
            ax.set_title(f'{codec} - {bitrate} Mbps')
           
            for i, row in data.iterrows():
              ax.text(row['TI'],row['SI'],row[container], 
                  f"{row['nombre_video']}", 
                  size=8, zorder=1, color=f'{kind_colors.get(row["kind"])}')
                            
            # Crear tabla con los datos
            tabla_data = data[['nombre_video','kind','TI', 'SI', container]].copy()
            # Formatear numéricos
            tabla_data = tabla_data.sort_values(by=container, ascending=False)
            tabla_data['TI'] = tabla_data['TI'].map('{:.3f}'.format)
            tabla_data['SI'] = tabla_data['SI'].map('{:.3f}'.format)
            tabla_data[container] = tabla_data[container].map('{:.3f}'.format)
            
            ax_table = fig.add_subplot(gs[1])
            ax_table.axis('off')
            legend_elements = [
                 Line2D(
                      [0], [0],
                      color=color,
                      marker='o',
                      linestyle='-',
                      linewidth=2,
                      markersize=6,
                      label=kind
                  )
                  for kind, color in kind_colors.items()
              ]
              
            ax.legend(handles=legend_elements, title="Kind")
            table = ax_table.table(
                cellText=tabla_data.values,
                colLabels=tabla_data.columns,
                loc='center',
                cellLoc='left'
            )
            table.auto_set_font_size(False)
            table.set_fontsize(8)
            table.scale(1.4, 1.2)
            plt.tight_layout()
            plt.savefig(f"{figs_save_path}/{container}-{codec}-{bitrate}_ConsumoSITI.png", dpi=130)
            #plt.show(block=True)  
            plt.close()
            
def plot_ti_consumo(process_data_final, container='consumo_container0_j', figs_save_path=f'{os.getcwd()}/grafics/consumo-ti'):    
    print(f"*** Plotting 2D Consumo x Ti para container {container} ***")
    df = pd.read_csv(process_data_final)
    os.makedirs(figs_save_path, exist_ok=True)

    codec_bitrate_dict=dict()
    for codec in df["codec"].unique():
        codec_bitrate_dict[codec]=df.loc[df["codec"] == codec, "bitrate_Mbps"].unique()

    for codec, bitrate_list in codec_bitrate_dict.items():
       for bitrate in bitrate_list:
           data = df.loc[(df["codec"] == codec) & (df["bitrate_Mbps"] == bitrate)]
           fig= plt.figure(figsize=(18, 10))
           ax=plt.subplot()
           
           markerline, stemlines, baseline = ax.stem(data['TI'],data[container])
           colors = [kind_colors.get(k, "gray") for k in data["kind"]]
           stemlines.set_colors(colors)
                       
           for i, row in data.iterrows():
             ax.text(row['TI'], row[container], 
                 f"{row['nombre_video']}", 
                 size=8, zorder=1, color='black', rotation=45)
             
           legend_elements = [
                Line2D(
                     [0], [0],
                     color=color,
                     marker='o',
                     linestyle='-',
                     linewidth=2,
                     markersize=6,
                     label=kind
                 )
                 for kind, color in kind_colors.items()
             ]
             
           ax.legend(handles=legend_elements, title="Kind")
           ax.set_xlabel("TI")
           ax.set_ylabel("Julios(J)")
           ax.set_title(f'{codec} - {bitrate} Mbps')
           plt.savefig(f"{figs_save_path}/{container}-{codec}-{bitrate}_ConsumoTI.png", dpi=130)
           #plt.show()
           plt.close()
       
def plot_si_consumo(process_data_final, container='consumo_container0_j', figs_save_path=f'{os.getcwd()}/grafics/consumo-si'):    
    print(f"*** Plotting 2D Consumo x Si para container {container} ***")
    df = pd.read_csv(process_data_final)
    os.makedirs(figs_save_path, exist_ok=True)

    codec_bitrate_dict=dict()
    for codec in df["codec"].unique():
        codec_bitrate_dict[codec]=df.loc[df["codec"] == codec, "bitrate_Mbps"].unique()

    for codec, bitrate_list in codec_bitrate_dict.items():
       for bitrate in bitrate_list:
           data = df.loc[(df["codec"] == codec) & (df["bitrate_Mbps"] == bitrate)]
           fig= plt.figure(figsize=(18, 10))
           ax=plt.subplot()
           
           markerline, stemlines, baseline = ax.stem(data['SI'],data[container])
           colors = [kind_colors.get(k, "gray") for k in data["kind"]]
           stemlines.set_colors(colors)
                       
           for i, row in data.iterrows():
             ax.text(row['SI'], row[container], 
                 f"{row['nombre_video']}", 
                 size=8, zorder=1, color='black', rotation=45)
             
           legend_elements = [
                Line2D(
                     [0], [0],
                     color=color,
                     marker='o',
                     linestyle='-',
                     linewidth=2,
                     markersize=6,
                     label=kind
                 )
                 for kind, color in kind_colors.items()
             ]
             
           ax.legend(handles=legend_elements, title="Kind")
           ax.set_xlabel("SI")
           ax.set_ylabel("Julios(J)")
           ax.set_title(f'{codec} - {bitrate} Mbps')
           plt.savefig(f"{figs_save_path}/{container}-{codec}-{bitrate}_ConsumoSI.png", dpi=130)
           #plt.show()
           plt.close()
               
if __name__ == "__main__":
    args = sys.argv
    container = "consumo_container0_j"
    subpath_metrics="AllVideos"
    index = [ i for i, word in enumerate(args) if '--data-final-dir' in word ]

    kind_colors = {
        "HTI_HSI": "red",
        "HTI_LSI": "blue",
        "LTI_HSI": "green",
        "LTI_LSI": "orange"
    }
    
    if index:
        process_data_path = args[index[-1]].split("=", 1)[1]
    else:
        process_data_path = f"{os.getcwd()}/data/ex2.2_process_data.csv"
    
    os.makedirs(os.path.dirname(process_data_path), exist_ok=True) 
    
    if "process" in args:
        process_data(subpath_metrics, process_data_path)
        print(f"*** Datos procesados y guardados en {process_data_path} ***")
        
    # Generacion de Graficos 
    # PLOT SI - TI - CONSUMO Container 1
    
    if "plot3d" in args:
        subflag = [ i for i, word in enumerate(args) if '--container*' in word ]
        
        if subflag:
            print("Entra")
            container=re.split(r'=', args[subflag[-1]])[1]
        
        plot_si_ti_consumo(process_data_path, container)

    # PENDIENTE
    if any(re.search(r'plot-consumo-ti', arg) for arg in args):
    
        index = [ i for i, word in enumerate(args) if 'plot-consumo-ti' in word ][-1]
        subflag = [ i for i, word in enumerate(args) if '--container*' in word ]
        
        if subflag:
            contianer=re.split(r'=', args[index])[1]

        plot_ti_consumo(process_data_path, container)
            
    #PENDIENTE   
    if any(re.search(r'plot-consumo-si', arg) for arg in args):
        
        index = [ i for i, word in enumerate(args) if 'plot-consumo-si' in word ][-1]
        subflag = [ i for i, word in enumerate(args) if '--container*' in word ]
        if subflag:
            container=re.split(r'=', args[index])[1]

        plot_si_consumo(process_data_path, container)