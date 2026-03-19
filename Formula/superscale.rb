# ABOUTME: Homebrew formula for Superscale.
# ABOUTME: Updated automatically by scripts/release.sh — do not edit manually.
#
# This file is a local reference copy. The canonical formula
# lives in the tigger04/homebrew-tap repository.

class Superscale < Formula
  desc "AI image upscaling for Apple Silicon"
  homepage "https://github.com/tigger04/superscale"
  url "https://github.com/tigger04/superscale/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "PLACEHOLDER"
  license "MIT"

  depends_on :macos
  depends_on arch: :arm64

  resource "default_model" do
    url "https://github.com/tigger04/superscale/releases/download/models-v1/RealESRGAN_x4plus.mlpackage.zip"
    sha256 "66c6ce19ebf060378f0a9d6fc2a09b22f147a52893a576aa37b7991b551eaaf0"
  end

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/superscale"

    # Install default model alongside binary (Cellar prefix layout)
    resource("default_model").stage do
      (prefix/"models").install "RealESRGAN_x4plus.mlpackage"
    end
  end

  def caveats
    <<~EOS
      The default model (RealESRGAN_x4plus, 4× upscaling) is bundled.

      Additional models can be downloaded from:
        https://github.com/tigger04/superscale/releases/tag/models-v1

      Extract .mlpackage files to:
        ~/Library/Application Support/superscale/models/

      List available models:
        superscale --list-models
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/superscale --version")
    assert_match "realesrgan-x4plus", shell_output("#{bin}/superscale --list-models")
  end
end
