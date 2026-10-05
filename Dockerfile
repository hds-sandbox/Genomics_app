ARG BASE_IMAGE=dreg.cloud.sdu.dk/ucloud-apps/rstudio:4.5.1
FROM ${BASE_IMAGE}

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

LABEL software="Genomics Sandbox" \
    author="Samuele Soraggi <samuele@birc.au.dk>, Alba Refoyo <alba.martinez@sund.ku.dk>" \
    version="2025.02" \
    license="MIT" \
    description="Courses, datasets and software tools for genomics analysis"


ENV PIXI_PROJECT=/opt
ENV PIXI_ENV=${PIXI_PROJECT}/.pixi/envs/course-env
ENV R_HOME=$PIXI_ENV/lib/R
ENV R_LIBS_USER=$R_HOME/library
ENV SHELL=/bin/bash
ENV PATH=$PIXI_ENV/bin:/home/$USER/bin:/home/$USER/.pixi/bin:$PATH
ENV JUPYTER_ENV_FILE="https://raw.githubusercontent.com/hds-sandbox/common-files_development/refs/heads/main/jupyterlab_and_plugins.yaml"


COPY --chown=$USERID:$GROUPID environments /tmp/environments
COPY --chown=$USERID:$GROUPID scripts/merge-repolist-envs.sh /tmp/merge-repolist-envs.sh

## Set shell
USER 0

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# System dependencies
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
 && mkdir -p "/home/${USER}/.R" \
 && chown -R "${USERID}:${GROUPID}" \
    /opt \
    "/home/${USER}/.R"

WORKDIR /sbin

ARG TINI_=${TINI_:-"latest"}
RUN if [[ "${TINI_}" = "latest" ]]; then export TINI_=$(curl -s https://api.github.com/repos/krallin/tini/releases/latest | jq -r '.tag_name'); fi \
 && wget -q "https://github.com/krallin/tini/releases/download/${TINI_}/tini" \
 && chmod +x tini

USER $USERID

# Install Pixi and create the course environment
WORKDIR ${PIXI_PROJECT}

RUN curl -fsSL https://pixi.sh/install.sh | bash \
 && export PATH="$HOME/.pixi/bin:$PATH" \
 && curl --fail --silent --show-error --location --retry 5 --retry-all-errors --retry-delay 2 -o ./jupyterlab_and_plugins.yml "${JUPYTER_ENV_FILE}" \
 && pixi init \
 && pixi add conda-merge \
 && bash /tmp/merge-repolist-envs.sh /tmp/environments/repolist.txt ./repolist_merged.yml \
 && pixi run conda-merge ./jupyterlab_and_plugins.yml ./repolist_merged.yml > ./environment_merged.yml \
 && pixi import --environment course-env --format conda-env ./environment_merged.yml \
 && cat ./environment_merged.yml

RUN "$HOME/.pixi/bin/pixi" install --environment course-env \
 && "$HOME/.pixi/bin/pixi" run --environment course-env \
    pip install --no-cache-dir -r /tmp/environments/requirements_pixi.txt \
 && "$HOME/.pixi/bin/pixi" run --environment course-env \
    R -e "install.packages(\"rehh\", repos=\"http://cran.r-project.org\", lib=Sys.getenv(\"R_LIBS_USER\"))" \
 && cat >> "/home/${USER}/.bashrc" <<'EOF'
export PIXI_PROJECT=${PIXI_PROJECT}
export PIXI_ENV=${PIXI_ENV}
export PATH="$PIXI_ENV/bin:$HOME/.pixi/bin:$PATH"
export R_HOME=$PIXI_ENV/lib/R
export R_LIBS_USER=$R_HOME/library
export LD_LIBRARY_PATH="$PIXI_ENV/lib:$LD_LIBRARY_PATH"
eval "$(pixi completion --shell bash)"
EOF

# Extra software not available through conda
WORKDIR /home/$USER

COPY --chown=$USERID:$GROUPID Software ./Software

RUN wget --progress=dot:giga "https://zenodo.org/records/14712777/files/bolt_2.4.1.zip?download=1" -O boltLMM.zip \
 && unzip -qq boltLMM.zip -d boltLMM \
 && rm boltLMM.zip \
 && chmod 755 boltLMM/bolt \
 && chmod 755 -R ./Software \
 && ln -s "$PWD/boltLMM/bolt" "$PIXI_ENV/bin/bolt" \
 && ln -s "$PWD/Software/ldak6.3.linux" "$PIXI_ENV/bin/ldak" \
 && ln -s "$PWD/Software/PRSice" "$PIXI_ENV/bin/PRSice"

## Set startup script in the PATH
## entrypoint script
COPY --chown=$USERID:$GROUPID scripts/start-app /usr/bin/start-app

RUN chmod 755 /usr/bin/start-app

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["bash"]

WORKDIR /work