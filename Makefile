ifneq (,$(wildcard ./.env))
  include .env
  export
endif

REGISTRY_NAME ?= ""
ORG_NAME ?= ""
AUTHFILE ?= "${HOME}/.config/quay.io/bot_auth.json"

IMAGE_NAME = "ollama"
GIT_HASH := $(shell git rev-parse --short HEAD)

TAG := ${REGISTRY_NAME}/${ORG_NAME}/${IMAGE_NAME}:${GIT_HASH}
TAG_LATEST := ${REGISTRY_NAME}/${ORG_NAME}/${IMAGE_NAME}:latest

CONTAINER_SUBSYS ?= "podman"

BUILD_ARGS ?= "--build-arg=GIT_HASH=${GIT_HASH}"
CACHE ?= "--no-cache"

ALLOW_DIRTY_CHECKOUT?=false

default: all

.PHONY: all
all: isclean build tag

.PHONY: env
env:
	@echo REGISTRY_NAME=${REGISTRY_NAME}
	@echo ORG_NAME=${ORG_NAME}

.PHONY: isclean
isclean:
	@(test "$(ALLOW_DIRTY_CHECKOUT)" == "true" || test 0 -eq $$(git status --porcelain | wc -l)) || (git --no-pager diff && echo "Local git checkout is not clean, commit changes and try again." >&2 && exit 1)

.PHONY: build
build: 
	${CONTAINER_SUBSYS} build ${CACHE} ${BUILD_ARGS} -t ${IMAGE_NAME} .
	${CONTAINER_SUBSYS} tag ${IMAGE_NAME} ${IMAGE_NAME}:${GIT_HASH}

.PHONY: tag
tag: 
	@(test -n $(REGISTRY_NAME) && test -n $(ORG_NAME)) || (echo "REGISTRY_NAME or ORG_NAME not set >&2" && exit 1)
	${CONTAINER_SUBSYS} tag ${IMAGE_NAME} ${TAG}
	${CONTAINER_SUBSYS} tag ${IMAGE_NAME} ${TAG_LATEST}

.PHONY: push
push:
	${CONTAINER_SUBSYS} push ${TAG} --authfile=${AUTHFILE}
	${CONTAINER_SUBSYS} push ${TAG_LATEST} --authfile=${AUTHFILE}
