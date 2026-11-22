ARG BASE_TAG="1.19.0"
ARG BASE_IMAGE="core-ubuntu-noble"
ARG BASE_REGISTRY="rd-harbor-secops.servicemicro.net/infra/kasmweb"
FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG}

USER root

ENV HOME=/home/kasm-default-profile
ENV STARTUPDIR=/dockerstartup
WORKDIR $HOME

# Environment config
ENV DEBIAN_FRONTEND=noninteractive \
    SKIP_CLEAN=true \
    KASM_RX_HOME=$STARTUPDIR/kasmrx \
    DONT_PROMPT_WSL_INSTALL="No_Prompt_please" \
    SAL_USE_VCLPLUGIN=gtk3 \
    SAL_DISABLE_OPENCL=1 \
    INST_DIR=$STARTUPDIR/install \
    INST_SCRIPTS="/ubuntu/install/cli-tools/install_cli_tools.sh \
                  /ubuntu/install/git-bash/install_git_bash.sh \
                  /ubuntu/install/chrome/install_chrome.sh \
                  /ubuntu/install/firefox/install_firefox.sh \
                  /ubuntu/install/edge/install_edge.sh \
                  /ubuntu/install/k8s-tools/install_k8s_tools.sh \
                  /ubuntu/install/cloudmonkey/install_cloudmonkey.sh \
                  /ubuntu/install/vscode/install_vscode.sh \
                  /ubuntu/install/sublime/install_sublime.sh \
                  /ubuntu/install/bruno/install_bruno.sh \
                  /ubuntu/install/wireshark/install_wireshark.sh \
                  /ubuntu/install/burp-suite/install_burp_suite.sh \
                  /ubuntu/install/drawio/install_drawio.sh \
                  /ubuntu/install/bcompare/install_bcompare.sh \
                  /ubuntu/install/headlamp/install_headlamp.sh \
                  /ubuntu/install/onlyoffice/install_onlyoffice.sh \
                  /ubuntu/install/rdm/install_rdm.sh \
                  /ubuntu/install/veracrypt/install_veracrypt.sh \
                  /ubuntu/install/keepassxc/install_keepassxc.sh \
                  /ubuntu/install/flameshot/install_flameshot.sh \
                  /ubuntu/install/typora/install_typora.sh \
                  /ubuntu/install/kleopatra/install_kleopatra.sh \
                  /ubuntu/install/nextcloud/install_nextcloud.sh \
                  /ubuntu/install/xmind8/install_xmind8.sh \
                  /ubuntu/install/openvpn3/install_openvpn3.sh \
                  /ubuntu/install/cleanup/cleanup.sh"

# Copy install scripts
COPY images/ubuntu/scripts/ $INST_DIR/ubuntu/install/

# Single consolidated layer: configure APT, run all install scripts, configure sdwf-user & cleanup
RUN rm -rf /var/lib/apt/lists/* && \
    printf 'APT::Architectures { "amd64"; };\n' > /etc/apt/apt.conf.d/99architecture && \
    groupadd -f -r wireshark && \
    mkdir -p /home/sdwf-user && \
    for SCRIPT in $INST_SCRIPTS; do \
      bash ${INST_DIR}${SCRIPT} || exit 1; \
    done && \
    $STARTUPDIR/set_user_permission.sh $HOME && \
    rm -f /etc/X11/xinit/Xclients && \
    chown -R 1000:0 $HOME && \
    cp -a $HOME/. /home/sdwf-user/ && \
    chown -R 1000:0 /home/sdwf-user && \
    rm -rf ${INST_DIR} /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Userspace Runtime (sdwf-user / UID 1000)
ENV HOME=/home/sdwf-user
WORKDIR $HOME
USER 1000

CMD ["--tail-log"]