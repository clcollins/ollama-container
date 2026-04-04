# Plan 004: GitHub Actions Workflow for Container Image Builds

> Retroactive plan document for PR #4, created after merge.

## Context

The project had a `Makefile` for local container image builds but no automated CI/CD pipeline. Images had to be built and pushed to Quay.io manually. A GitHub Actions workflow was needed to automate multi-architecture container image builds on every push to `main` and on version tags.

## What Was Implemented (PR #4)

PR #4 added `.github/workflows/image-build-push.yaml` — a GitHub Actions workflow that:

- **Triggers** on pushes to `main` branch and version tags (`v*`)
- **Builds** container images for `linux/amd64` and `linux/arm64` using `podman build` with QEMU for cross-platform support
- **Tags** images with:
  - Short commit SHA (always)
  - Semantic version with `v` prefix stripped (for version tags)
  - `latest` (for main branch pushes)
- **Pushes** multi-architecture manifests to Quay.io using `podman manifest`
- **Authenticates** via `QUAY_REPOSITORY`, `QUAY_ROBOT_USERNAME`, and `QUAY_ROBOT_TOKEN` GitHub secrets

The workflow was modeled after the `clcollins/dwarfbot` image-build-push workflow.

### Files Changed

- `.github/workflows/image-build-push.yaml` (added, 84 lines)

## What Happened

PR #4 merged on 2026-04-03 (commit `ddf9ad7`), which triggered the new workflow on the `main` branch (run [23966484837](https://github.com/clcollins/ollama-container/actions/runs/23966484837)).

**The workflow failed at the "Build linux/amd64 image" step** with:

```
gzip: stdin: not in gzip format
tar: Child returned status 1
tar: Error is not recoverable: exiting now
Error: building at STEP "RUN arch="$(uname -m)" ...": while running runtime: exit status 2
```

### Root Cause

The failure was **not in the workflow itself** but in the `Containerfile`. The Containerfile downloads the Ollama binary via:

```bash
curl -sSL "https://ollama.com/download/ollama-linux-${target_arch}.tgz" -o- | tar -C /usr -xzv
```

**Ollama v0.20.0 changed their Linux release artifact format from `.tgz` (gzip-compressed tar) to `.tar.zst` (zstd-compressed tar).** The old `.tgz` URLs now return HTTP 404 with a 9-byte "Not Found" ASCII body, which gets piped into `tar -xzv`, causing the gzip format error.

This was a pre-existing issue in the Containerfile that also affects local `make build`. The workflow correctly built and invoked `podman build` — it faithfully reproduced the same failure that would occur locally.

## Lessons Learned

### 1. Validate end-to-end builds before merging CI workflows

The workflow was developed and reviewed in isolation without running `podman build .` or `make build` to confirm the Containerfile actually builds. A single local build attempt would have caught the download failure before the PR was merged.

**Recommendation**: When adding CI that builds container images, always do a local build as part of pre-merge validation.

### 2. External download URLs are fragile

Upstream projects can change distribution formats, URLs, or hosting without notice. The Ollama project moved from `.tgz` to `.tar.zst` in v0.20.0, breaking all downstream consumers that relied on the `.tgz` URL.

**Recommendation**: Pin to a specific release version URL when possible, or add a verification step that checks the download succeeded before proceeding.

### 3. Piping `curl` directly to `tar` masks failures

The pattern `curl -sSL <url> -o- | tar -xzv` is concise but dangerous:
- `-sS` suppresses progress but shows errors — however, HTTP 404 responses are not curl errors when following redirects
- The pipe means `tar` receives whatever `curl` outputs, even if it's an HTML error page or "Not Found" text
- The exit code of the pipeline is the exit code of `tar`, not `curl`

**Safer alternatives**:
- Download to a temp file first, verify it, then extract
- Use `set -o pipefail` in the shell so the pipeline fails if `curl` fails
- Check the downloaded content-type or file magic before extraction

### 4. Plan documents should precede implementation

This PR was merged without a plan document. A plan document would have prompted review of the Containerfile's download mechanism and potentially surfaced the `.tgz` deprecation risk during the design phase.
