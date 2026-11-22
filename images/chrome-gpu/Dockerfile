ARG BASE_TAG="1.19.0"
ARG BASE_IMAGE="core-ubuntu-noble"
ARG BASE_REGISTRY="rd-harbor-secops.servicemicro.net/infra/kasmweb"

FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG}

USER root

ENV HOME=/home/kasm-default-profile
ENV STARTUPDIR=/dockerstartup
ENV NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility,graphics,video,display
ENV LIBVA_DRIVER_NAME=nvidia \
    NVD_BACKEND=direct

WORKDIR $HOME

# Environment config
ENV DEBIAN_FRONTEND=noninteractive \
    SKIP_CLEAN=true \
    KASM_RX_HOME=$STARTUPDIR/kasmrx \
    DONT_PROMPT_WSL_INSTALL="No_Prompt_please" \
    INST_DIR=$STARTUPDIR/install \
    INST_SCRIPTS="/ubuntu/install/chrome/install_chrome.sh \
                  /ubuntu/install/cleanup/cleanup.sh"

# Copy installation scripts
COPY images/chrome-gpu/scripts/install_chrome.sh $INST_DIR/ubuntu/install/chrome/install_chrome.sh
COPY shared/browser/cleanup.sh $INST_DIR/ubuntu/install/cleanup/cleanup.sh

# Restrict APT index downloads to amd64
RUN rm -rf /var/lib/apt/lists/* && \
    printf 'APT::Architectures { "amd64"; };\n' \
      > /etc/apt/apt.conf.d/99architecture

# Install Chrome
RUN for SCRIPT in $INST_SCRIPTS; do \
      bash ${INST_DIR}${SCRIPT} || exit 1; \
    done

# Configure XFCE for Single Application
RUN cp $HOME/.config/xfce4/xfconf/single-application-xfce-perchannel-xml/* \
       $HOME/.config/xfce4/xfconf/xfce-perchannel-xml/ && \
    apt-get remove -y xfce4-panel

# Copy Chrome startup script
COPY images/chrome-gpu/scripts/custom_startup.sh $STARTUPDIR/custom_startup.sh

RUN chmod 755 $STARTUPDIR/custom_startup.sh

# COPY images/chrome-gpu/configs/kasmvnc.yaml /etc/kasmvnc/kasmvnc.yaml
# RUN chown root:root /etc/kasmvnc/kasmvnc.yaml && \
#     chmod 644 /etc/kasmvnc/kasmvnc.yaml

# Set startup command and process monitor
ENV START_COMMAND="$STARTUPDIR/custom_startup.sh"
ENV PGREP="google-chrome"

COPY shared/browser/ublock_extension.json \
    /etc/opt/chrome/policies/managed/ublock_extension.json

RUN chown root:root /etc/opt/chrome/policies/managed && \
    chown root:root /etc/opt/chrome/policies/managed/ublock_extension.json && \
    chmod 755 /etc/opt/chrome/policies/managed && \
    chmod 644 /etc/opt/chrome/policies/managed/ublock_extension.json

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
