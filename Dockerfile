FROM dreg.cloud.sdu.dk/ucloud-apps/jupyter-base:3.6.1

MAINTAINER "Samuele Soraggi <samuele@birc.au.dk>"

LABEL software="Genomics Sandbox" \
      author="Samuele Soraggi" \
      version="2023.03.01" \
      license="MIT" \
      description="Courses, datasets and software tools for genomics analysis"

USER 0

## Environments files
COPY --chown="${NB_USER}":"${NB_GID}" environments /home/${NB_USER}/environments


## Permissions and JupyterLab Extensions
# hadolint ignore=DL3016
RUN fix-permissions "/home/${NB_USER}" \
 && fix-permissions "${CONDA_DIR}" \
 ##Install libGL-mesa
 && apt-get update && apt-get install -y xxd libgl1-mesa-glx && apt-get clean \
 ## create conda environment(s)
 && mamba env create -f /home/"${NB_USER}"/environments/env_popgen_ngs.full.yml -p "${CONDA_DIR}"/envs/Course_Env \
 && mamba clean --all -f -y \
 ## Install R package
 && eval "$(conda shell.bash hook)" \
 && conda activate /opt/conda/envs/Course_Env \
 && /opt/conda/envs/Course_Env/bin/R -e "install.packages('rehh', repos='http://cran.r-project.org', lib='/opt/conda/envs/Course_Env/lib/R/library/')" \
 && conda deactivate \
 ## Setup for the IGV browser
 && npm install --global http-server \
 &&  git clone -b v1.12.9 https://github.com/igvteam/igv-webapp.git /usr/igv-webapp \
 && fix-permissions /usr/igv-webapp \
 && npm install --prefix /usr/igv-webapp \
 && npm run --prefix /usr/igv-webapp build \
 && npm --force cache clean

USER $NB_UID

RUN printf "\nInstall JupyterLab extensions:\n" \
 && pip install --no-cache-dir --upgrade "pip" "setuptools" "wheel" \
 && pip install --no-cache-dir --upgrade "jupyter-server" "jupyter-server-terminals" \
 && pip install --no-cache-dir "nbconvert" \
 && pip install --no-cache-dir "nteract-on-jupyter" \
 ## add top bar
 && pip install --no-cache-dir "jupyterlab-topbar" \
 && pip install --no-cache-dir "jupyterlab-topbar-text" \
 ## add system monitor
 && pip install --no-cache-dir "jupyterlab-system-monitor" \
 ## add code formatter
 && pip install --no-cache-dir "autopep8" "yapf" "isort" "black" \
 && pip install --no-cache-dir "jupyterlab_code_formatter" \
 ## add Bokeh extension
 && pip install --no-cache-dir "jupyter_bokeh" \
 ## add Plotly extension
 && pip install --no-cache-dir  "plotly" \
 && pip install --no-cache-dir "jupyter-dash" \
 && jupyter lab build -y \
 && jupyter lab clean -y

## Executables
COPY --chown="${NB_USER}":"${NB_GID}" ./Software /home/ucloud/Software
RUN chmod -R 755 /home/ucloud/Software/

## Set startup script in the PATH
COPY --chown="${NB_USER}":"${NB_GID}" start-jupyter "${CONDA_DIR}"/bin/
RUN chmod 755 "${CONDA_DIR}"/bin/start-jupyter

WORKDIR /work
