ARG BASE_IMAGE=dreg.cloud.sdu.dk/ucloud-apps/rstudio:4.4.2

FROM $BASE_IMAGE

LABEL software="Genomics Sandbox" \
      author="Samuele Soraggi <samuele@birc.au.dk>, Emiliano Molinaro <molinaro@imada.sdu.dk>" \
      version="2025.02" \
      license="MIT" \
      description="Courses, datasets and software tools for genomics analysis"

USER 0

## Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

## Permissions and JupyterLab Extensions
RUN apt-get update \
 && apt-get install --no-install-recommends -y \
    build-essential \
    pandoc \
    libicu-dev \
    libcurl4-openssl-dev \
    libjpeg9 libssl-dev \
    libxml2-dev \
    texlive-fonts-recommended \
    texlive-plain-generic \
    texlive-xetex xxd \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /opt/pixi \
 && chown "${USERID}":"${GROUPID}" /opt/pixi

WORKDIR /sbin

ARG TINI_=${TINI_:-"latest"}
RUN if [[ "${TINI_}" = "latest" ]]; then export TINI_=$(curl -s https://api.github.com/repos/krallin/tini/releases/latest | jq -r '.tag_name'); fi \
 && wget -q "https://github.com/krallin/tini/releases/download/${TINI_}/tini" \
 && chmod +x tini

USER $USERID

## Environments files and scripts
COPY --chown=$USERID:$GROUPID environments /tmp/environments

WORKDIR /opt/pixi

ENV PATH=$PATH:/home/$USER/bin:/home/$USER/.pixi/bin

RUN curl -fsSL https://pixi.sh/install.sh | bash \
 && eval "$(pixi completion --shell bash)" \
 && mkdir -p ./envs/Course_Env

WORKDIR /opt/pixi/envs/Course_Env

RUN pixi init --import /tmp/environments/env_popgen_ngs_pixi.yml \
 && pixi install \
 && pixi run /opt/pixi/envs/Course_Env/.pixi/envs/default/bin/pip install -r /tmp/environments/requirements_pixi.txt \
 && pixi run R -e "install.packages(\"rehh\", repos=\"http://cran.r-project.org\", lib=\"/opt/pixi/envs/Course_Env/.pixi/envs/default/lib/R/library\")"

WORKDIR /home/$USER

# RUN wget -q --recursive --no-parent "ftp://ftp.escience.sdu.dk/support/genomics/2025.02/Software/" \
#  && mv ftp.escience.sdu.dk/support/genomics/2025.02/Software . \
#  && rm -rf ftp.escience.sdu.dk/support/genomics/2025.02 \
#  && chown -R "${USEID}":"${GROUPID}" Software \
#  && chmod -R 755 Software/*

COPY --chown=$USERID:$GROUPID Software ./Software

ENV PATH=$PATH:/opt/pixi/envs/Course_Env/.pixi/envs/default/bin

# hadolint igonre=SC2016 
RUN wget --progress=dot:giga "https://zenodo.org/records/14712777/files/bolt_2.4.1.zip?download=1" -O boltLMM.zip \
 && unzip -qq boltLMM.zip -d boltLMM \
 && rm boltLMM.zip \
 && chmod 755 boltLMM/bolt \ 
# && git clone --depth 1  https://github.com/hds-sandbox/GWAS_course.git /tmp/gwas_course \
# && mv /tmp/gwas_course/Software/* . \
# && rm -rf /tmp/gwas_course \
 && chmod 755 -R ./Software \
 && ln -s /opt/pixi/envs/Course_Env/pixi.toml /opt/pixi/envs/Course_Env/.pixi/envs/default/pixi.toml \
 && ln -s "$PWD/boltLMM/bolt" /opt/pixi/envs/Course_Env/.pixi/envs/default/bin/bolt \
 && ln -s "$PWD/Software/ldak" /opt/pixi/envs/Course_Env/.pixi/envs/default/bin/ldak \
 && ln -s "$PWD/Software/PRSice" /opt/pixi/envs/Course_Env/.pixi/envs/default/bin/PRSice \
 && echo 'eval "$(pixi completion --shell bash)"' >> "/home/${USER}/.bashrc"

## Set startup script in the PATH
## entrypoint script
COPY --chown=$USERID:$GROUPID scripts/start-app.sh /usr/bin/start-app

RUN chmod 755 /usr/bin/start-app

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["bash"]

WORKDIR /work
