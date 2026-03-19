// ABOUTME: Detects image content type (photo vs illustration) using Apple's Vision framework.
// ABOUTME: Uses VNClassifyImageRequest to auto-select the best upscaling model.

import CoreGraphics
import Vision

/// Detected content type of an image.
enum ContentType: String, CustomStringConvertible {
    case photo = "photograph"
    case illustration = "illustration"

    var description: String { rawValue }
}

/// Detects image content type using Apple's built-in VNClassifyImageRequest.
///
/// The classifier runs in milliseconds with zero external dependencies — it uses
/// the macOS built-in image classification model (available since macOS 10.15).
enum ContentDetector {

    /// Minimum confidence for the "illustrations" label to classify as illustration.
    /// Photos typically score 0.1–0.35; real illustrations/anime score 0.6+.
    static let illustrationThreshold: Float = 0.5

    /// VNClassifyImageRequest label identifiers that indicate illustration/anime content.
    static let illustrationLabels: Set<String> = ["illustrations"]

    /// Detect the content type of an image using VNClassifyImageRequest.
    ///
    /// - Parameter image: The image to classify.
    /// - Returns: Detected content type and confidence score.
    static func detect(image: CGImage) throws -> (type: ContentType, confidence: Float) {
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])

        guard let observations = request.results else {
            return (.photo, 0.0)
        }

        let labels = observations.map {
            (identifier: $0.identifier, confidence: $0.confidence)
        }
        return interpret(labels: labels)
    }

    /// Interpret classification labels to determine content type.
    ///
    /// Separated from `detect()` for testability — allows testing the
    /// threshold/mapping logic without running VNClassifyImageRequest.
    ///
    /// - Parameter labels: Classification labels with confidence scores.
    /// - Returns: Detected content type and confidence score.
    static func interpret(
        labels: [(identifier: String, confidence: Float)]
    ) -> (type: ContentType, confidence: Float) {
        let maxIllustration = labels
            .filter { illustrationLabels.contains($0.identifier) }
            .map { $0.confidence }
            .max() ?? 0.0

        if maxIllustration >= illustrationThreshold {
            return (.illustration, maxIllustration)
        }
        return (.photo, 1.0 - maxIllustration)
    }

    /// Map a detected content type and scale factor to the best model name.
    ///
    /// - Parameters:
    ///   - contentType: Detected content type.
    ///   - scale: Desired scale factor (2 or 4).
    /// - Returns: CLI model name for ModelRegistry.
    static func modelName(for contentType: ContentType, scale: Int) -> String {
        switch (contentType, scale) {
        case (.illustration, 4):
            return "realesrgan-anime-6b"
        case (.illustration, _):
            // No 2× anime model available — fall back to general 2×
            return "realesrgan-x2plus"
        case (.photo, 2):
            return "realesrgan-x2plus"
        case (.photo, _):
            return "realesrgan-x4plus"
        }
    }
}
