FROM registry.fedoraproject.org/fedora-minimal:42 as DNF

RUN dnf install --assumeyes tar gzip \
  && dnf clean all \
  && rm -rf /var/yum/cache

FROM DNF
LABEL author "Chris Collins <collins.christopher@gmail.com>"

LABEL com.github.containers.toolbox="true"

ARG GIT_HASH
LABEL toolbox-ollama-version ${GIT_HASH}

ENV OLLAMA_PORT 11434
ENV OLLAMA_HOST 0.0.0.0:11434

RUN curl -L https://ollama.com/download/ollama-linux-amd64.tgz -o ollama-linux-amd64.tgz
RUN tar -C /usr -xzf ollama-linux-amd64.tgz

RUN mkdir -p /home/ollama
RUN chmod -R 777 /home/ollama

WORKDIR /home/ollama

RUN ollama --help

EXPOSE 11434

