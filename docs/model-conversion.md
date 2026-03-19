<!-- Version: 1.0 | Last updated: 2026-03-19 -->

# Model conversion

This guide covers converting Real-ESRGAN PyTorch checkpoints (`.pth`) to CoreML (`.mlpackage`) format for use with Superscale. This is a build-time activity — end users do not need to do this.

## Prerequisites

- Python 3.12+ (via pyenv or system)
- ~2 GB disk space for checkpoints + converted models
- macOS (CoreML validation requires macOS)

## Quick start

```bash
# 1. Download all checkpoints
mkdir -p checkpoints && cd checkpoints
curl -LO https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth
curl -LO https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.1/RealESRGAN_x2plus.pth
curl -LO https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.1/RealESRNet_x4plus.pth
curl -LO https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.2.4/RealESRGAN_x4plus_anime_6B.pth
curl -LO https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.5.0/realesr-animevideov3.pth
curl -LO https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.5.0/realesr-general-x4v3.pth
cd ..

# 2. Convert all models
make convert-models

# 3. Verify inference works
swift test --filter CoreMLTests
```

## Checkpoints

All checkpoints are hosted on the [Real-ESRGAN GitHub releases](https://github.com/xinntao/Real-ESRGAN/releases) page under BSD-3-Clause licence.

| Model | Checkpoint | Release tag | Size |
|-------|-----------|-------------|------|
| General photo (4×) | `RealESRGAN_x4plus.pth` | v0.1.0 | ~64 MB |
| General photo (2×) | `RealESRGAN_x2plus.pth` | v0.2.1 | ~64 MB |
| PSNR-oriented (4×) | `RealESRNet_x4plus.pth` | v0.1.1 | ~64 MB |
| Anime/illustration (4×) | `RealESRGAN_x4plus_anime_6B.pth` | v0.2.2.4 | ~17 MB |
| Anime video (4×) | `realesr-animevideov3.pth` | v0.2.5.0 | ~6 MB |
| General compact (4×) | `realesr-general-x4v3.pth` | v0.2.5.0 | ~6 MB |

Download checkpoints into `checkpoints/` at the project root. This directory is gitignored.

## Conversion

### Using Make

```bash
make convert-models
```

This creates a Python venv (if absent), installs dependencies from `scripts/requirements-convert.txt`, and converts all six models. Output `.mlpackage` files are written to `models/`.

### Manual conversion

```bash
# Set up venv
python3 -m venv .venv
. .venv/bin/activate
pip install -r scripts/requirements-convert.txt

# Convert a single model
python scripts/convert_model.py realesrgan-x4plus --input-dir checkpoints --output-dir models

# Convert all models
python scripts/convert_model.py --all --input-dir checkpoints --output-dir models

# List supported models
python scripts/convert_model.py --list
```

### Script options

```
python scripts/convert_model.py [MODEL_NAME | --all] [OPTIONS]

Options:
  --input-dir DIR     Directory containing .pth files (default: checkpoints/)
  --output-dir DIR    Output directory for .mlpackage files (default: models/)
  --tile-size N       Input tile size for model tracing (default: 512)
  --list              List supported models and exit
  --help              Show usage
```

## What the script does

For each model:

1. Reconstructs the PyTorch architecture (RRDBNet or SRVGGNetCompact) with correct parameters
2. Loads the `.pth` checkpoint weights
3. Traces the model with a dummy input tensor
4. Converts to CoreML via `coremltools` with `ImageType` input/output
5. Validates by loading the `.mlpackage` back via CoreML
6. Reports the SHA256 hash for manifest integration

Architecture definitions are inline in the script — no dependency on `basicsr` or `realesrgan` packages.

## After conversion

### Verify

```bash
# Run the CoreML inference tests
swift test --filter CoreMLTests
```

### Publish

If you are preparing a release:

```bash
# Upload models to GitHub Release and update manifest
make release-models
```

This compresses each `.mlpackage` as a `.zip`, uploads to the `models-v1` GitHub Release, and updates `models/manifest.json` with SHA256 hashes.

## Troubleshooting

### `torch` installation fails

On Apple Silicon, ensure you are using a recent pip:

```bash
pip install --upgrade pip
pip install torch --index-url https://download.pytorch.org/whl/cpu
```

The CPU-only build of torch is sufficient for conversion (no GPU/CUDA needed).

### `coremltools` conversion fails

Ensure you are on macOS and using coremltools 7.0+. Older versions may not support the `minimum_deployment_target=ct.target.macOS14` parameter.

### Checkpoint key mismatch

The script handles checkpoints that wrap weights in `params_ema` or `params` keys (common in Real-ESRGAN releases). If you see a `strict=True` load error, the checkpoint format may have changed — check whether the `.pth` file contains the expected architecture.

## File layout

```
superscale/
├── checkpoints/                  ← .pth files (gitignored, download manually)
│   ├── RealESRGAN_x4plus.pth
│   └── ...
├── models/                       ← .mlpackage files (gitignored) + manifest (tracked)
│   ├── manifest.json             ← tracked by git
│   ├── RealESRGAN_x4plus.mlpackage  ← gitignored
│   └── ...
└── scripts/
    ├── convert_model.py          ← conversion script
    └── requirements-convert.txt  ← Python dependencies
```

## See also

- [Architecture](architecture.md) — how CoreML models are used at runtime
- [Model licensing](model-licensing.md) — licence status of model weights
- [Implementation plan](implementation-plan.md) — Phase 1 (issue #3)
