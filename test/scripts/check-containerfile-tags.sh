#!/usr/bin/env bash
#
# Validates Containerfile base image references:
# - No :latest tags (warn or fail based on ENFORCE)
# - Images use known registries
#
set -euo pipefail

CONTAINERFILE="${1:-Containerfile}"
ENFORCE="${ENFORCE:-0}"
EXIT_CODE=0

KNOWN_REGISTRIES=(
  "docker.io"
  "ghcr.io"
  "gcr.io"
  "registry.k8s.io"
  "quay.io"
  "mcr.microsoft.com"
  "public.ecr.aws"
  "lscr.io"
  "registry.access.redhat.com"
  "registry.redhat.io"
  "registry.fedoraproject.org"
)

if [ ! -f "${CONTAINERFILE}" ]; then
  echo "ERROR: ${CONTAINERFILE} not found"
  exit 1
fi

echo "Checking ${CONTAINERFILE}..."

while IFS= read -r line; do
  # Extract image reference (skip "AS" alias)
  image=$(echo "${line}" | sed -E 's/^FROM\s+//i; s/\s+[Aa][Ss]\s+.*//; s/\s*$//')

  # Skip build stage references (no / or . in the name)
  if [[ ! "${image}" =~ [/.] ]]; then
    continue
  fi

  # Check for :latest tag
  if [[ "${image}" =~ :latest$ ]] || [[ ! "${image}" =~ : ]]; then
    echo "WARNING: ${image} uses :latest or no tag (implicit latest)"
    if [ "${ENFORCE}" = "1" ]; then
      EXIT_CODE=1
    fi
  fi

  # Check for known registry
  registry_found=0
  for registry in "${KNOWN_REGISTRIES[@]}"; do
    if [[ "${image}" == "${registry}/"* ]]; then
      registry_found=1
      break
    fi
  done

  if [ "${registry_found}" = "0" ]; then
    echo "WARNING: ${image} does not use a known registry"
    if [ "${ENFORCE}" = "1" ]; then
      EXIT_CODE=1
    fi
  fi

done < <(grep -iE '^FROM\s' "${CONTAINERFILE}")

if [ "${EXIT_CODE}" = "0" ]; then
  echo "All checks passed."
fi

exit ${EXIT_CODE}
