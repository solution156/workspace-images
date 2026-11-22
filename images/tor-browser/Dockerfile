ARG BASE_TAG="1.19.0"
ARG BASE_IMAGE="core-ubuntu-noble"
ARG BASE_REGISTRY="rd-harbor-secops.servicemicro.net/infra/kasmweb"

FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG}

# "latest" = tự lấy bản stable mới nhất từ torproject.org.
# Nên ghim phiên bản cụ thể (vd: --build-arg TOR_VERSION=15.0.3) để build tái lập được.
ARG TOR_VERSION="16.0.1"
ENV TOR_VERSION=${TOR_VERSION}

# uBlock Origin Lite (bản Firefox/AMO). Có thể ghi đè nếu slug thay đổi.
ARG UBOL_XPI_URL="https://addons.mozilla.org/firefox/downloads/latest/ublock-origin-lite/latest.xpi"
ENV UBOL_XPI_URL=${UBOL_XPI_URL}

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
    INST_SCRIPTS="/ubuntu/install/torbrowser/install_torbrowser.sh \
                  /ubuntu/install/cleanup/cleanup.sh"

# Copy installation scripts
COPY images/tor-browser/scripts/install_torbrowser.sh $INST_DIR/ubuntu/install/torbrowser/install_torbrowser.sh
COPY images/tor-browser/scripts/cleanup.sh $INST_DIR/ubuntu/install/cleanup/cleanup.sh
COPY images/tor-browser/configs/policies.json $INST_DIR/policies.json

# Restrict APT index downloads to amd64
RUN rm -rf /var/lib/apt/lists/* && \
    printf 'APT::Architectures { "amd64"; };\n' \
      > /etc/apt/apt.conf.d/99architecture

# Install Tor Browser + uBlock Origin Lite + policies
RUN for SCRIPT in $INST_SCRIPTS; do \
      bash ${INST_DIR}${SCRIPT} || exit 1; \
    done

# Configure XFCE for Single Application
RUN cp $HOME/.config/xfce4/xfconf/single-application-xfce-perchannel-xml/* \
       $HOME/.config/xfce4/xfconf/xfce-perchannel-xml/ && \
    apt-get remove -y xfce4-panel

# Copy Tor Browser startup script
COPY images/tor-browser/scripts/custom_startup.sh $STARTUPDIR/custom_startup.sh

RUN chmod 755 $STARTUPDIR/custom_startup.sh

# Set startup command and process monitor
ENV START_COMMAND="$STARTUPDIR/custom_startup.sh"
ENV PGREP="firefox"

# Set permissions
RUN $STARTUPDIR/set_user_permission.sh $HOME && \
    rm -f /etc/X11/xinit/Xclients && \
    chown 1000:0 $HOME && \
    mkdir -p /home/kasm-user && \
    chown -R 1000:0 /home/kasm-user && \
    rm -rf ${INST_DIR}

RUN rm -rf /home/kasm-default-profile/Downloads && \
    rm -f /home/kasm-default-profile/Desktop/Downloads

# Userspace Runtime
ENV HOME=/home/kasm-user

WORKDIR $HOME

USER 1000

CMD ["--tail-log"]