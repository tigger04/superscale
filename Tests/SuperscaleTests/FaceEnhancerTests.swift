// ABOUTME: Tests for face enhancement — GFPGAN download, CLI flags, face detection.
// ABOUTME: Validates AC1.1–AC1.6 for the optional face enhancement feature.

import XCTest
import CoreGraphics
@testable import Superscale

final class FaceEnhancerTests: XCTestCase {

    private var projectRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private var testImagesDir: URL {
        projectRoot.appendingPathComponent("Tests/images")
    }

    // RT-041: --face-enhance without GFPGAN model → exit 1 with download instructions
    func test_face_enhance_without_model_shows_download_instructions_RT041() throws {
        // Ensure the GFPGAN model is NOT present in any search path
        let faceModelPath = ModelRegistry.userModelsDirectory
            .appendingPathComponent("GFPGANv1.4.mlpackage")
        try XCTSkipIf(FileManager.default.fileExists(atPath: faceModelPath.path),
                      "GFPGAN model is present — cannot test missing model scenario")

        let input = testImagesDir.appendingPathComponent("remy2.jpg")
        try XCTSkipIf(!FileManager.default.fileExists(atPath: input.path),
                      "remy2.jpg not found")

        let result = try runCLI(["--face-enhance", input.path])

        XCTAssertNotEqual(result.exitCode, 0,
                          "Should fail when face model is not present")
        XCTAssertTrue(
            result.stderr.lowercased().contains("download"),
            "Error should mention downloading the face model — stderr: \(result.stderr)")
    }

    // RT-042: GFPGAN excluded from git, formula, and distribution
    func test_gfpgan_excluded_from_distribution_RT042() throws {
        // 1. Check .gitignore covers GFPGAN model files
        let gitignore = try String(contentsOfFile:
            projectRoot.appendingPathComponent(".gitignore").path)
        // *.mlpackage and *.pth patterns cover GFPGAN files
        XCTAssertTrue(gitignore.contains("*.mlpackage"),
                      ".gitignore should exclude *.mlpackage")
        XCTAssertTrue(gitignore.contains("*.pth"),
                      ".gitignore should exclude *.pth")

        // 2. Check formula has no GFPGAN resource
        let formula = try String(contentsOfFile:
            projectRoot.appendingPathComponent("Formula/superscale.rb").path)
        XCTAssertFalse(
            formula.lowercased().contains("gfpgan"),
            "Formula should not contain any GFPGAN references")

        // 3. Check GFPGAN model is not in git tracked files
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["ls-files", "--cached"]
        process.currentDirectoryURL = projectRoot
        process.standardOutput = pipe
        try process.run()
        process.waitUntilExit()
        let trackedFiles = String(
            data: pipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8) ?? ""
        XCTAssertFalse(
            trackedFiles.lowercased().contains("gfpgan"),
            "No GFPGAN files should be tracked in git")
    }

    // RT-043: Face detection runs without error and returns face rectangles
    func test_face_detection_runs_on_image_RT043() throws {
        let photoURL = testImagesDir.appendingPathComponent("remy2.jpg")
        try XCTSkipIf(!FileManager.default.fileExists(atPath: photoURL.path),
                      "remy2.jpg not found")

        let loaded = try ImageLoader.load(from: photoURL)

        // FaceDetector should run without error regardless of whether faces are found
        let faces = try FaceDetector.detect(in: loaded.image)

        // The result should be a valid (possibly empty) array of face rectangles
        XCTAssertNotNil(faces, "Face detection should return a result")
        // Each detected face should have valid normalized coordinates
        for face in faces {
            XCTAssertGreaterThanOrEqual(face.origin.x, 0,
                                        "Face rect x should be >= 0")
            XCTAssertGreaterThanOrEqual(face.origin.y, 0,
                                        "Face rect y should be >= 0")
            XCTAssertGreaterThan(face.size.width, 0,
                                 "Face rect width should be > 0")
            XCTAssertGreaterThan(face.size.height, 0,
                                 "Face rect height should be > 0")
        }
    }

    // MARK: - Helpers

    struct CLIResult {
        let exitCode: Int32
        let stdout: String
        let stderr: String
    }

    func runCLI(_ arguments: [String]) throws -> CLIResult {
        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        let binaryPath = projectRoot
            .appendingPathComponent(".build/debug/superscale")

        process.executableURL = binaryPath
        process.arguments = arguments
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

        return CLIResult(
            exitCode: process.terminationStatus,
            stdout: String(data: stdoutData, encoding: .utf8) ?? "",
            stderr: String(data: stderrData, encoding: .utf8) ?? ""
        )
    }
}
