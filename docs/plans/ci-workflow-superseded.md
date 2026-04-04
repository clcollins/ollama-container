# CI Workflow (Superseded)

> **SUPERSEDED**: This plan was replaced by [Container-Based CI](container-based-ci.md),
> which runs all checks inside a dedicated CI container for local/remote parity.

## Original Proposal

Add `.github/workflows/ci.yaml` with 8 independent GHA jobs, each installing
tools directly on the `ubuntu-latest` runner:

1. yaml-lint (yamllint via pip)
2. markdown-lint (markdownlint-cli2 via npx)
3. makefile-lint (checkmake via go install)
4. containerfile-check (bash script)
5. image-build (podman build + OCI label validation)
6. kubernetes-manifests (kubeconform)
7. python-lint (ruff via pip)
8. docs-check (find)

## Why It Was Superseded

- Tools installed ad-hoc on the runner create environment drift between
  local development and CI (e.g., ruff not installed locally, different
  tool versions)
- No way to reproduce CI checks locally without installing every tool
- Violates the project's containerization philosophy
