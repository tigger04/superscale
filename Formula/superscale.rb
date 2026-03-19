class Superscale < Formula
  desc "AI image upscaling for Apple Silicon"
  homepage "https://github.com/tigger04/superscale"
  url "https://github.com/tigger04/superscale/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "0019dfc4b32d63c1392aa264aed2253c1e0c2fb09216f8e2cc269bbfb8bb49b5"
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
    assert_match "0.2.0", shell_output("#{bin}/superscale --version")
    assert_match "realesrgan-x4plus", shell_output("#{bin}/superscale --list-models")
  end
end
