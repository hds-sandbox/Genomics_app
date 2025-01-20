ARG BASE_IMAGE

FROM $BASE_IMAGE

LABEL software="Genomics Sandbox" \
      author="Samuele Soraggi <samuele@birc.au.dk>" \
      version="2025.02" \
      license="MIT" \
      description="Courses, datasets and software tools for genomics analysis"

USER $USERID

ENV G_SLICE=always-malloc
      
## Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

## Environments files
COPY --chown=$USERID:$GROUPID environments /tmp/environments


## Permissions and JupyterLab Extensions
# hadolint ignore=DL3016 # 'libgl1-mesa-glx'
RUN sudo apt-get update \ 
&& sudo apt-get install --no-install-recommends -y xxd build-essential libjpeg9 libcurl4-openssl-dev libxml2-dev libssl-dev libicu-dev \
&& sudo apt-get clean \
&& sudo rm -rf /var/lib/apt/lists/* \
&& sudo mkdir -p /opt/miniconda \
&& sudo chown -R $USERID:$GROUPID /opt/miniconda \
&& wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /opt/miniconda/miniconda.sh \
&& bash /opt/miniconda/miniconda.sh -b -u -p /opt/miniconda \
&& rm -rf /opt/miniconda/miniconda.sh \
&& eval "$(/opt/miniconda/bin/conda shell.bash hook)" \
&& conda config --set channel_priority flexible \
&& conda install -n base --yes conda-libmamba-solver \
&& conda config --set solver libmamba \
## create conda environment(s)
&& conda env create -vv -f /tmp/environments/env_popgen_ngs.yml -p /opt/miniconda/envs/Course_Env \
&& conda clean --all -f -y \
## Install R package
&& eval "$(conda shell.bash hook)" \
&& conda activate /opt/miniconda/envs/Course_Env \
&& /opt/miniconda/envs/Course_Env/bin/R -e "install.packages('rehh', repos='http://cran.r-project.org', lib='/opt/miniconda/envs/Course_Env/lib/R/library/')" \
&& conda deactivate \
## Setup for the IGV browser
&& npm install --global http-server \
&& git clone -b master https://github.com/igvteam/igv-webapp.git /usr/igv-webapp \
&& chmod -R 755 /usr/igv-webapp \
&& npm install --prefix /usr/igv-webapp \
&& npm run --prefix /usr/igv-webapp build \
&& npm --force cache clean


#RUN printf "\nInstall JupyterLab extensions:\n" \
# && pip install --no-cache-dir --upgrade "pip" "setuptools" "wheel" \
# && pip install --no-cache-dir --upgrade "jupyter-server" "jupyter-server-terminals" \
# && pip install --no-cache-dir "nbconvert" \
# && pip install --no-cache-dir "nteract-on-jupyter" \
# ## add top bar
# && pip install --no-cache-dir "jupyterlab-topbar" \
# && pip install --no-cache-dir "jupyterlab-topbar-text" \
# ## add system monitor
# && pip install --no-cache-dir "jupyterlab-system-monitor" \
# ## add code formatter
# && pip install --no-cache-dir "autopep8" "yapf" "isort" "black" \
# && pip install --no-cache-dir "jupyterlab_code_formatter" \
### add Bokeh extension
# && pip install --no-cache-dir "jupyter_bokeh" \
# ## add Plotly extension
# && pip install --no-cache-dir  "plotly" \
# && pip install --no-cache-dir "jupyter-dash" \
#&& jupyter lab build -y \
#&& jupyter lab clean -y

## Executables
COPY --chown=$USERID:$GROUPID ./Software ./Software
RUN chmod -R 755 ./Software

## Set startup script in the PATH
## entrypoint script
COPY --chown=$USERID:$GROUPID ./scripts/start-app /usr/bin/start-app

RUN chmod 755 /usr/bin/start-app \
    && sudo chown -R $USERID:$GROUPID /etc/rstudio/

WORKDIR /work
