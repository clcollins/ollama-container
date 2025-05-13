REGISTRY_NAME := "quay.io"
ORG_NAME := "chcollin"
AUTHFILE := "${HOME}/.config/quay.io/bot_auth.json"

IMAGE_NAME = "toolbox-ollama"
GIT_HASH := $(shell git rev-parse --short HEAD)

TAG := ${REGISTRY_NAME}/${ORG_NAME}/${IMAGE_NAME}:${GIT_HASH}
TAG_LATEST := ${REGISTRY_NAME}/${ORG_NAME}/${IMAGE_NAME}:latest

CONTAINER_SUBSYS?="podman"

BUILD_ARGS ?= "--build-arg=GIT_HASH=${GIT_HASH}"
CACHE ?= "--no-cache"

ALLOW_DIRTY_CHECKOUT?=false

default: all

.PHONY: all
all: isclean build tag

.PHONY: isclean
isclean:
	(test "$(ALLOW_DIRTY_CHECKOUT)" == "true" || test 0 -eq $$(git status --porcelain | wc -l)) || (echo "Local git checkout is not clean, commit changes and try again." >&2 && git --no-pager diff && exit 1)

.PHONY: build
build: 
	${CONTAINER_SUBSYS} build ${CACHE} ${BUILD_ARGS} -t ${IMAGE_NAME} .

.PHONY: tag
tag: 
	${CONTAINER_SUBSYS} tag ${IMAGE_NAME} ${IMAGE_NAME}:${GIT_HASH}
	${CONTAINER_SUBSYS} tag ${IMAGE_NAME} ${TAG}
	${CONTAINER_SUBSYS} tag ${IMAGE_NAME} ${TAG_LATEST}

.PHONY: push
push:
	${CONTAINER_SUBSYS} push ${TAG} --authfile=${AUTHFILE}
	${CONTAINER_SUBSYS} push ${TAG_LATEST} --authfile=${AUTHFILE}

.PHONY: cleanup-bootstrap
cleanup-bootstrap:
	${CONTAINER_SUBSYS} stop bootstrap
	${CONTAINER_SUBSYS} rm bootstrap

.PHONY: toolbox
toolbox:
	toolbox create --image ${TAG} ${IMAGE_NAME}

.PHONY: cleanup-toolbox
cleanup-toolbox:
	toolbox rm --force ${IMAGE_NAME}
