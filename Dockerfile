FROM dreg.cloud.sdu.dk/ucloud-apps/jupyter-base:3.6.1

MAINTAINER "Samuele Soraggi <samuele@birc.au.dk>"

LABEL software="Genomics Sandbox" \
      author="Samuele Soraggi" \
      version="v2023.03.01" \
      license="MIT" \
      description="Courses, datasets and software tools for genomics analysis"

#  docker build -t genomicssandbox:v2023.03.01 .
#  docker run --rm -it -p 8888:8888 -p 8850:8850 --name genomicssandbox genomicssandbox:v2023.03.01 /bin/bash start-jupyter



USER 0

EXPOSE 8850
EXPOSE 8888

## Environments files
COPY ./environments/ /home/${NB_USER}/environments


## make course folder
RUN mkdir /work/Material && \
 ## Permissions
 fix-permissions "/work/Material/" && \
 fix-permissions "/home/${NB_USER}" && \
 fix-permissions "${CONDA_DIR}" && \
 ## create conda environment(s)
 mamba env create -f /home/${NB_USER}/environments/env_popgen_ngs.full.yml -p ${CONDA_DIR}/envs/Course_Env && \
 cp ${CONDA_DIR}/envs/Course_Env/lib/libcrypto.so.3 ${CONDA_DIR}/envs/Course_Env/lib/libcrypto.so.1.0.0 && \
 ln -sf ${CONDA_DIR}/envs/Course_Env /work/Material/Course_Env && \
 mamba clean --all -f -y && \
 ## add JupyterLab Extensions
 printf "Install JupyterLab extensions:" && \    
 pip install --no-cache-dir "jupyter_server" && \
 pip install --no-cache-dir "nteract-on-jupyter" && \
 ## tabular data reader and editor
 pip install --no-cache-dir "jupyterlab-tabular-data-editor" && \
 ## add support for LaTeX docs
 pip install --no-cache-dir "jupyterlab-latex" && \
 ## add top bar
 pip install --no-cache-dir "jupyterlab-topbar" && \
 pip install --no-cache-dir "jupyterlab-topbar-text" && \
 ## add system monitor
 pip install --no-cache-dir "jupyterlab-system-monitor" && \
 ## add code formatter
 pip install --no-cache-dir "autopep8" "yapf" "isort" "black" && \
 pip install --no-cache-dir "jupyterlab_code_formatter" && \
 ## add Bokeh extension
 pip install --no-cache-dir "jupyter_bokeh" && \
 ## add Plotly extension
 pip install --no-cache-dir  "plotly" && \
 pip install --no-cache-dir "jupyter-dash" && \
 jupyter lab build -y && \
 jupiter lab clean && \
 ## setup for the IGV browser
 npm install --global http-server && \
 git clone -b v1.12.9 https://github.com/igvteam/igv-webapp.git /usr/igv-webapp && \
 fix-permissions /usr/igv-webapp && \
 npm install --prefix /usr/igv-webapp && \
 npm run --prefix /usr/igv-webapp build && \
 npm --force cache clean

USER 11042

## Set startup script in the PATH
COPY --chown="${NB_USER}":"${NB_GID}" start-jupyter ${CONDA_DIR}/bin/
## executable start script
RUN chmod +x ${CONDA_DIR}/bin/start-jupyter

WORKDIR /work/Material