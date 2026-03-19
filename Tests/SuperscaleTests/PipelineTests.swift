// ABOUTME: Tests for the Pipeline — end-to-end upscaling orchestration.
// ABOUTME: Validates AC9.1 (correct output), AC9.2 (progress reporting), AC9.3 (error handling).

import XCTest
import CoreGraphics
@testable import Superscale

final class PipelineTests: XCTestCase {

    private var testImagesDir: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // SuperscaleTests/
            .deletingLastPathComponent()  // Tests/
            .deletingLastPathComponent()  // project root
            .appendingPathComponent("Tests/images")
    }

    private var modelsDir: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("models")
    }

    // RT-021: Full pipeline produces correctly scaled output
    func test_pipeline_produces_correctly_scaled_output_RT021() throws {
        let inputURL = testImagesDir.appendingPathComponent("remy2.jpg")
        try XCTSkipIf(!FileManager.default.fileExists(atPath: inputURL.path),
                      "Test image remy2.jpg not found")

        let modelURL = modelsDir.appendingPathComponent("RealESRGAN_x2plus.mlpackage")
        try XCTSkipIf(!FileManager.default.fileExists(atPath: modelURL.path),
                      "x2plus model not found — run make convert-models")

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("superscale_pipeline_test_\(UUID().uuidString).png")
        defer { try? FileManager.default.removeItem(at: outputURL) }

        let pipeline = try Pipeline(modelName: "realesrgan-x2plus")
        try pipeline.process(input: inputURL, output: outputURL)

        // Verify output exists and has correct dimensions (1024×2 = 2048)
        let result = try ImageLoader.load(from: outputURL)
        XCTAssertEqual(result.image.width, 2048, "Output width should be 2× input")
        XCTAssertEqual(result.image.height, 2048, "Output height should be 2× input")
    }

    // RT-022: Pipeline reports progress on stderr during multi-tile processing
    func test_pipeline_reports_progress_RT022() throws {
        let inputURL = testImagesDir.appendingPathComponent("remy2.jpg")
        try XCTSkipIf(!FileManager.default.fileExists(atPath: inputURL.path),
                      "Test image remy2.jpg not found")

        let modelURL = modelsDir.appendingPathComponent("RealESRGAN_x2plus.mlpackage")
        try XCTSkipIf(!FileManager.default.fileExists(atPath: modelURL.path),
                      "x2plus model not found — run make convert-models")

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("superscale_progress_test_\(UUID().uuidString).png")
        defer { try? FileManager.default.removeItem(at: outputURL) }

        // Capture progress messages
        var progressMessages: [String] = []
        let pipeline = try Pipeline(modelName: "realesrgan-x2plus", tileSize: 256)
        pipeline.onProgress = { message in
            progressMessages.append(message)
        }

        try pipeline.process(input: inputURL, output: outputURL)

        // With 1024×1024 input and 256 tile size, should get multiple tiles
        XCTAssertGreaterThan(progressMessages.count, 0,
                             "Should report progress during processing")
        // At least one message should mention tile processing
        let hasTileMessage = progressMessages.contains { $0.contains("tile") || $0.contains("Tile") }
        XCTAssertTrue(hasTileMessage, "Progress should mention tile processing")
    }

    // RT-023: Pipeline errors on non-existent input path
    func test_pipeline_errors_on_invalid_input_RT023() throws {
        let badURL = URL(fileURLWithPath: "/nonexistent/path/image.png")
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("superscale_error_test_\(UUID().uuidString).png")
        defer { try? FileManager.default.removeItem(at: outputURL) }

        let pipeline = try Pipeline(modelName: "realesrgan-x2plus")

        XCTAssertThrowsError(try pipeline.process(input: badURL, output: outputURL)) { error in
            let description = String(describing: error)
            XCTAssertTrue(
                description.lowercased().contains("read") ||
                description.lowercased().contains("not found") ||
                description.lowercased().contains("cannot"),
                "Error should describe the problem: \(description)")
        }
    }
}
