ARG BASE_TAG="1.19.0"
ARG BASE_IMAGE="core-ubuntu-noble"
ARG BASE_REGISTRY="rd-harbor-secops.servicemicro.net/infra/kasmweb"

FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG}

# Ghim phiên bản Opera để build tái lập được. Để trống = lấy bản mới nhất trong repo.
ARG OPERA_VERSION="140.0.6074.18"
ARG OPERA_DEB_SHA256="e6bd67b26a572a7bf72d0a6f4f1bfc418ef7767a9f448760007b71da96d50b0f"
ENV OPERA_VERSION=${OPERA_VERSION} \
    OPERA_DEB_SHA256=${OPERA_DEB_SHA256}

USER root

ENV HOME=/home/kasm-default-profile
ENV STARTUPDIR=/dockerstartup

WORKDIR $HOME

ENV DEBIAN_FRONTEND=noninteractive \
    SKIP_CLEAN=true \
    KASM_RX_HOME=$STARTUPDIR/kasmrx \
    DONT_PROMPT_WSL_INSTALL="No_Prompt_please" \
    INST_DIR=$STARTUPDIR/install \
    INST_SCRIPTS="/ubuntu/install/opera/install_opera.sh \
                  /ubuntu/install/cleanup/cleanup.sh"

COPY images/opera-browser/scripts/install_opera.sh $INST_DIR/ubuntu/install/opera/install_opera.sh
COPY shared/browser/cleanup.sh $INST_DIR/ubuntu/install/cleanup/cleanup.sh
COPY images/opera-browser/configs/policies.json $INST_DIR/policies.json

RUN rm -rf /var/lib/apt/lists/* && \
    printf 'APT::Architectures { "amd64"; };\n' \
      > /etc/apt/apt.conf.d/99architecture

RUN for SCRIPT in $INST_SCRIPTS; do \
      bash ${INST_DIR}${SCRIPT} || exit 1; \
    done

# Giống Tor: bỏ panel XFCE để chỉ còn một cửa sổ app
RUN cp $HOME/.config/xfce4/xfconf/single-application-xfce-perchannel-xml/* \
       $HOME/.config/xfce4/xfconf/xfce-perchannel-xml/ && \
    apt-get remove -y xfce4-panel

COPY images/opera-browser/scripts/custom_startup.sh $STARTUPDIR/custom_startup.sh
RUN chmod 755 $STARTUPDIR/custom_startup.sh

ENV START_COMMAND="$STARTUPDIR/custom_startup.sh"
ENV PGREP="opera/opera"

RUN $STARTUPDIR/set_user_permission.sh $HOME && \
    rm -f /etc/X11/xinit/Xclients && \
    chown 1000:0 $HOME && \
    mkdir -p /home/kasm-user && \
    chown -R 1000:0 /home/kasm-user && \
    rm -rf ${INST_DIR}

ENV HOME=/home/kasm-user
WORKDIR $HOME

USER 1000

CMD ["--tail-log"]