#!/usr/bin/env bash
# ABOUTME: Downloads missing CoreML models from the GitHub release.
# ABOUTME: Called by 'make build' and 'make install' to ensure all models are available.

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MANIFEST="${PROJECT_ROOT}/models/manifest.json"
MODELS_DIR="${PROJECT_ROOT}/models"

if [[ ! -f "${MANIFEST}" ]]; then
    echo "ERROR: models/manifest.json not found" >&2
    exit 1
fi

if ! command -v python3 > /dev/null 2>&1; then
    echo "ERROR: python3 is required" >&2
    exit 1
fi

# Parse model info from manifest
MODEL_DATA=$(python3 -c "
import json
manifest = json.loads(open('${MANIFEST}').read())
for m in manifest['models']:
    print(f\"{m['filename']}|{m.get('url', '')}\")
")

MISSING=0
DOWNLOADED=0

while IFS='|' read -r filename url; do
    pkg_path="${MODELS_DIR}/${filename}"

    if [[ -d "${pkg_path}" ]]; then
        continue
    fi

    MISSING=$((MISSING + 1))

    if [[ -z "${url}" ]]; then
        echo "WARNING: No download URL for ${filename}, skipping" >&2
        continue
    fi

    zipfile="${MODELS_DIR}/${filename}.zip"

    echo "Downloading ${filename}..."
    if curl -fSL "${url}" -o "${zipfile}"; then
        echo "  Extracting..."
        (cd "${MODELS_DIR}" && unzip -q -o "${filename}.zip")
        rm -f -- "${zipfile}"
        DOWNLOADED=$((DOWNLOADED + 1))
        echo "  OK: ${filename}"
    else
        echo "  FAILED: Could not download ${filename}" >&2
        rm -f -- "${zipfile}"
    fi
done <<< "${MODEL_DATA}"

if [[ ${MISSING} -eq 0 ]]; then
    echo "All models present."
elif [[ ${DOWNLOADED} -eq ${MISSING} ]]; then
    echo "Downloaded ${DOWNLOADED} model(s)."
else
    FAILED=$((MISSING - DOWNLOADED))
    echo "WARNING: ${FAILED} of ${MISSING} model(s) could not be downloaded." >&2
    exit 1
fi
