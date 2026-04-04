# Claude Code Configuration

## Repository Standards

This repository must conform to [CONVENTIONS.md](CONVENTIONS.md). When making
changes, review CONVENTIONS.md first and ensure all modifications align with
the documented standards.

## CI

- Run `make ci-all` before proposing changes to verify all checks pass
- All CI checks run inside the CI container (`test/Containerfile.ci`)
- Do not install tools on the host — if a tool is needed for CI, add it to
  the CI container

## Plan Documents

- Every non-trivial change requires a plan document in `docs/plans/`
- Review existing plan documents for lessons learned before starting new work
- Use descriptive filenames, not numeric prefixes

## Container Engine

- Use `podman`, not `docker`
- Use `Containerfile`, not `Dockerfile`
- Use `.containerignore`, not `.dockerignore`
