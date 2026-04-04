# Container-Based CI

## Context

The repo had no CI validation. An initial plan (see
[ci-workflow-superseded.md](ci-workflow-superseded.md)) proposed running checks
directly on the GHA runner, installing tools ad-hoc. This was rejected because:

- Tools installed ad-hoc on the runner create environment drift (e.g., ruff not
  installed locally, different markdownlint versions between local and CI)
- No way to reproduce CI checks locally without installing every tool
- Violates the project's containerization philosophy

This plan runs all CI checks inside a dedicated CI container so that
`make ci-all` locally and the GHA workflow produce identical results. Inspired
by openshift/boilerplate's `container-pr-check` pattern.

## Architecture

- `test/Containerfile.ci` defines the CI container with all lint/validation tools
- `make ci-all` builds the CI container and runs `make ci-checks` inside it
  serially (local developer entry point)
- `.github/workflows/ci.yaml` builds the same CI image once, then fans out to
  parallel jobs — each running a single `make <target>` inside that image
- A separate `image-build` GHA job runs on the host (needs podman for the app image)

### Local vs Remote Execution

- **Locally**: `make ci-all` runs all checks serially in one container
- **Remotely**: GHA builds the CI image once (uploaded as artifact), then each
  check runs as a separate parallel job loading that same image

Both paths use the same Makefile targets and the same container image.

## Checks (run inside CI container via `make ci-checks`)

| Check | Tool | What it validates |
| ----- | ---- | ----------------- |
| yaml-lint | yamllint | YAML syntax in deploy/, ollama.yaml |
| markdown-lint | markdownlint-cli2 | Markdown formatting |
| makefile-lint | checkmake | Makefile best practices |
| containerfile-check | bash script | Base image tags and registries |
| kubernetes-validate | kubeconform | K8s manifest validity |
| python-lint | ruff | Python lint + format on examples/ |
| shellcheck-lint | shellcheck | Shell scripts in test/scripts/ |
| docs-check | bash (find) | Plan docs exist in docs/plans/ |

## Files Added/Modified

- `test/Containerfile.ci` — CI container image (fedora-minimal:42 with all tools)
- `test/scripts/check-containerfile-tags.sh` — Containerfile validation script
- `test/.containerignore` — empty build context for CI container
- `.github/workflows/ci.yaml` — GHA workflow (10 jobs: ci-image build + 8
  parallel lint/check jobs + image-build)
- `.yamllint.yaml` — yamllint config
- `.markdownlint.yaml` — markdownlint config
- `.containerignore` — updated to exclude test/CI files from app image
- `Containerfile` — added OCI standard labels
- `Makefile` — added CI targets and `default` PHONY, `clean`, `test` targets
- `ollama.yaml` — fixed env var value type (number to string)
- `examples/ask.py` — fixed ruff lint/format issues
- `README.md` — fixed markdown lint issues (table separators, list spacing,
  code block language)
- `CONVENTIONS.md` — project conventions document
- `CLAUDE.md` — Claude Code configuration referencing CONVENTIONS.md

## Implementation Notes

Issues discovered and fixed during implementation:

1. **fedora-minimal missing tar/gzip** — CI container needed `tar` and `gzip`
   for kubeconform binary extraction
2. **fedora-minimal missing git** — CI container needed `git` for Makefile's
   `GIT_HASH` variable; also added graceful fallback when git unavailable
3. **Newer markdownlint MD060 rule** — table separator rows need spaces around
   pipes; fixed in all markdown files rather than disabling the rule
4. **checkmake requirements** — Makefile needed `default` as PHONY, plus `clean`
   and `test` targets
5. **kubeconform found real bug** — `ollama.yaml` had `value: 8` (number) for
   OLLAMA_NUM_THREADS env var; K8s requires strings; fixed to `value: "8"`
6. **ruff found real bug** — `examples/ask.py` had an f-string without
   placeholders; also needed formatting fixes (blank lines, trailing commas)
7. **Git worktree resolution** — `.git` file in worktrees points outside the
   container mount; Makefile now handles gracefully with fallback to "unknown"

## Verification

1. `make ci-all` locally builds the CI container and runs all 8 checks — all pass
2. GHA workflow triggers on PR with parallel jobs using the same container
3. `image-build` job validates the app container builds and `ollama --help` runs
