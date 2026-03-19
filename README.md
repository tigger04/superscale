# Superscale

AI image upscaling that runs entirely on your Mac. No cloud. No API keys. No uploads. Your images stay on your machine.

Superscale uses Apple's Neural Engine — dedicated ML hardware built into every M-series chip — to upscale images in seconds. The CPU and GPU stay free for other work.

```bash
brew install tigger04/tap/superscale
superscale photo.png
```

That's it. One command to install, one command to upscale.

## Why Superscale?

- **Private** — images never leave your machine. No cloud processing, no accounts, no internet required after install.
- **Fast** — runs on the Neural Engine, not CPU. A 1024×1024 image upscales 4× in seconds.
- **Smart** — auto-detects content type (photo, illustration, anime) and selects the best model using Apple's Vision framework.
- **Simple** — single binary, all models bundled, zero dependencies. Works offline.

## Usage

```bash
# Upscale an image — auto-detects best model
superscale photo.png

# Specify scale factor and output directory
superscale -s 2 -o upscaled/ photo.png

# Process multiple images at once
superscale -o output/ *.png

# Override model selection (see table below)
superscale -m realesrgan-anime-6b illustration.png

# List available models
superscale --list-models
```

## Models

Six models are included, each optimized for different content. Auto-detection picks the right one, or you can override with `-m`:

| CLI name (`-m`) | Scale | Best for |
|-----------------|-------|----------|
| `realesrgan-x4plus` | 4× | General photos (default) |
| `realesrgan-x2plus` | 2× | General photos, lighter upscale |
| `realesrnet-x4plus` | 4× | Photos, PSNR-oriented (less sharpening) |
| `realesrgan-anime-6b` | 4× | Anime/illustration |
| `realesr-animevideov3` | 4× | Anime video frames |
| `realesr-general-x4v3` | 4× | General scenes, compact model |

## Face enhancement (optional)

Superscale can enhance faces in upscaled photos using GFPGAN. This model is not bundled due to its non-commercial licence — you download it separately:

```bash
superscale --download-face-model --accept-licence
```

Once installed, face enhancement runs automatically on every upscale. Use `--no-face-enhance` to skip it.

## Install

### Homebrew (recommended)

```bash
brew install tigger04/tap/superscale
```

### From source

```bash
git clone https://github.com/tigger04/superscale.git
cd superscale
make install
```

Requires Xcode Command Line Tools (`xcode-select --install`).

## Requirements

- macOS 14 (Sonoma) or later
- Apple Silicon (M1, M2, M3, M4)

No other dependencies. Everything runs on built-in system frameworks.

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
├── Sources/Superscale/          # Swift source
│   ├── SuperscaleCommand.swift  # CLI entry point (ArgumentParser)
│   ├── Pipeline.swift           # End-to-end upscaling orchestration
│   ├── CoreMLInference.swift    # CoreML model loading and inference
│   ├── ContentDetector.swift    # Auto-detect content type (photo/illustration)
│   ├── ModelRegistry.swift      # Model catalogue and path resolution
│   ├── Tiler.swift              # Tile splitting, overlap blending, stitching
│   ├── ImageLoader.swift        # Image reading (PNG, JPEG, TIFF, HEIC)
│   └── ImageWriter.swift        # Image writing with colour profile preservation
├── Tests/SuperscaleTests/       # XCTest suite
├── models/                      # Model manifest (manifest.json tracked; .mlpackage gitignored)
├── Formula/                     # Homebrew formula
├── scripts/                     # Release and conversion tooling
│   ├── convert_model.py         # PyTorch → CoreML conversion
│   ├── download-models.sh       # Download missing models from GitHub release
│   ├── release.sh               # Version bump, tag, GitHub release, tap update
│   └── release-models.sh        # Upload model artefacts to GitHub release
├── docs/                        # Project documentation
├── Package.swift                # Swift package manifest
├── Makefile                     # Build, test, install, release targets
└── LICENSE                      # MIT licence
```

## Makefile targets

| Target | Description |
|--------|-------------|
| `make build` | Download models (if needed) + build release binary |
| `make test` | Run test suite |
| `make install` | Build + symlink to `~/.local/bin` |
| `make release` | Tag, build, push, update Homebrew formula |
| `make release-models` | Upload model artefacts to GitHub Release |
| `make download-models` | Download missing models from GitHub release |
| `make convert-models` | Run PyTorch → CoreML conversion (dev only) |
| `make clean` | Remove build artefacts |
| `make sync` | Git add, commit, pull, push |

## Licence

MIT. Copyright Taḋg Paul.

Bundled model weights (Real-ESRGAN) are BSD-3-Clause (Copyright Xintao Wang, 2021). See [THIRD_PARTY_LICENSES](THIRD_PARTY_LICENSES).

The optional GFPGAN face enhancement model (`--download-face-model`) is **not bundled** and contains non-commercial components (StyleGAN2, DFDNet). The licence applies to the model weights, not to output images. See [model licensing](docs/model-licensing.md) for details.
