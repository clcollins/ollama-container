# This is intended to be built into an image for use with Fedora Toolbox
# and run with `toolbox create --image NAME`. This allows podman on the
# host to be used from within the toolbox via the flatpak-spawn command.

FROM registry.fedoraproject.org/fedora-toolbox:42
LABEL author "Chris Collins <collins.christopher@gmail.com>"

LABEL com.github.containers.toolbox="true"

ARG GIT_HASH
LABEL toolbox-ollama-version=${GIT_HASH}

ENV OLLAMA_PORT 11434

RUN curl -L https://ollama.com/download/ollama-linux-amd64.tgz -o ollama-linux-amd64.tgz
RUN tar -C /usr -xzf ollama-linux-amd64.tgz

RUN ollama  --help

EXPOSE 11434

# ENTRYPOINT and CMD are set by toolbox for an interactive shell

