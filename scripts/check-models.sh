#!/usr/bin/env bash
# ABOUTME: Checks whether local .mlpackage files match the manifest SHA256 hashes.
# ABOUTME: Called by 'make sync' to warn developers about unpublished model changes.

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MANIFEST="${PROJECT_ROOT}/models/manifest.json"
MODELS_DIR="${PROJECT_ROOT}/models"

if [[ ! -f "${MANIFEST}" ]]; then
    exit 0
fi

if ! command -v python3 > /dev/null 2>&1; then
    exit 0
fi

# Check each model listed in the manifest
changed=0
python3 -c "
import json, hashlib, sys
from pathlib import Path

manifest = json.loads(Path('${MANIFEST}').read_text())
models_dir = Path('${MODELS_DIR}')

for model in manifest.get('models', []):
    pkg_path = models_dir / model['filename']
    if not pkg_path.exists():
        continue
    # Compute SHA256 of directory contents
    h = hashlib.sha256()
    for child in sorted(pkg_path.rglob('*')):
        if child.is_file():
            h.update(child.read_bytes())
    local_sha = h.hexdigest()
    manifest_sha = model.get('sha256', '')
    if manifest_sha and local_sha != manifest_sha:
        print(f\"  {model['name']}: manifest={manifest_sha[:12]}... local={local_sha[:12]}...\")
        sys.exit(2)
    elif not manifest_sha and pkg_path.exists():
        print(f\"  {model['name']}: present locally but no SHA256 in manifest\")
        sys.exit(2)
" 2>/dev/null && exit 0

echo "WARNING: Local model files differ from manifest. Run 'make release-models' to upload."
