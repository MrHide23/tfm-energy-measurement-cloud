# Data Ploter Exp 2.2
Script en python que permite obtener varios plots del conjunto de datos de consumo y siti de la fase de experimentacion 2.2.

## Argumentos de entrada
Los argumentos de entrada varian dependiendo de la flag:
- `process`: Flag que indica que se quiere procesar los datos y almacenar el resultado en un csv

- `plot3d`: Flag que indica que se quiere obtener el plot 3d del Consumo energetico frente a SI y TI. 

- `plot-consumo-ti`: Flag que indica que se quiere obtener el plot 2D del Consumo energetico frente a TI.
- `plot-consumo-si`: Flag que indica que se quiere obtener el plot 2D del Consumo energetico frente a SI.

*SubFlags:*
- `--container=consumo_container0_j`: Flag OPCIONAL que indica de que container/s se desea realizar el/los plots, por defecto `consumo_container0_j`.
- `--data-final-dir=PATH_ARCHIVO`: Flag opcional que indica la ruta del archivo donde va a dejar los datos procesados. Por defecto `./data/ex2.2_process_data.csv`.

## Estructura de datos que itera

## Plots que realiza
