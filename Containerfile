FROM registry.fedoraproject.org/fedora-minimal:42 as deps

RUN dnf install --assumeyes tar zstd \
  && dnf clean all \
  && rm -rf /var/yum/cache

FROM deps
LABEL author "Chris Collins <collins.christopher@gmail.com>"

LABEL com.github.containers.toolbox="true"

ARG GIT_HASH
LABEL toolbox-ollama-version ${GIT_HASH}

ENV OLLAMA_PORT 11434
ENV OLLAMA_HOST 0.0.0.0:11434

RUN mkdir -p /home/ollama
RUN chmod -R 777 /home/ollama

RUN arch="$(uname -m)" \
  && case "$arch" in \
       x86_64) target_arch="amd64" ;; \
       aarch64|arm64) target_arch="arm64" ;; \
       *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
     esac \
  && curl -sSL "https://ollama.com/download/ollama-linux-${target_arch}.tar.zst" -o- | tar -C /usr --zstd -xv

WORKDIR /home/ollama

RUN ollama --help

EXPOSE 11434

