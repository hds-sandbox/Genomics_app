ARG BASE_IMAGE

FROM $BASE_IMAGE

LABEL software="Genomics Sandbox" \
      author="Samuele Soraggi <samuele@birc.au.dk>" \
      version="2025.02" \
      license="MIT" \
      description="Courses, datasets and software tools for genomics analysis"

USER $USERID

EXPOSE 8787
      
## Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

## Environments files and scripts
COPY --chown=$USERID:$GROUPID environments /tmp/environments
COPY --chown=$USERID:$GROUPID ./Software ./Software


## Permissions and JupyterLab Extensions
# hadolint ignore=DL3016 # 'libgl1-mesa-glx'
RUN sudo apt-get update \
&& sudo apt-get install --no-install-recommends -y xxd build-essential libjpeg9 libcurl4-openssl-dev libxml2-dev libssl-dev libicu-dev texlive-xetex texlive-fonts-recommended texlive-plain-generic pandoc \
&& sudo apt-get clean \
&& sudo rm -rf /var/lib/apt/lists/* \
&& curl -fsSL https://pixi.sh/install.sh | bash \
&& export PATH=$PATH:/home/ucloud/.pixi/bin && eval "$(pixi completion --shell bash)" \
&& sudo mkdir -p /opt/pixi/envs/Course_Env && sudo chown -R $USERID:$GROUPID /opt/pixi\
&& cd /opt/pixi/envs/Course_Env \
&& pixi init --import /tmp/environments/env_popgen_ngs_pixi.yml \
&& pixi install && pixi run /opt/pixi/envs/Course_Env/.pixi/envs/default/bin/pip install -r /tmp/environments/requirements_pixi.txt \
&& pixi run R -e "install.packages(\"rehh\", repos=\"http://cran.r-project.org\", lib=\"/opt/pixi/envs/Course_Env/.pixi/envs/default/lib/R/library\")" \
&& cd /work && chmod -R 755 ./Software && cd ./Software \
&& wget https://zenodo.org/records/14712777/files/bolt_2.4.1.zip?download=1 -O boltLMM.zip \
&& unzip boltLMM.zip -d boltLMM && rm boltLMM.zip \
&& sudo chmod 755 -R /work/Software/ && cd .. \
&& export PATH=$PATH:/home/ucloud/.pixi/bin && eval "$(pixi completion --shell bash)" \
&& ln -s /opt/pixi/envs/Course_Env/.pixi && ln -s /opt/pixi/envs/Course_Env/pixi.toml \
&& echo "export PATH=\$PATH:/work/Software/boltLMM" >> /home/ucloud/.bashrc \
&& ln -s /work/Software/boltLMM/bolt /opt/pixi/envs/Course_Env/.pixi/envs/default/bin/bolt \
&& echo 'eval "$(pixi completion --shell bash)"' >> /home/ucloud/.bashrc 

    

## Set startup script in the PATH
## entrypoint script
COPY --chown=$USERID:$GROUPID ./scripts/start-app /usr/bin/start-app

RUN chmod 755 /usr/bin/start-app \
    && sudo chown -R $USERID:$GROUPID /etc/rstudio/

WORKDIR /work
