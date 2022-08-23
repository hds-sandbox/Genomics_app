FROM dreg.cloud.sdu.dk/ucloud-apps/jupyter-all-spark:3.4.2
#jupyter/minimal-notebook:latest

MAINTAINER "Samuele Soraggi <samuele@birc.au.dk>"

LABEL software="GenomicsCourses" \
      author="Samuele Soraggi" \
      version="v2022.08.01" \
      license="MIT" \
      description="NGS summer school Aarhus"


USER 0

RUN fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

############# NGS summer course
RUN mkdir -p /usr/NGS_summer_course
RUN fix-permissions "/usr/NGS_summer_course"
WORKDIR /usr/NGS_summer_course
RUN git init && \
      git remote add origin https://github.com/hds-sandbox/NGS_summer_course_Aarhus.git && \
      git config core.sparseCheckout true && \
      echo "Environments/" >> .git/info/sparse-checkout && \
      echo "Notebooks/" >> .git/info/sparse-checkout && \
      echo "Scripts/" >> .git/info/sparse-checkout && \
      git pull --depth=1 origin main
###data download
RUN mkdir -p /usr/NGS_summer_course/Data && \
    curl https://zenodo.org/record/6952995/files/clover.tar.gz?download=1 -o /usr/NGS_summer_course/Data/Clover_Data.tar.gz && \
    tar -zxvf /usr/NGS_summer_course/Data/Clover_Data.tar.gz -C /usr/NGS_summer_course/Data/
RUN curl https://zenodo.org/record/6952995/files/singlecell.tar.gz?download=1 -o /usr/NGS_summer_course/Data/scrna_Data.tar.gz && \
    tar -zxvf /usr/NGS_summer_course/Data/scrna_Data.tar.gz -C /usr/NGS_summer_course/Data/ && \
    rm -f /usr/NGS_summer_course/Data/*.tar.gz
#create environments
RUN mamba env create -p "${CONDA_DIR}/envs/NGS_aarhus_py" -f /usr/NGS_summer_course/Environments/python_environment.yml && \
    mamba env create -p "${CONDA_DIR}/envs/NGS_aarhus_r" -f /usr/NGS_summer_course/Environments/R_environment.yml && \
    mamba clean --all -f -y
#install kernels - this goes into start-jupyter
#RUN "${CONDA_DIR}/envs/NGS_aarhus_py/bin/python" -m ipykernel install --user --name="NGS_python" --display-name "NGS (python)" && \
#    /opt/conda/envs/NGS_aarhus_r/bin/R -e "IRkernel::installspec(user=TRUE, name = 'NGS_R', displayname = 'NGS (R)')" && \
#    fix-permissions "${CONDA_DIR}" && \
#    fix-permissions "/home/${NB_USER}"
### modify kernel files with system variables
#RUN cp ./Course_Material/Environments/kernel_py_docker.json ~/.local/share/jupyter/kernels/ngs_python/kernel.json && \
#    cp ./Course_Material/Environments/kernel_R_docker.json ~/.local/share/jupyter/kernels/ngs_r/kernel.json

## Set startup script in the PATH
COPY --chown=${NB_USER}:${NB_GID} start-jupyter ${CONDA_DIR}/bin/
RUN chmod +x ${CONDA_DIR}/bin/start-jupyter
#COPY --chown=${NB_USER}:${NB_GID} start-jupyter ${CONDA_DIR}/bin/
#RUN sed -i -e 's/\r$//' ${CONDA_DIR}/bin/start-jupyter \
# && chmod +x ${CONDA_DIR}/bin/start-jupyter

WORKDIR /work