import sys
import os
import re
from siti_tools.siti import ColorRange, SiTiCalculator
import _siti as siti
import pandas as pd

def saniti_check(args, data_results_path, file_fullpath, header):
    if (len(args) > 2 or len(args))<2:
        print("*** ERROR: Argumentos de entrada erroneos ***")
        sys.exit(1)
     
    if not os.path.exists(data_results_path):
        os.makedirs(data_results_path,exist_ok=True)
        
        with open(file_fullpath, 'w') as f:
            f.write(header)

    if not os.path.exists(file_fullpath):
        with open(file_fullpath, 'w', encoding='utf-8') as f:
            f.write(header)

def get_config_video(video_path):
    #Funcion para determinar valores o settings de cada uno de los videos que se pasan por referencia
    # - Color_range
    # - Numero de Frames
    
    #bit_deep=os.popen(f"ffprobe -v error -select_streams v:0 -count_frames -show_entries stream=nb_read_frames -of csv=p=0 {video_path}").read()
    print(f"video_path: {video_path}")
    frames=int(f"{os.popen(f"ffprobe -v error -select_streams v:0 -count_frames -show_entries stream=nb_read_frames -of csv=p=0 {video_path}").read()}")
    range=ColorRange.FULL
        
    return[range, frames]

if __name__ == "__main__":
    args=sys.argv
    data_results_path='data/chuncks'
    data_results_name = 'video_10s_results.csv'
    video_path=f"{os.getenv('HOME')}/Documentos/Experiments/exp2/videos/siti-videos"
    file_fullpath=f"{data_results_path}/{data_results_name}"
    header = "name_video,chunck,SI,TI\n"
    
    saniti_check(args, data_results_path, file_fullpath, header)
    
    # Calculate SITI    
    video_name=args[1]
    full_video_path=f"{video_path}/{video_name}"
    
    [range,frames]=get_config_video(full_video_path)
    siti_calculator = SiTiCalculator(color_range=range)
    siti_calculator.calculate(full_video_path, num_frames=frames)
    results = siti_calculator.get_results()
    stats=results["aggregated_statistics"]
    print(f"SI: {stats['si']['mean']}, TI: {stats['ti']['mean']}")
    
    chunk_video=re.search(r"chunk(\d+)", video_name)
    chunk_video=chunk_video.group(1) if chunk_video else None
    video_name=re.split("_chunk*",video_name)[0]
    
    # SAVE SITI DATA
    obj=siti.SITI(name_video=video_name, chunck=chunk_video, SI=stats['si']['mean'], TI=stats['ti']['mean'])
    df = pd.DataFrame([obj.__dict__])
    df.to_csv(file_fullpath, mode='a', header=False, index=False)
    
    
