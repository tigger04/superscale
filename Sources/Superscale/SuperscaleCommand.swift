// ABOUTME: CLI entry point for Superscale.
// ABOUTME: Parses arguments and dispatches to the upscaling pipeline.

import ArgumentParser
import Foundation

@main
struct Superscale: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "superscale",
        abstract: "AI image upscaling for Apple Silicon.",
        version: "0.2.0"
    )

    @Argument(help: "Input image file(s).")
    var inputs: [String] = []

    @Option(name: .shortAndLong, help: "Scale factor (2 or 4).")
    var scale: Int = 4

    @Option(name: .shortAndLong, help: "Output directory.")
    var output: String?

    @Option(name: .shortAndLong, help: "Model name.")
    var model: String = "realesrgan-x4plus"

    @Option(name: .long, help: "Tile size in pixels (smaller = less memory, more passes).")
    var tileSize: Int?

    @Flag(name: .long, help: "List available models.")
    var listModels: Bool = false

    mutating func run() throws {
        if listModels {
            print("Models:")
            for model in ModelRegistry.models {
                let status = ModelRegistry.isInstalled(model) ? "installed" : "not installed"
                let defaultLabel = model.isDefault ? " [default]" : ""
                let nameCol = model.name.padding(toLength: 24, withPad: " ", startingAt: 0)
                let descCol = "\(model.displayName)\(defaultLabel)"
                    .padding(toLength: 38, withPad: " ", startingAt: 0)
                print("  \(nameCol) \(descCol) [\(status)]")
            }
            return
        }

        guard !inputs.isEmpty else {
            throw ValidationError("No input files specified.")
        }

        // Resolve model — if -s is specified, pick the matching scale variant
        let modelName = resolveModelName()

        // Validate model exists
        guard let modelInfo = ModelRegistry.model(named: modelName) else {
            let available = ModelRegistry.models.map { $0.name }.joined(separator: ", ")
            throw ValidationError("Unknown model '\(modelName)'. Available: \(available)")
        }

        // Create output directory if needed
        let outputDir: URL?
        if let outputPath = output {
            let dirURL = URL(fileURLWithPath: outputPath)
            if !FileManager.default.fileExists(atPath: dirURL.path) {
                try FileManager.default.createDirectory(
                    at: dirURL, withIntermediateDirectories: true)
            }
            outputDir = dirURL
        } else {
            outputDir = nil
        }

        // Create pipeline
        let pipeline = try Pipeline(
            modelName: modelName, tileSize: tileSize)
        pipeline.onProgress = { message in
            fputs("\(message)\n", stderr)
        }

        // Process each input file, accumulating errors
        var errors: [(String, Error)] = []

        for inputPath in inputs {
            let inputURL = URL(fileURLWithPath: inputPath)
            let outputFilename = ImageWriter.outputFilename(
                for: inputPath, scale: modelInfo.scale)
            let outputURL: URL
            if let dir = outputDir {
                outputURL = dir.appendingPathComponent(outputFilename)
            } else {
                outputURL = inputURL.deletingLastPathComponent()
                    .appendingPathComponent(outputFilename)
            }

            do {
                try pipeline.process(input: inputURL, output: outputURL)
            } catch {
                errors.append((inputPath, error))
                fputs("Error processing \(inputPath): \(error)\n", stderr)
            }
        }

        if !errors.isEmpty {
            let total = inputs.count
            let failed = errors.count
            fputs("\(failed) of \(total) file(s) failed.\n", stderr)
            if failed == total {
                throw ExitCode.failure
            }
        }
    }

    /// Resolve the model name, matching scale factor if the user specified -s
    /// with the default model.
    private func resolveModelName() -> String {
        // If the user explicitly set -m, use it as-is
        if model != "realesrgan-x4plus" {
            return model
        }
        // If -s 2 was specified with the default model, switch to x2plus
        if scale == 2 {
            return "realesrgan-x2plus"
        }
        return model
    }
}
