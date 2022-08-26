FROM dreg.cloud.sdu.dk/ucloud-apps/jupyter-base:3.4.2
# dreg.cloud.sdu.dk/ucloud-apps/jupyter-all-spark:3.4.2

MAINTAINER "Samuele Soraggi <samuele@birc.au.dk>"

LABEL software="Genomics Courses" \
      author="Samuele Soraggi" \
      version="v2022.08.01" \
      license="MIT" \
      description="Genomics sandbox"


USER 0

RUN printf "Install JupyterLab extensions:" \
 && pip install --no-cache-dir "nteract-on-jupyter" \
 && jupyter labextension install "jupyter-threejs" \
 && jupyter labextension install "ipyvolume" \
 && jupyter lab clean -y \
 ## add support for LaTeX docs
 && pip install --no-cache-dir "jupyterlab-latex" \
 ## open spreadsheets such as Excel and OpenOffice
 && jupyter labextension install "jupyterlab-spreadsheet" \
 && jupyter lab clean -y \
 ## add top bar
 && pip install --no-cache-dir "jupyterlab-topbar" \
 && jupyter labextension install "jupyterlab-topbar-text" \
 && jupyter lab clean -y \
 ## add system monitor
 && pip install --no-cache-dir "jupyterlab-system-monitor" \
 ## add theme toggle bottom
 && jupyter labextension install "jupyterlab-theme-toggle" \
 && jupyter lab clean -y \
 ## add code formatter
 && pip install --no-cache-dir "autopep8" "yapf" "isort" "black" \
 && pip install --no-cache-dir "jupyterlab_code_formatter" \
 && jupyter lab build -y \
 && jupyter lab clean -y \
 && fix-permissions "/home/${NB_USER}" \
 ## add variableInspector
 && pip install --no-cache-dir "lckr-jupyterlab-variableinspector" \
 ## add nbdime
 && pip install --no-cache-dir "nbdime" \
 ## add Bokeh extension
 && pip install --no-cache-dir "jupyter_bokeh" \
 ## add Plotly extension
 && pip install --no-cache-dir  "plotly" \
 && jupyter labextension install "jupyterlab-plotly" \
 && fix-permissions "/home/${NB_USER}"  

RUN fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"


############# Intro to NGS (Aarhus summer course) - release 2022.08.01
RUN mkdir -p /usr/Intro_to_NGS
RUN fix-permissions "/usr/Intro_to_NGS"
WORKDIR /usr/Intro_to_NGS
RUN git init && \
      git remote add origin https://github.com/hds-sandbox/NGS_summer_course_Aarhus.git && \
      git config core.sparseCheckout true && \
      echo "Environments/" >> .git/info/sparse-checkout && \
      echo "Notebooks/" >> .git/info/sparse-checkout && \
      echo "Scripts/" >> .git/info/sparse-checkout && \
      git pull --depth=1 origin main
###data download
RUN mkdir -p /usr/Intro_to_NGS/Data && \
    curl https://zenodo.org/record/6952995/files/clover.tar.gz?download=1 -o /usr/Intro_to_NGS/Data/Clover_Data.tar.gz && \
    tar -zxvf /usr/Intro_to_NGS/Data/Clover_Data.tar.gz -C /usr/Intro_to_NGS/Data/
RUN curl https://zenodo.org/record/6952995/files/singlecell.tar.gz?download=1 -o /usr/Intro_to_NGS/Data/scrna_Data.tar.gz && \
    tar -zxvf /usr/Intro_to_NGS/Data/scrna_Data.tar.gz -C /usr/Intro_to_NGS/Data/ && \
    rm -f /usr/Intro_to_NGS/Data/*.tar.gz
#create environments
RUN mamba env create -p "${CONDA_DIR}/envs/NGS_aarhus_py" -f /usr/Intro_to_NGS/Environments/python_environment.yml && \
    mamba env create -p "${CONDA_DIR}/envs/NGS_aarhus_r" -f /usr/Intro_to_NGS/Environments/R_environment.yml && \
    mamba clean --all -f -y && \
    rm -rf 
    

## Set startup script in the PATH
COPY --chown=${NB_USER}:${NB_GID} start-jupyter ${CONDA_DIR}/bin/
RUN chmod +x ${CONDA_DIR}/bin/start-jupyter
RUN chown -R ${NB_USER}:${NB_GID} /usr/Intro_to_NGS
#COPY --chown=${NB_USER}:${NB_GID} start-jupyter ${CONDA_DIR}/bin/
#RUN sed -i -e 's/\r$//' ${CONDA_DIR}/bin/start-jupyter \
# && chmod +x ${CONDA_DIR}/bin/start-jupyter

WORKDIR /work

USER 11042