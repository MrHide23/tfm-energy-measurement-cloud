% Plantilla para la memorial del TFM del Máster en Tecnologías Web,
% Computación en la Nube y Aplicaciones Móviles (http://www.uv.es/twcam)
% Plantilla desarrollada por Juan Gutiérrez Aguado
% (www.uv.es/jgutierr)
% Departamento de Informática - Universitat de València
%
% Versión 09/2021
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{twcam-tfm-doc}[2019/04/15 Plantilla para la memoria del TFM Master TWCAM]

\DeclareOption*{\PassOptionsToClass{\CurrentOption}{book}}
\ProcessOptions
\LoadClass{book}

\newcommand{\@tutorlabel}{\ClassError{twcam-tfm-doc}{Falta especificar
\string\tutorlabel{}}
 {Usa el comando \string\tutorlabel{} en el preambulo para especificar
\MessageBreak la etiqueta asociada (Tutor, Tutora, Tutores)}}
\newcommand{\tutorlabel}[1]{\gdef\@tutorlabel{#1}}

\newcommand{\@authorlabel}{\ClassError{twcam-tfm-doc}{Falta especificar
\string\autorlabel{}}
 {Usa el comando \string\authorlabel{} en el preambulo para especificar
\MessageBreak la etiqueta asociada (Autor, Autora)}}
\newcommand{\authorlabel}[1]{\gdef\@authorlabel{#1}}

\newcommand{\@tutor}{\ClassError{twcam-tfm-doc}{Falta especificar
\string\tutor{}}
 {Usa el comando \string\tutor{} en el preambulo para especificar
\MessageBreak el nombre del tutor o la tutora.}}
\newcommand{\tutor}[1]{\gdef\@tutor{#1}}

\newcommand{\@convocatoria}{\ClassError{twcam-tfm-doc}{Falta especificar
\string\convocatoria{}}
 {Usa el comando \string\convocatoria{} en el preambulo para especificar
\MessageBreak el mes y año de la lectura.}}
\newcommand{\convocatoria}[1]{\gdef\@convocatoria{#1}}

\RequirePackage[T1]{fontenc}
\RequirePackage[spanish,activeacute]{babel}
\RequirePackage{amsmath}
\RequirePackage{amssymb}
\RequirePackage{fancyhdr}
\RequirePackage{minted}
\RequirePackage{tikz}
\RequirePackage{framed}
\RequirePackage{geometry}
\RequirePackage{soul}
\RequirePackage{bold-extra}
\RequirePackage{ragged2e}
\usepackage[utf8]{inputenc} %Codificacion de entrada
\usepackage{graphicx}
\usepackage{hyperref}
\usepackage[acronym]{glossaries}
\usepackage[table,xcdraw]{xcolor}
\usepackage{listings}
\usepackage{multirow, tabularx, booktabs}
\usepackage{tablefootnote}
\usepackage{subfigure}
\usepackage{subcaption}

% COMANDOS PERSONALES 
\newcommand{\dosubfigs}[6]{%
  \begin{minipage}[b]{0.40\textwidth}
    \centering
    \includegraphics[width=\textwidth]{#1}
    \captionof{subfigure}{#2}
    \label{#3}
  \end{minipage}%
  \hfill
  \begin{minipage}[b]{0.40\textwidth}
    \centering
    \includegraphics[width=\textwidth]{#4}
    \captionof{subfigure}{#5}
    \label{#6}
  \end{minipage}%
  \par\vspace{1ex}%
}


\newcommand{\tresubfigs}[9]{%
  \begin{minipage}[b]{0.30\textwidth}
    \centering
    \includegraphics[width=\textwidth]{#1}
    \captionof{subfigure}{#2}
    \label{#3}
  \end{minipage}%
  \hfill
  \begin{minipage}[b]{0.30\textwidth}
    \centering
    \includegraphics[width=\textwidth]{#4}
    \captionof{subfigure}{#5}
    \label{#6}
  \end{minipage}%
  \hfill
  \begin{minipage}[b]{0.30\textwidth}
    \centering
    \includegraphics[width=\textwidth]{#7}
    \captionof{subfigure}{#8}
    \label{#9}
  \end{minipage}%
  \par\vspace{1ex}%
}


% Configuración para el código usando minted

\setminted{frame=single,linenos=true,fontsize=\scriptsize,numberblanklines=false}

\definecolor{codegreen}{rgb}{0,0.5,0}
\definecolor{codegray}{rgb}{0.5,0.5,0.5}
\definecolor{codepurple}{rgb}{0.58,0,0.82}
\definecolor{backcolour}{rgb}{0.96,0.96,0.96}

\lstdefinestyle{tfmstyle}{
    backgroundcolor=\color{backcolour},
    commentstyle=\color{codegreen}\itshape,
    keywordstyle=\color{blue}\bfseries,
    numberstyle=\tiny\color{codegray},
    stringstyle=\color{codepurple},
    basicstyle=\ttfamily\scriptsize,
    breakatwhitespace=false,
    breaklines=true,
    captionpos=b,
    keepspaces=true,
    numbers=left,
    numbersep=8pt,
    showspaces=false,
    showstringspaces=false,
    showtabs=false,
    tabsize=2,
    frame=single,
    rulecolor=\color{black!15}
}

\lstset{style=tfmstyle,
  inputencoding=utf8,
  extendedchars=true,
  literate={á}{{\'a}}1 {é}{{\'e}}1 {í}{{\'i}}1 {ó}{{\'o}}1 {ú}{{\'ú}}1 {ñ}{{\~n}}1,
  basicstyle=\ttfamily\small}

% Ruta donde buscar las figuras
\graphicspath{{figs/}}
\DeclareGraphicsExtensions{.pdf,.jpg,.png}


 \geometry{
  a4paper,
  total={160mm,255mm},
  left=25mm,
  right=25mm,
  top=25mm,
  bottom=20mm
 }

\newlength{\ancho}
\setlength{\ancho}{16cm}


\hypersetup{bookmarks=true,%
bookmarksnumbered=true,%
colorlinks,%
citecolor=red,%
filecolor=blue,%
linkcolor=blue,%
urlcolor=blue,%
pdfstartview=FitH,%
pdffitwindow=true,%
pdfauthor=\@author}

\setlength{\parskip}{5pt}


\newcommand{\master}{
 	{\scshape \LARGE Máster Universitario en Tecnologías Web,}\\[3mm]
   {\scshape \LARGE Computación en la Nube y}\\[3mm]
   {\scshape \LARGE  Aplicaciones Móviles}
}


\newcommand{\portada}{
  \pagestyle{empty}
   \makeatletter
	\centering % Centre everything on the title page
	 % Use small caps for all text on the title page

   \begin{center}
     \includegraphics[width=0.55\ancho]{figs/uv/etse_titulo.png}
   \end{center}

   \vspace*{1\baselineskip} % White space

   \master

   \vspace*{2\baselineskip} % White space

   \begin{center}
      \includegraphics[width=0.35\ancho]{figs/uv/escudo_logo_UV_narrow.png}
   \end{center}

   \vspace*{3\baselineskip} % White space

 	{\scshape \LARGE Trabajo Fin de Máster}

   \vspace*{2\baselineskip} % White space

	% ------------------------------------------------
	%	Title
	%------------------------------------------------
	\rule{\ancho}{1.6pt}\vspace*{-\baselineskip}\vspace*{2pt} % Thick horizontal rule
	\rule{\ancho}{0.4pt} % Thin horizontal rule

	\vspace{0.75\baselineskip} % Whitespace above the title

   \begin{minipage}[h]{\ancho}
     \centering
     \LARGE
     \capsdef{T1/ppl/m/n/5-15}{\scshape}{.16em}{.6em}{.2em}
     \scshape \@title
   \end{minipage}

	\vspace{0.75\baselineskip} % Whitespace below the title

	\rule{\ancho}{0.4pt}\vspace*{-\baselineskip}\vspace{3.2pt} % Thin horizontal rule
	\rule{\ancho}{1.6pt} % Thick horizontal rule

   \vfill

   \hspace*{0.15\ancho}\begin{minipage}[h]{0.85\ancho}
   \large
	\bfseries{\scshape \@authorlabel: \@author} % Author

	\vspace{0.5\baselineskip} % Whitespace below the editor list

	{\scshape \@tutorlabel: \@tutor} % Tutor

  	\vspace{0.5\baselineskip} % Whitespace below the editor list

    {\scshape \@convocatoria}
 \end{minipage}
 \makeatother
 }


 % \newcommand{\contraportada}{
 %   \pagestyle{empty}
 %   \makeatletter
 %   \centering % Centre everything on the title page
 %   \vspace*{0.2\baselineskip} % White space at the top of the page

 %   \begin{center}
 %     \includegraphics[width=\ancho]{figs/logo-contraportada.png}
 %   \end{center}

 %   \vspace*{\baselineskip} % White space

 %   \master

 %   \vspace*{2\baselineskip} % White space

 %   {\scshape \LARGE Trabajo Fin de Máster}

 %   \vspace*{1\baselineskip} % White space

 %   % ------------------------------------------------
 %   %	Title
 %   %------------------------------------------------
 %   \rule{\ancho}{1.6pt}\vspace*{-\baselineskip}\vspace*{2pt} % Thick horizontal rule
 %   \rule{\ancho}{0.4pt} % Thin horizontal rule

 %   \vspace{0.5\baselineskip} % Whitespace above the title

 %   \begin{minipage}[h]{\ancho}
 %     \centering
 %     \LARGE
 %     \capsdef{T1/ppl/m/n/5-15}{\scshape}{.16em}{.6em}{.2em}
 %     \scshape \@title
 %   \end{minipage}

 %   \vspace{0.5\baselineskip} % Whitespace below the title

 %   \rule{\ancho}{0.4pt}\vspace*{-\baselineskip}\vspace{3.2pt} % Thin horizontal rule
 %   \rule{\ancho}{1.6pt} % Thick horizontal rule

 %   \vspace{1\baselineskip} % Whitespace after the title block

 %   \hspace*{0.15\ancho}\begin{minipage}[h]{0.85\ancho}
 %   \large
 %   \bfseries{\scshape \@authorlabel: \@author} % Author

 %   \vspace{0.5\baselineskip} % Whitespace below the editor list

 %   {\scshape \@tutorlabel: \@tutor} % Tutor

 %  	\vspace{0.5\baselineskip} % Whitespace below the editor list
 % \end{minipage}

 %    \vfill

 %   \rule{\ancho}{0.4pt}\vspace*{-\baselineskip}\vspace{3.2pt}

 % 	\vspace{2\baselineskip} % Whitespace after the title block

 %   {\bf TRIBUNAL}

 %  	\vspace{0.3\baselineskip} % Whitespace after the title block

 %   \flushleft PRESIDENTE/A: \hspace*{0.5\ancho}  VOCAL 1:

 %   \vspace{5\baselineskip}

 %   \flushleft VOCAL 2:      \hspace*{0.6\ancho}\begin{minipage}[t]{0.3\ancho}FECHA DE DEFENSA: \\[1cm]
 %                                                      CALIFICACIÓN:
 %                              \end{minipage}

 %   \vfill
 %   \makeatother
 %   \mdseries
 % }


 \newcommand{\declaracion}
 {
   \pagestyle{empty}
   \justify
   \makeatletter

   \vspace*{5cm}
   {\bf Declaración de autoría:}

   \vspace*{1cm}

   Yo, \@author, declaro la autoría del Trabajo Fin de Máster titulado ``\@title{}'' y que el citado trabajo no infringe las leyes en vigor sobre propiedad intelectual. El material no original que figura en este trabajo ha sido atribuido a sus legítimos autores.

   \vspace*{2cm}
   Firmado:


   \vfill
   \makeatother
 }

 \newenvironment{resumen}
    {\begin{center}\begin{tabular}{p{0.9\textwidth}}
       \hline\\
       {\bf Resumen:} \\[3mm]
    }
    {
    \\\\\hline
    \end{tabular}
  \end{center}
    }

 \newenvironment{abstract}
    {\begin{center}\begin{tabular}{p{0.9\textwidth}}
       \hline\\
       {\bf Abstract:} \\[3mm]
    }
    {
    \\\\\hline
    \end{tabular}
  \end{center}
    }


 \newenvironment{resum}
    {\begin{center}\begin{tabular}{p{0.9\textwidth}}
       \hline\\
       {\bf Resum:} \\[3mm]
    }
    {
    \\\\\hline
    \end{tabular}
  \end{center}
    }


  \newenvironment{agradecimientos}
    {\begin{center}\begin{tabular}{p{0.9\textwidth}}
       \hline\\
       {\bf Agradecimientos:} \\[3mm]
    }
    {
    \\\\\hline
    \end{tabular}
  \end{center}
    }


\renewcommand{\UrlFont}{\small}

\definecolor{enlaces}{rgb}{0.6,0.6,0.9}
\definecolor{colurl}{rgb}{0.34,0.36,0.60}

\hypersetup{
    colorlinks = true,
    linkcolor = enlaces,
    citecolor = enlaces,
    filecolor = enlaces,
    urlcolor = enlaces
}



\pagestyle{fancy}

\fancypagestyle{twcam}{%
  %Información del capítulo en la parte exterior
  \fancyhead[EL,OR]{\chaptername{} \thechapter}
  % Información del número de página en la parte interior
  \fancyhead[OL,ER]{\thepage}
  \renewcommand{\headrulewidth}{1pt}
  \fancyfoot{}
}

\fancypagestyle{appendix}{%
  %Información del capítulo en la parte exterior
  \fancyhead[EL,OR]{\appendixname{}}
  % Información del número de página en la parte interior
  \fancyhead[OL,ER]{\thepage}
  \renewcommand{\headrulewidth}{1pt}
  \fancyfoot{}
}

\fancypagestyle{plain}{
  \fancyhf{}
  \renewcommand{\headrulewidth}{0pt}
}
