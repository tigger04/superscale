<!-- Version: 0.1 | Last updated: 2026-03-18 -->

# Testing

## Strategy

Testing follows TDD per project standards. All tests use XCTest and run via `make test` (`swift test`).

## Test types

| Type | Scope | Location | Speed |
|------|-------|----------|-------|
| Unit | Individual functions, model registry, path resolution | `Tests/SuperscaleTests/` | Fast (<1s) |
| Integration | Full pipeline with small test images | `Tests/SuperscaleTests/` | Medium (<10s) |
| End-to-end | CLI invocation via subprocess | `Tests/SuperscaleTests/` | Slow (<30s) |
| Quality | Output comparison against PyTorch reference | `Tests/SuperscaleTests/` | Slow |

## Test structure

```
Tests/SuperscaleTests/
├── TilerTests.swift              # Tile splitting and stitching
├── ModelRegistryTests.swift      # Model lookup, metadata
├── ImageLoaderTests.swift        # Image reading, format detection
├── ImageWriterTests.swift        # Output writing, format options
├── CLITests.swift                # End-to-end CLI subprocess tests
├── QualityTests.swift            # Output vs reference comparison
├── Resources/
│   ├── test_input_64x64.png      # Minimal test image
│   ├── test_input_alpha.png      # Image with alpha channel
│   └── reference_output_4x.png   # PyTorch reference output
└── NEXT_IDS.txt                  # Test ID allocation
```

## Quality validation

Output quality is validated by comparing Superscale's output against the PyTorch reference implementation:

1. Run the same input image through both PyTorch Real-ESRGAN and Superscale
2. Compare pixel-by-pixel using PSNR (peak signal-to-noise ratio)
3. Threshold: PSNR > 40 dB (visually indistinguishable)

Small numerical differences are expected between PyTorch and CoreML due to floating-point precision differences across runtimes. The PSNR threshold accommodates this.

## Test images

Test images are small (64×64 or 128×128) synthetic images to keep the test suite fast. Quality validation uses a single 256×256 natural image with a pre-computed PyTorch reference.

No production images, copyrighted content, or user data in the test suite.

## Test IDs

Per project standards, all tests carry unique IDs:

| Prefix | Type | Run by |
|--------|------|--------|
| `RT-NNN` | Regression test | `make test` |
| `OT-NNN` | One-off test | `make test-one-off` |
| `UT-NNN` | User test | Manual |

IDs are allocated from `Tests/SuperscaleTests/NEXT_IDS.txt`.

## Makefile targets

```makefile
test            # swift test (all regression tests)
test-one-off    # Run one-off tests
```

## See also

- [Architecture](architecture.md) — component overview
- [Implementation plan](implementation-plan.md) — which phases introduce which tests
