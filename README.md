# Superscale

AI image upscaling for Apple Silicon, powered by CoreML and Real-ESRGAN.

Superscale converts Real-ESRGAN neural network models to CoreML format and runs them natively on Apple Silicon — using the Neural Engine and GPU rather than CPU. A 1024×1024 image at 4× scale completes in seconds, not minutes.

## What it does

1. **Upscales images** using Real-ESRGAN models via Apple's CoreML framework
2. **Runs on the Neural Engine** — dedicated AI hardware on M-series chips
3. **Zero Python at runtime** — pure Swift CLI, no venv, no pip, no PyTorch
4. **Ships as a single binary** plus model files, installable via Homebrew

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

## Dependencies

| Dependency | Purpose | Install |
|-----------|---------|---------|
| macOS 14+ | CoreML runtime | Built-in |
| Xcode CLT | Swift compiler | `xcode-select --install` |

Runtime dependencies: **none**. CoreML is a system framework.

Build-time only: `coremltools` (Python, for model conversion during development/release).

## Documentation

| Document | Description |
|----------|-------------|
| [Vision](docs/VISION.md) | Project goals, non-goals, and design philosophy |
| [Architecture](docs/architecture.md) | System design, data flow, component overview |
| [Testing](docs/testing.md) | Test strategy, coverage, and conventions |
| [Implementation plan](docs/implementation-plan.md) | Phased delivery plan |
| [Model licensing](docs/model-licensing.md) | Licence status of bundled model weights |

## Project structure

```
superscale/
├── Sources/Superscale/       # Swift source
│   ├── main.swift            # CLI entry point
│   ├── Commands/             # ArgumentParser subcommands
│   ├── Pipeline/             # CoreML inference, image I/O
│   └── Models/               # Model registry, metadata
├── Tests/SuperscaleTests/    # XCTest suite
├── Models/                   # CoreML .mlpackage files (or download manifest)
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
