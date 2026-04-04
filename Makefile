ifneq (,$(wildcard ./.env))
  include .env
  export
endif

REGISTRY_NAME ?= ""
ORG_NAME ?= ""
AUTHFILE ?= "${HOME}/.config/quay.io/bot_auth.json"

IMAGE_NAME = "ollama"
GIT_HASH := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")

TAG := ${REGISTRY_NAME}/${ORG_NAME}/${IMAGE_NAME}:${GIT_HASH}
TAG_LATEST := ${REGISTRY_NAME}/${ORG_NAME}/${IMAGE_NAME}:latest

CONTAINER_SUBSYS ?= "podman"

BUILD_ARGS ?= "--build-arg=GIT_HASH=${GIT_HASH}"
CACHE ?= "--no-cache"

ALLOW_DIRTY_CHECKOUT?=false

CI_IMAGE = "ollama-ci"

.PHONY: default
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
	@(test -n $(REGISTRY_NAME) && test -n $(ORG_NAME)) || (echo "REGISTRY_NAME or ORG_NAME not set" >&2 && exit 1)
	${CONTAINER_SUBSYS} tag ${IMAGE_NAME} ${TAG}
	${CONTAINER_SUBSYS} tag ${IMAGE_NAME} ${TAG_LATEST}

.PHONY: push
push:
	${CONTAINER_SUBSYS} push ${TAG} --authfile=${AUTHFILE}
	${CONTAINER_SUBSYS} push ${TAG_LATEST} --authfile=${AUTHFILE}

# CI targets — all checks run inside the CI container

.PHONY: ci-build
ci-build:
	${CONTAINER_SUBSYS} build -f test/Containerfile.ci -t ${CI_IMAGE} test/

.PHONY: ci-all
ci-all: ci-build
	${CONTAINER_SUBSYS} run --rm -v $$(pwd):/work:Z ${CI_IMAGE} make ci-checks

.PHONY: ci-checks
ci-checks: yaml-lint markdown-lint makefile-lint containerfile-check kubernetes-validate python-lint shellcheck-lint docs-check

.PHONY: yaml-lint
yaml-lint:
	yamllint .

.PHONY: markdown-lint
markdown-lint:
	npx markdownlint-cli2 "**/*.md" "#node_modules"

.PHONY: makefile-lint
makefile-lint:
	checkmake Makefile

.PHONY: containerfile-check
containerfile-check:
	ENFORCE=1 bash test/scripts/check-containerfile-tags.sh Containerfile

.PHONY: kubernetes-validate
kubernetes-validate:
	kubeconform -summary -strict deploy/
	kubeconform -summary -strict ollama.yaml

.PHONY: python-lint
python-lint:
	ruff check examples/
	ruff format --check examples/

.PHONY: shellcheck-lint
shellcheck-lint:
	shellcheck test/scripts/*.sh

.PHONY: docs-check
docs-check:
	@test $$(find docs/plans -name '*.md' 2>/dev/null | wc -l) -gt 0 \
		|| (echo "ERROR: No plan documents found in docs/plans/" && exit 1)
	@echo "Plan documents found in docs/plans/"

.PHONY: test
test: ci-all

.PHONY: clean
clean:
	${CONTAINER_SUBSYS} rmi -f ${CI_IMAGE} 2>/dev/null || true
	${CONTAINER_SUBSYS} rmi -f ${IMAGE_NAME} 2>/dev/null || true
