# Image Build & Push: Add PR Trigger

## Context

The `image-build-push.yaml` workflow only triggered on pushes to main and
version tags. This meant container image builds were never validated on PRs —
a broken Containerfile would only be caught after merging.

## Changes

- Added `pull_request` to the workflow trigger
- Build steps run on all events (push, tag, PR)
- Login and push steps are skipped on PRs via `if: github.event_name != 'pull_request'`
- PR builds get a `pr-<number>` tag for local identification

## Verification

1. Open a PR — both multi-arch builds should run without pushing
2. Merge to main — builds run and push to Quay.io as before
3. Tag a release — builds run and push with version tag as before
