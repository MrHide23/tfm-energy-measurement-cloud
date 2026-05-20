(TeX-add-style-hook
 "twcam-tfm-doc"
 (lambda ()
   (TeX-add-to-alist 'LaTeX-provided-package-options
                     '(("fontenc" "T1") ("babel" "spanish" "activeacute") ("inputenc" "utf8")))
   (add-to-list 'LaTeX-verbatim-environments-local "minted")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "href")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "hyperimage")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "hyperbaseurl")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "nolinkurl")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "url")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "path")
   (add-to-list 'LaTeX-verbatim-macros-with-delims-local "path")
   (TeX-run-style-hooks
    "latex2e"
    "book"
    "bk10"
    "fontenc"
    "babel"
    "amsmath"
    "amssymb"
    "fancyhdr"
    "minted"
    "tikz"
    "framed"
    "geometry"
    "soul"
    "bold-extra"
    "ragged2e"
    "inputenc"
    "graphicx"
    "hyperref")
   (TeX-add-symbols
    '("convocatoria" 1)
    '("tutor" 1)
    '("authorlabel" 1)
    '("tutorlabel" 1)
    "master"
    "portada"
    "declaracion")
   (LaTeX-add-environments
    "resumen"
    "abstract"
    "resum"
    "agradecimientos")
   (LaTeX-add-pagestyles
    "twcam"
    "appendix"
    "plain")
   (LaTeX-add-lengths
    "ancho")
   (LaTeX-add-xcolor-definecolors
    "enlaces"
    "colurl"))
 :latex)

