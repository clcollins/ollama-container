# ollama-container

> ⚠️ This README was partially generated using AI tools, which were also used in the development of this project.

## Overview

This repository provides a containerized setup for running [Ollama](https://ollama.com/) — an open-source AI language model runtime — in a Podman-managed environment using `podman kube play`. It includes a `Makefile` for building and managing the container image and configuration files for deploying with Kubernetes-compatible YAML.

## Features

- Run Ollama in a local container with Podman
- Use `podman kube play` to launch the environment with Kubernetes-style manifests
- Define your own custom LLM model logic via a `Modelfile` specified in a ConfigMap
- Interact with Ollama locally using a simple CLI interface or via API

## Prerequisites

- [Podman](https://podman.io/)
- [make](https://www.gnu.org/software/make/)
- An internet connection (for downloading base models)

## Build the Image

To build the container image for Ollama using the provided `Makefile`, simply run:

```bash
make build
```

This builds the image defined in the Makefile and tags it as `localhost/ollama`.

## Deploy the Environment with Podman

Start the containerized Ollama environment using the Kubernetes-compatible YAML:

```bash
podman kube play ollama.yaml
```

This will:

- Create a Pod running the Ollama container
- Mount a `Modelfile` from a ConfigMap
- Set up the necessary volumes for model storage and logs

## Downloading a model

On first run, Ollama will need to retrieve a model to use.  You can retrieve a model with the `ollama pull` command inside the ollama-cli container:

```bash
# eg: pull the latest granite3.3 model
podman exec -it ollama pull granite3.3:latest
```

### Customizing the Modelfile

A sample `Modelfile` used by Ollama to define the model behavior is mounted as a [ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/) in the container, and specified in the `ollama.yaml`. You can customize the model and system prompt by editing the `Modelfile` section in that file.

To initialize a new model using a custom `Modelfile`, run:

```bash
podman exec -it ollama create model -f Modelfile
```

This will load the model defined in the `Modelfile` on first startup.  If you have already started the pod, you can restart it to update the `Modelfile`. Run:

```bash
podman kube play --replace ollama.yaml
```

## Interacting with Ollama via the terminal

Once the pod is running, you can interact with the Ollama LLM using:

```bash
podman exec -it ollama-cli ollama run model "<your query here>"
```

Replace `<your query here>` with your prompt or question.

### Example

```bash
podman exec -it ollama-cli ollama run model "What is your Quest?"
```

## Creating an Alias for Ollama

You can create an shell alias for Ollama to have it perform as it would in a normal un-containerized installation. Add it to your `~/.bashrc` for persistence.

```bash
alias ollama='podman exec -it ollama-cli ollama'
```

### Example

```bash
ollama run model "What is your Quest?"
```

## Interacting with Ollama via the API

The Ollama API is available to other containers or pods, or your local machine, via localhost on the standard Ollama port `11434`. Use the `--publish` flag with `podman kube play` to open the publish (open) the port to the container.

The `examples/ask.py` script is an example connecting to Ollama on `localhost:11434`, and behaves as any other Ollama installation would.

## Acknowledgments

- [Ollama](https://ollama.com/)
- [Podman](https://podman.io/)
