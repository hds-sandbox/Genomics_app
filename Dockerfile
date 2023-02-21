FROM dreg.cloud.sdu.dk/ucloud-apps/jupyter-base:3.6.1

MAINTAINER "Samuele Soraggi <samuele@birc.au.dk>"

LABEL software="Genomics Sandbox" \
      author="Samuele Soraggi" \
      version="2023.03.01" \
      license="MIT" \
      description="Courses, datasets and software tools for genomics analysis"

#  docker build -t genomicssandbox:v2023.03.01 .
#  docker run --rm -it -p 8888:8888 -p 8850:8850 --name genomicssandbox genomicssandbox:v2023.03.01 /bin/bash start-jupyter

USER 0

# Create material folder and add JupyterLab Extensions
RUN mkdir /work/Material && \
 fix-permissions "/work/Material/" && \
 fix-permissions "/home/${NB_USER}" && \
 fix-permissions "${CONDA_DIR}" && \
 printf "Install JupyterLab extensions:" && \    
 pip install jupyter_server && \
 pip install --no-cache-dir "nteract-on-jupyter" && \
 #&& jupyter labextension install "jupyter-threejs" \
 #&& jupyter labextension install "ipyvolume" \
 ## add support for LaTeX docs
 pip install --no-cache-dir "jupyterlab-latex" && \
 ## open spreadsheets such as Excel and OpenOffice
 #jupyter labextension install "jupyterlab-spreadsheet" && \
 ## add top bar
 pip install --no-cache-dir "jupyterlab-topbar" && \
 pip install --no-cache-dir "jupyterlab-topbar-text" && \
 ## add system monitor
 pip install --no-cache-dir "jupyterlab-system-monitor" && \
 ## add theme toggle bottom
 #&& jupyter labextension install "jupyterlab-theme-toggle" \
 ## add code formatter
 pip install --no-cache-dir "autopep8" "yapf" "isort" "black" && \
 pip install --no-cache-dir "jupyterlab_code_formatter" && \
 ## add nbdime
 # && pip install --no-cache-dir "nbdime" \
 ## add Bokeh extension
 pip install --no-cache-dir "jupyter_bokeh" && \
 ## add Plotly extension
 pip install --no-cache-dir  "plotly" && \
 pip install --no-cache-dir "jupyter-dash" && \
 #jupyter labextension install "jupyterlab-plotly" 
 jupyter lab build -y

## setup for the IGV browser
RUN npm install --global http-server && \
 git clone -b v1.12.9 https://github.com/igvteam/igv-webapp.git /usr/igv-webapp && \
 fix-permissions /usr/igv-webapp && \
 npm install --prefix /usr/igv-webapp && \
 npm run --prefix /usr/igv-webapp build && \
 npm --force cache clean


USER 11042

WORKDIR /work/Material


## Set startup script in the PATH
COPY --chown="${NB_USER}":"${NB_GID}" start-jupyter "${CONDA_DIR}"/bin/
RUN chmod +x "${CONDA_DIR}"/bin/start-jupyter

