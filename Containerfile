# This is intended to be built into an image for use with Fedora Toolbox
# and run with `toolbox create --image NAME`. This allows podman on the
# host to be used from within the toolbox via the flatpak-spawn command.

FROM registry.fedoraproject.org/fedora-toolbox:40
LABEL author "Chris Collins <collins.christopher@gmail.com>"

ARG GIT_HASH
LABEL toolbox-ollama-version=${GIT_HASH}

RUN curl -L https://ollama.com/download/ollama-linux-amd64-rocm.tgz -o ollama-linux-amd64-rocm.tgz
RUN tar -C /usr -xzf ollama-linux-amd64-rocm.tgz

RUN ollama --help


