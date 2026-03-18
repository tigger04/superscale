// ABOUTME: Tests for licence files and third-party attribution.
// ABOUTME: Validates THIRD_PARTY_LICENSES content and GFPGAN exclusion from repo.

import XCTest

final class LicensingTests: XCTestCase {

    private var projectRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // SuperscaleTests/
            .deletingLastPathComponent()  // Tests/
            .deletingLastPathComponent()  // project root
    }

    // RT-027: THIRD_PARTY_LICENSES contains BSD-3-Clause attribution for Real-ESRGAN
    func test_third_party_licenses_contains_realesrgan_attribution_RT027() throws {
        let url = projectRoot.appendingPathComponent("THIRD_PARTY_LICENSES")
        let contents = try String(contentsOf: url, encoding: .utf8)

        XCTAssertTrue(contents.contains("BSD 3-Clause") || contents.contains("BSD-3-Clause"),
                      "Expected BSD-3-Clause licence text")
        XCTAssertTrue(contents.contains("Xintao Wang"),
                      "Expected Xintao Wang copyright holder")
        XCTAssertTrue(contents.contains("2021"),
                      "Expected 2021 copyright year")
        XCTAssertTrue(contents.contains("Real-ESRGAN"),
                      "Expected Real-ESRGAN source reference")
    }

    // RT-028: No GFPGAN files tracked; .gitignore covers model weight files
    func test_gfpgan_files_not_tracked_and_gitignored_RT028() throws {
        // Verify no GFPGAN files are tracked in git
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["ls-files"]
        process.currentDirectoryURL = projectRoot
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let trackedFiles = String(data: data, encoding: .utf8) ?? ""
        let gfpganFiles = trackedFiles
            .components(separatedBy: "\n")
            .filter { $0.lowercased().contains("gfpgan") }
        XCTAssertTrue(gfpganFiles.isEmpty,
                      "GFPGAN files must not be tracked: \(gfpganFiles)")

        // Verify .gitignore covers model weight formats
        let gitignoreURL = projectRoot.appendingPathComponent(".gitignore")
        let gitignore = try String(contentsOf: gitignoreURL, encoding: .utf8)
        XCTAssertTrue(gitignore.contains("*.pth"),
                      ".gitignore must exclude .pth files (covers GFPGAN weights)")
        XCTAssertTrue(gitignore.contains("*.mlpackage"),
                      ".gitignore must exclude .mlpackage files (covers GFPGAN conversions)")
    }
}
