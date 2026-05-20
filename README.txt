Platilla para la elaboración de la memoria del TFM del Máśter TWCAM en Latex

Contenido:

  - Plantilla: twcam-tfm-doc.cls (no es necesario editar este fichero)

  - Ejemplo de uso de la plantilla: ejemplo-memoria.tex  (hay que editar
    este fichero para poner: autor/a, tutor/a/es, título, convocatoria,
    resumen, agradecimientos, etc).

  - Directorio para los ficheros de los capítulos: tex (hay que editar
    los ficheros de este directorio)

  - Directorio para las figuras: figs (no se debe cambiar el nombre
    del directorio, se pueden almacenar las figuras en formato pdf,
    png o jpg en este directorio)

  - Directorio para la bibliografía: bib (no se debe cambiar el nombre
    del directorio, hay que añadir elementos al fichero bibliografia.bib)

  - Directorio para trozos de código: src (esto es opcional, el código
    también se puede poner en el texto de la memoria).

Para generar el pdf:

pdflatex --shell-escape ejemplo-memoria.tex
bibtex ejemplo-memoria
pdflatex --shell-escape ejemplo-memoria.tex


Esta plantilla se puede usar en overleaf (hay que copiar todos los ficheros).


Este material ha sido elaborado por Juan Gutiérrez Aguado
(Departamento de Informática - Universitat de València)
y se distribuye bajo una licencia Creative Commons:

https://creativecommons.org/licenses/by-nc-sa/4.0/deed.es
