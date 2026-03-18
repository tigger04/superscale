#!/usr/bin/env bash
# ABOUTME: Uploads model artefacts to a dedicated GitHub Release and updates the manifest.
# ABOUTME: Compresses each .mlpackage as a .zip (store-only) and attaches to the release.

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

if ! command -v gh > /dev/null 2>&1; then
    echo "ERROR: gh (GitHub CLI) is required. Install with: brew install gh" >&2
    exit 1
fi

if ! command -v python3 > /dev/null 2>&1; then
    echo "ERROR: python3 is required" >&2
    exit 1
fi

# Read release tag from manifest
RELEASE_TAG=$(python3 -c "import json; print(json.loads(open('${MANIFEST}').read())['release_tag'])")
echo "Release tag: ${RELEASE_TAG}"

# Verify all .mlpackage files exist
MISSING=0
MODEL_NAMES=$(python3 -c "
import json
manifest = json.loads(open('${MANIFEST}').read())
for m in manifest['models']:
    print(m['filename'])
")

for filename in ${MODEL_NAMES}; do
    if [[ ! -d "${MODELS_DIR}/${filename}" ]]; then
        echo "MISSING: ${filename}" >&2
        MISSING=$((MISSING + 1))
    fi
done

if [[ ${MISSING} -gt 0 ]]; then
    echo "ERROR: ${MISSING} model file(s) missing. Run 'make convert-models' first." >&2
    exit 1
fi

# Compress each .mlpackage to .zip (store-only, no compression)
echo "Compressing models..."
ASSETS=()
for filename in ${MODEL_NAMES}; do
    zipfile="${MODELS_DIR}/${filename}.zip"
    if [[ -f "${zipfile}" ]]; then
        rm -- "${zipfile}"
    fi
    (cd "${MODELS_DIR}" && zip -0 -r "${filename}.zip" "${filename}")
    ASSETS+=("${zipfile}")
    echo "  ${filename}.zip"
done

# Create or update the GitHub Release
if gh release view "${RELEASE_TAG}" > /dev/null 2>&1; then
    echo "Updating existing release: ${RELEASE_TAG}"
    gh release upload "${RELEASE_TAG}" "${ASSETS[@]}" --clobber
else
    echo "Creating new release: ${RELEASE_TAG}"
    gh release create "${RELEASE_TAG}" "${ASSETS[@]}" \
        --title "Model Artefacts (${RELEASE_TAG})" \
        --notes "CoreML .mlpackage model files for Superscale. See models/manifest.json for details." \
        --prerelease
fi

# Update manifest SHA256 hashes and URLs
echo "Updating manifest SHA256 hashes..."
python3 -c "
import json, hashlib
from pathlib import Path

manifest_path = Path('${MANIFEST}')
manifest = json.loads(manifest_path.read_text())
models_dir = Path('${MODELS_DIR}')

for model in manifest['models']:
    pkg_path = models_dir / model['filename']
    if not pkg_path.exists():
        continue
    h = hashlib.sha256()
    for child in sorted(pkg_path.rglob('*')):
        if child.is_file():
            h.update(child.read_bytes())
    model['sha256'] = h.hexdigest()
    print(f\"  {model['name']}: {model['sha256'][:16]}...\")

manifest_path.write_text(json.dumps(manifest, indent=2) + '\n')
print('Manifest updated.')
"

# Stage and commit the updated manifest
git add models/manifest.json
if ! git diff --cached --quiet -- models/manifest.json; then
    git commit -m "chore: update model manifest SHA256 hashes for ${RELEASE_TAG}"
    echo "Committed manifest update."
fi

echo ""
echo "--- Release Summary ---"
echo "  Tag:    ${RELEASE_TAG}"
echo "  Assets: ${#ASSETS[@]} model(s) uploaded"
echo "  Done."
