import matplotlib.pyplot as plt
import matplotlib
from matplotlib.container import BarContainer
import seaborn as sns
import pandas as pd 
from typing import cast
import sys, os, random

def sanity_check(args):
    if (len(args) > 2 or len(args))<2:
        print("*** ERROR: Argumentos de entrada erroneos ***")
        sys.exit(1)
    
    if not os.path.exists(args[1]):    
        print(f"*** ERROR: NO se encuentra el archivo {args[1]} ***")
        sys.exit(1)

def plot_point_labels(ax, df, x="SI", y="TI", label="chunck"):
    for _, row in df.iterrows():
        ax.annotate(
            row[label],
            (row[x], row[y]),
            xytext=(5, 5),          # desplazamiento respecto al punto
            textcoords="offset points",
            fontsize=8,
            alpha=0.8
        )
    return ax
    
if __name__ == "__main__":
    sanity_check(sys.argv)

    csv_data_file=sys.argv[1]
    data=pd.read_csv(csv_data_file)

    ax=sns.scatterplot(
        data=data,
        x="SI",
        y="TI",
        hue="name_video",
        s=100
    )
    
    plot_point_labels(ax, data)
    plt.xlabel("Spatial Information (SI)")
    plt.ylabel("Temporal Information (TI)")
    plt.title("Mapa SI-TI por chunk")
    
    plt.tight_layout()
    plt.show()