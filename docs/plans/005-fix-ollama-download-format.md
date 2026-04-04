# Plan 005: Fix Ollama Download Format (.tgz -> .tar.zst)

## Context

Ollama v0.20.0 changed the Linux release artifact format from `.tgz` (gzip) to `.tar.zst` (zstd). The Containerfile's download step uses the old `.tgz` URL, which now returns HTTP 404 "Not Found". This breaks both local `make build` and the GitHub Actions workflow (PR #4, run 23966484837).

See [Plan 004](004-github-actions-container-builds.md) for full incident details and lessons learned.

## Changes

### `Containerfile`

**deps stage** — Replace `gzip` with `zstd` in package install:
```diff
-RUN dnf install --assumeyes tar gzip \
+RUN dnf install --assumeyes tar zstd \
```

**Download step** — Update URL extension and tar decompression flag:
```diff
-  && curl -sSL "https://ollama.com/download/ollama-linux-${target_arch}.tgz" -o- | tar -C /usr -xzv
+  && curl -sSL "https://ollama.com/download/ollama-linux-${target_arch}.tar.zst" -o- | tar -C /usr --zstd -xv
```

No changes needed to the GitHub Actions workflow or Makefile.

## Verification

1. Run `make build` locally — image should build successfully
2. The existing `RUN ollama --help` step in the Containerfile validates the binary was extracted correctly
3. After merge, confirm the GitHub Actions workflow passes on `main`
