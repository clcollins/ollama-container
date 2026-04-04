# Image Build & Push: Add PR Trigger

## Context

The `image-build-push.yaml` workflow only triggered on pushes to main and
version tags. This meant container image builds were never validated on PRs —
a broken Containerfile would only be caught after merging.

## Changes

- Added `pull_request` to the workflow trigger
- PR builds use a local-only image name (`ollama`) instead of the registry
  path, avoiding dependency on `QUAY_REPOSITORY` secret (which is unavailable
  on fork PRs)
- PR builds are tagged with both `pr-<number>` and short SHA for identification
- Login and push steps are skipped on PRs via `if: github.event_name != 'pull_request'`
- Non-PR builds (main push, tags) continue to use the full registry path and
  push to Quay.io as before

## Verification

1. Open a PR — both multi-arch builds should run without pushing
2. Merge to main — builds run and push to Quay.io as before
3. Tag a release — builds run and push with version tag as before
