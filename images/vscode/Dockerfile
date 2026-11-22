# VS Code workspace. Base manifest is pinned by the existing Makefile.
ARG BASE_IMAGE="kasmweb/vs-code:1.19.0@sha256:a54b3d145cb4fb672e799f4db3d5f6f7c0cb604254acc001084b2a10fc09d2f6"
FROM ${BASE_IMAGE}

ARG EXTENSION_MODE=locked
USER root
ENV HOME=/home/sdwf-user \
    VSCODE_EXTENSIONS=/opt/dwf-vscode/extensions \
    EXTENSIONS_MANIFEST=/opt/dwf-vscode/extensions.txt \
    EXTENSIONS_LOCK=/opt/dwf-vscode/extensions.lock \
    GENERATED_LOCK=/opt/dwf-vscode/extensions.lock.generated

COPY --chown=1000:0 images/vscode/configs/extensions.txt images/vscode/configs/extensions.lock /opt/dwf-vscode/
COPY --chown=1000:0 images/vscode/scripts/install-extensions.sh images/vscode/validate/verify-extensions.sh /opt/dwf-vscode/
RUN mkdir -p /home/sdwf-user/.vscode /opt/dwf-vscode/extensions && \
    chown -R 1000:0 /home/sdwf-user /opt/dwf-vscode && \
    chmod 0755 /opt/dwf-vscode/*.sh && \
    ln -sfn /opt/dwf-vscode/extensions /home/sdwf-user/.vscode/extensions

USER 1000
WORKDIR /home/sdwf-user
RUN EXTENSION_MODE="${EXTENSION_MODE}" /opt/dwf-vscode/install-extensions.sh
CMD ["--tail-log"]
