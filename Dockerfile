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

## Environments files and scripts
COPY --chown=$USERID:$GROUPID environments /tmp/environments


## Permissions and JupyterLab Extensions
# hadolint ignore=DL3016 # 'libgl1-mesa-glx'
RUN sudo apt-get update \
&& sudo apt-get install --no-install-recommends -y xxd build-essential libjpeg9 libcurl4-openssl-dev libxml2-dev libssl-dev libicu-dev \
&& sudo apt-get clean \
&& sudo rm -rf /var/lib/apt/lists/* \
&& curl -fsSL https://pixi.sh/install.sh | bash \
&& echo "export PATH=\$PATH:/home/ucloud/.pixi/bin" >> /home/ucloud/.bashrc \
&& echo 'eval "\$(pixi completion --shell bash)"' >> /home/ucloud/.bashrc \
&& export PATH=$PATH:/home/ucloud/.pixi/bin && eval "$(pixi completion --shell bash)" \
&& sudo mkdir -p /opt/pixi/envs/Course_Env && sudo chown -R $USERID:$GROUPID /opt/pixi\
&& cd /opt/pixi/envs/Course_Env \
&& pixi init --import /tmp/environments/env_popgen_ngs_pixi.yml \
&& pixi install && pixi run /opt/pixi/envs/Course_Env/.pixi/envs/default/bin/pip install -r /tmp/environments/requirements_pixi.txt \
&& pixi run R -e 'install.packages("rehh", repos="http://cran.r-project.org", lib="/opt/pixi/envs/Course_Env/.pixi/envs/default/lib/R/library")'
##########
RUN  sudo mkdir -p /opt/software && sudo chown -R $USERID:$GROUPID /opt/software \
    && wget https://zenodo.org/records/14712777/files/bolt_2.4.1.zip?download=1 -O /opt/software/boltLMM.zip \
    && unzip /opt/software/boltLMM.zip && rm /opt/software/boltLMM.zip \
    && wget https://zenodo.org/records/14712871/files/gcta-1.94.3-linux-kernel-3-x86_64.zip?download=1 -O /opt/software/gcta.zip \
    && unzip /opt/software/gcta.zip && rm /opt/software/gcta.zip \
    && echo "export PATH=\$PATH:/opt/software/boltLMM:/opt/software/gcta-1.94.3-linux-kernel-3-x86_64" >> /home/ucloud/.bashrc 

## Executables
COPY --chown=$USERID:$GROUPID ./Software ./Software
RUN chmod -R 755 ./Software

## Set startup script in the PATH
## entrypoint script
COPY --chown=$USERID:$GROUPID ./scripts/start-app /usr/bin/start-app

RUN chmod 755 /usr/bin/start-app \
    && sudo chown -R $USERID:$GROUPID /etc/rstudio/

WORKDIR /work
