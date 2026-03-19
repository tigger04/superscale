# Superscale

Fast AI image upscaling for Mac. Takes a low-resolution image and produces a sharp, detailed version at 2× or 4× the original size.

Built natively for Apple Silicon — runs on the Neural Engine rather than CPU, so a 1024×1024 image upscales in seconds, not minutes.

## Features

- **2× and 4× upscaling** with multiple models optimized for photos, illustrations, and anime
- **Batch processing** — upscale entire directories of images
- **Fast** — uses Apple's Neural Engine hardware, not CPU
- **No dependencies** — single binary, installable via Homebrew

## Quickstart

### Homebrew (recommended)

```bash
brew tap tigger04/tap
brew install superscale
```

### From source

```bash
git clone https://github.com/tigger04/superscale.git
cd superscale
make install
```

### Usage

```bash
# Upscale a single image (4× by default)
superscale photo.png

# Specify scale factor and output directory
superscale -s 2 -o upscaled/ photo.png

# Process multiple images
superscale -o output/ *.png

# List available models
superscale --list-models
```

## Requirements

- macOS 14 (Sonoma) or later
- Apple Silicon (M1, M2, M3, M4)

No other dependencies. Everything runs on built-in system frameworks.

### Building from source

If building from source rather than installing via Homebrew, you'll need Xcode Command Line Tools (`xcode-select --install`).

## Documentation

| Document | Description |
|----------|-------------|
| [Vision](docs/VISION.md) | Project goals, non-goals, and design philosophy |
| [Architecture](docs/architecture.md) | System design, data flow, component overview |
| [Testing](docs/testing.md) | Test strategy, coverage, and conventions |
| [Implementation plan](docs/implementation-plan.md) | Phased delivery plan |
| [Model conversion](docs/model-conversion.md) | How to convert PyTorch checkpoints to CoreML |
| [Model licensing](docs/model-licensing.md) | Licence status of bundled model weights |

## Project structure

```
superscale/
├── Sources/Superscale/       # Swift source
│   ├── SuperscaleCommand.swift  # CLI entry point
│   ├── ModelRegistry.swift      # Model catalogue and path resolution
│   └── CoreMLInference.swift    # CoreML model loading and inference
├── Tests/SuperscaleTests/    # XCTest suite
├── models/                   # Model manifest (manifest.json tracked; .mlpackage gitignored)
├── Formula/                  # Homebrew formula
├── scripts/                  # Release and conversion tooling
│   └── convert_model.py      # PyTorch → CoreML conversion script
├── docs/                     # Project documentation
├── Package.swift             # Swift package manifest
├── Makefile                  # Build, test, install, release targets
└── LICENSE                   # MIT licence
```

## Makefile targets

| Target | Description |
|--------|-------------|
| `make build` | Build release binary |
| `make test` | Run test suite |
| `make install` | Build + symlink to `~/.local/bin` |
| `make release` | Tag, build, push, update Homebrew formula |
| `make release-models` | Upload model artefacts to GitHub Release |
| `make convert-models` | Run PyTorch → CoreML conversion (dev only) |
| `make clean` | Remove build artefacts |
| `make sync` | Git add, commit, pull, push |

## Supported models

| Model | Scale | Best for |
|-------|-------|----------|
| RealESRGAN_x4plus | 4× | General photos (default) |
| RealESRGAN_x2plus | 2× | General photos, lighter upscale |
| RealESRNet_x4plus | 4× | Photos, PSNR-oriented (less sharpening) |
| RealESRGAN_x4plus_anime_6B | 4× | Anime/illustration |
| realesr-animevideov3 | 4× | Anime video frames |
| realesr-general-x4v3 | 4× | General scenes, compact model |

All models are converted from xinntao's [Real-ESRGAN](https://github.com/xinntao/Real-ESRGAN) weights (BSD-3-Clause). See [model licensing](docs/model-licensing.md) for details.

## Licence

MIT. Copyright Taḋg Paul.

Model weights are BSD-3-Clause (Copyright Xintao Wang, 2021). See [THIRD_PARTY_LICENSES](THIRD_PARTY_LICENSES).
