<!-- Version: 0.1 | Last updated: 2026-03-18 -->

# Implementation plan

## Overview

Delivery is phased. Each phase produces a working, testable increment.

## Phase 1: CoreML model conversion

**Goal:** Convert RealESRGAN_x4plus (the default model) from PyTorch to CoreML and validate output quality.

**Tasks:**
1. Create Python conversion script (`scripts/convert_model.py`)
2. Set up conversion venv with torch, coremltools, basicsr
3. Convert RealESRGAN_x4plus.pth → RealESRGAN_x4plus.mlpackage
4. Compare output against PyTorch reference (PSNR > 40 dB)
5. Convert remaining models (x2plus, anime, general)

**Artefacts:** `.mlpackage` files for all supported models, conversion script.

**Risk:** CoreML may not support all operations used by Real-ESRGAN architectures. The RRDBNet architecture uses standard convolutions and upsampling which CoreML handles well. The compact SRVGGNetCompact architecture needs verification.

## Phase 2: Swift CLI — single image

**Goal:** A working CLI that upscales a single image using CoreML.

**Tasks:**
1. Set up Swift package (Package.swift, ArgumentParser)
2. Implement ImageLoader (CGImage-based)
3. Implement Tiler (split/stitch with overlap blending)
4. Implement CoreMLInference (load model, run prediction)
5. Implement ImageWriter (PNG/JPEG output)
6. Wire up CLI: `superscale input.png`
7. Add model selection: `superscale -m anime input.png`
8. Add scale factor: `superscale -s 2 input.png`
9. Add output path: `superscale -o out/ input.png`

**Artefacts:** Working `superscale` binary. Tests for each component.

## Phase 3: Polish and distribution

**Goal:** Homebrew formula, batch processing, progress reporting.

**Tasks:**
1. Batch processing (multiple input files, directory input)
2. Progress reporting to stderr (tile N of M)
3. Alpha channel handling
4. Colour profile preservation
5. Homebrew formula
6. `make release` automation
7. `--list-models` flag
8. `--help` / `--version`

**Artefacts:** `brew install superscale` works end-to-end.

## Phase 4: Model download

**Goal:** Models not bundled in the binary can be downloaded on first use.

**Tasks:**
1. Model manifest (JSON) listing available models and download URLs
2. First-use download with progress
3. SHA256 verification of downloaded models
4. `superscale --download-models` to pre-fetch

**Decision needed:** Whether to bundle models in the Homebrew bottle (larger install, works offline) or download on first use (smaller install, requires network). Could offer both via `brew install superscale` (minimal) and `brew install superscale --with-models` or a post-install step.

## Phase 5: SwiftUI GUI

**Goal:** Drag-and-drop image upscaling with preview.

**Tasks:**
1. Extract shared code into SuperscaleKit library
2. SwiftUI app target
3. Drag-and-drop input
4. Before/after preview with slider
5. Model and scale selection
6. Progress indicator
7. Batch queue

**Artefacts:** `Superscale.app` distributed as DMG or via Homebrew Cask.

## Dependencies between phases

```
Phase 1 (conversion) ──▶ Phase 2 (CLI) ──▶ Phase 3 (polish)
                                │                 │
                                │                 ▼
                                │           Phase 4 (download)
                                │
                                ▼
                          Phase 5 (GUI)
```

Phase 5 depends on Phase 2 (shared library) but can overlap with Phases 3–4.

## See also

- [Vision](VISION.md) — project goals
- [Architecture](architecture.md) — system design
- [Testing](testing.md) — test strategy
