// ABOUTME: End-to-end CLI tests for Superscale.
// ABOUTME: Validates command-line argument parsing and basic invocation.

import XCTest

final class CLITests: XCTestCase {

    // RT-001
    func test_cli_version_flag_returns_zero() throws {
        let result = try runCLI(["--version"])
        XCTAssertEqual(result.exitCode, 0, "Expected exit code 0 for --version")
        XCTAssertTrue(result.stdout.contains("0.1.0"), "Expected version string in output")
    }

    // RT-002
    func test_cli_help_flag_returns_zero() throws {
        let result = try runCLI(["--help"])
        XCTAssertEqual(result.exitCode, 0, "Expected exit code 0 for --help")
        XCTAssertTrue(result.stdout.contains("USAGE"), "Expected usage info in output")
    }

    // RT-003
    func test_cli_list_models_returns_zero() throws {
        let result = try runCLI(["--list-models"])
        XCTAssertEqual(result.exitCode, 0, "Expected exit code 0 for --list-models")
        XCTAssertTrue(result.stdout.contains("realesrgan-x4plus"), "Expected default model in list")
    }

    // RT-004
    func test_cli_no_input_returns_error() throws {
        let result = try runCLI([])
        XCTAssertNotEqual(result.exitCode, 0, "Expected non-zero exit code with no input")
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

        // Find the built binary
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
