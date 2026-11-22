ARG BASE_TAG="1.19.0"
ARG BASE_IMAGE="core-ubuntu-noble"
ARG BASE_REGISTRY="rd-harbor-secops.servicemicro.net/infra/kasmweb"

FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG}

ARG FIREFOX_VERSION="159.0.1"
ENV FIREFOX_VERSION=${FIREFOX_VERSION}

USER root

ENV HOME=/home/kasm-default-profile
ENV STARTUPDIR=/dockerstartup

WORKDIR $HOME

# Environment config
ENV DEBIAN_FRONTEND=noninteractive \
    SKIP_CLEAN=true \
    KASM_RX_HOME=$STARTUPDIR/kasmrx \
    DONT_PROMPT_WSL_INSTALL="No_Prompt_please" \
    INST_DIR=$STARTUPDIR/install \
    INST_SCRIPTS="/ubuntu/install/firefox/install_firefox.sh \
                  /ubuntu/install/cleanup/cleanup.sh"

# Copy installation scripts
COPY images/firefox/scripts/install_firefox.sh $INST_DIR/ubuntu/install/firefox/install_firefox.sh
COPY shared/browser/cleanup.sh $INST_DIR/ubuntu/install/cleanup/cleanup.sh

# Restrict APT index downloads to amd64
RUN rm -rf /var/lib/apt/lists/* && \
    printf 'APT::Architectures { "amd64"; };\n' \
      > /etc/apt/apt.conf.d/99architecture

# Install Firefox
RUN for SCRIPT in $INST_SCRIPTS; do \
      bash ${INST_DIR}${SCRIPT} || exit 1; \
    done

# Configure XFCE for Single Application
RUN cp $HOME/.config/xfce4/xfconf/single-application-xfce-perchannel-xml/* \
       $HOME/.config/xfce4/xfconf/xfce-perchannel-xml/ && \
    apt-get remove -y xfce4-panel

# Copy Firefox startup script
COPY images/firefox/scripts/custom_startup.sh $STARTUPDIR/custom_startup.sh

RUN chmod 755 $STARTUPDIR/custom_startup.sh

# Set startup command and process monitor
ENV START_COMMAND="$STARTUPDIR/custom_startup.sh"
ENV PGREP="firefox"

# Enterprise policies: tắt cập nhật, cài sẵn uBlock Origin
COPY images/firefox/configs/policies.json /opt/firefox/distribution/policies.json

RUN chown root:root /opt/firefox/distribution && \
    chown root:root /opt/firefox/distribution/policies.json && \
    chmod 755 /opt/firefox/distribution && \
    chmod 644 /opt/firefox/distribution/policies.json

# Set permissions
RUN $STARTUPDIR/set_user_permission.sh $HOME && \
    rm -f /etc/X11/xinit/Xclients && \
    chown 1000:0 $HOME && \
    mkdir -p /home/kasm-user && \
    chown -R 1000:0 /home/kasm-user && \
    rm -rf ${INST_DIR}

# Userspace Runtime
ENV HOME=/home/kasm-user

WORKDIR $HOME

USER 1000

CMD ["--tail-log"]