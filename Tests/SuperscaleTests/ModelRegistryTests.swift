// ABOUTME: Tests for ModelRegistry — model metadata, path resolution, and status.
// ABOUTME: Validates the model catalogue and --list-models CLI output with status indicators.

import XCTest

final class ModelRegistryTests: XCTestCase {

    // RT-006: --list-models shows model names with installed/available labels
    func test_cli_list_models_shows_status_labels_RT006() throws {
        let result = try runCLI(["--list-models"])
        XCTAssertEqual(result.exitCode, 0, "Expected exit code 0 for --list-models")

        // All six models must appear in the output
        let expectedModels = [
            "realesrgan-x4plus",
            "realesrgan-x2plus",
            "realesrnet-x4plus",
            "realesrgan-anime-6b",
            "realesr-animevideov3",
            "realesr-general-x4v3",
        ]
        for name in expectedModels {
            XCTAssertTrue(result.stdout.contains(name),
                          "Expected model '\(name)' in --list-models output")
        }

        // Each model line must have a status indicator
        let lines = result.stdout.components(separatedBy: "\n")
        let modelLines = lines.filter { line in
            expectedModels.contains { line.contains($0) }
        }
        XCTAssertEqual(modelLines.count, 6, "Expected exactly 6 model lines")

        for line in modelLines {
            XCTAssertTrue(
                line.contains("[installed]") || line.contains("[not installed]"),
                "Expected status indicator in line: \(line)"
            )
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

        let buildDir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // SuperscaleTests/
            .deletingLastPathComponent()  // Tests/
            .deletingLastPathComponent()  // project root
            .appendingPathComponent(".build/debug/superscale")

        process.executableURL = buildDir
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
