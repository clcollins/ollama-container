# ollama-container

> ⚠️ This README was partially generated using AI tools, which were also used in the development of this project.

## Overview

This repository provides a containerized setup for running [Ollama](https://ollama.com/) — an open-source AI language model runtime — in a Podman-managed environment using `podman kube play`. It includes a `Makefile` for building and managing the container image, configuration files for deploying with Kubernetes-compatible YAML, and Kubernetes manifests for cluster deployment.

## Features

- Run Ollama in a local container with Podman
- Use `podman kube play` to launch the environment with Kubernetes-style manifests
- Deploy to a Kubernetes cluster using the manifests in `deploy/`
- Define your own custom LLM model logic via a `Modelfile` specified in a ConfigMap
- Configurable resource limits to prevent CPU and memory overconsumption
- Health probes for automatic restart of unhealthy containers
- Interact with Ollama locally using a simple CLI interface or via API

## Prerequisites

- [Podman](https://podman.io/) (for local deployment)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (for Kubernetes cluster deployment)
- [make](https://www.gnu.org/software/make/)
- An internet connection (for downloading base models)

## Model Selection

The default model is `llama3.1` (8B parameters), configured in the `Modelfile` ConfigMap. You can change the model by editing the `FROM` line in the ConfigMap in `ollama.yaml` (for Podman) or `deploy/ollama-modelfile.ConfigMap.yaml` (for Kubernetes).

### Model Sizing Guide

Adjust resource limits in the pod/deployment manifest to match your chosen model:

| Model | Parameters | RAM Required | CPU Recommended | PVC Size |
|-------|-----------|-------------|-----------------|----------|
| llama3.2 | 3B | ~4Gi | 4 cores | 5Gi |
| llama3.1 | 8B | ~8Gi | 4 cores | 10Gi |
| qwen2.5 | 7B | ~8Gi | 4 cores | 10Gi |
| llama3.1:70b | 70B | ~48Gi | 16 cores | 50Gi |
| llama3.3 | 70B | ~48Gi | 16 cores | 50Gi |

## Build the Image

To build the container image for Ollama using the provided `Makefile`, simply run:

```bash
make build
```

This builds the image defined in the Makefile and tags it as `localhost/ollama`.

To build for a different architecture (e.g., ARM):

```bash
podman build --platform linux/arm64 -t localhost/ollama .
```

## Deploy with Podman (Local)

Start the containerized Ollama environment using the Kubernetes-compatible YAML:

```bash
podman kube play ollama.yaml
```

This will:

- Create a Pod running the Ollama container
- Mount a `Modelfile` from a ConfigMap
- Set up the necessary volume for model storage
- Apply resource limits (CPU and memory) to prevent overconsumption
- Configure health probes to automatically restart unhealthy containers

## Deploy to a Kubernetes Cluster

The `deploy/` directory contains standalone Kubernetes manifests following one-resource-per-file conventions:

```
deploy/
  ollama.Namespace.yaml
  ollama.PersistentVolumeClaim.yaml
  ollama-modelfile.ConfigMap.yaml
  ollama.Deployment.yaml
  ollama.Service.yaml
```

Apply the Namespace first, then the remaining resources:

```bash
kubectl apply -f deploy/ollama.Namespace.yaml
kubectl apply -f deploy/
```

This creates:
- A dedicated `ollama` namespace
- A PersistentVolumeClaim using the cluster's default storage class
- A ConfigMap with the Modelfile
- A Deployment with resource limits and health probes
- A ClusterIP Service on port 11434

The Ollama API will be available within the cluster at `ollama.ollama.svc.cluster.local:11434`.

## Downloading a model

On first run, Ollama will need to retrieve a model to use. You can retrieve a model with the `ollama pull` command inside the cli container:

```bash
# For Podman:
podman exec -it ollama-cli ollama pull llama3.1:latest

# For Kubernetes:
kubectl exec -it -n ollama deployment/ollama -c cli -- ollama pull llama3.1:latest
```

### Customizing the Modelfile

A sample `Modelfile` used by Ollama to define the model behavior is mounted as a [ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/) in the container, and specified in the `ollama.yaml`. You can customize the model and system prompt by editing the `Modelfile` section in that file.

To initialize a new model using a custom `Modelfile`, run:

```bash
# For Podman:
podman exec -it ollama-cli ollama create model -f Modelfile

# For Kubernetes:
kubectl exec -it -n ollama deployment/ollama -c cli -- ollama create model -f Modelfile
```

This will load the model defined in the `Modelfile` on first startup. If you have already started the pod, you can restart it to update the `Modelfile`. Run:

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

The Ollama API is available to other containers or pods, or your local machine, via localhost on the standard Ollama port `11434`. Use the `--publish` flag with `podman kube play` to publish (open) the port from the container to your host.

```bash
podman kube play --publish 127.0.0.1:11434:11434/tcp --replace ollama.yaml
```

The `examples/ask.py` script is an example connecting to Ollama on `localhost:11434`, and behaves as any other Ollama installation would. You can configure the host and model name via environment variables:

```bash
OLLAMA_HOST=http://localhost:11434 OLLAMA_MODEL=model python3 examples/ask.py
```

## Resource Limits

Both containers in the pod have CPU and memory limits configured to prevent overconsumption:

- **serve** (Ollama server): 8 CPU cores / 12Gi memory limit (tuned for 8B models)
- **cli** (interactive shell): 1 CPU core / 512Mi memory limit

When switching to larger models (e.g., 70B), update the resource limits in the manifest accordingly. See the [Model Sizing Guide](#model-sizing-guide) above.

## Acknowledgments

- [Ollama](https://ollama.com/)
- [Podman](https://podman.io/)
