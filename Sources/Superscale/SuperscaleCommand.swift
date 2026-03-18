// ABOUTME: CLI entry point for Superscale.
// ABOUTME: Parses arguments and dispatches to the upscaling pipeline.

import ArgumentParser
import Foundation

@main
struct Superscale: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "superscale",
        abstract: "AI image upscaling for Apple Silicon.",
        version: "0.1.0"
    )

    @Argument(help: "Input image file(s).")
    var inputs: [String] = []

    @Option(name: .shortAndLong, help: "Scale factor (2 or 4).")
    var scale: Int = 4

    @Option(name: .shortAndLong, help: "Output directory.")
    var output: String?

    @Option(name: .shortAndLong, help: "Model name.")
    var model: String = "realesrgan-x4plus"

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

        // TODO: Phase 2 — wire up CoreML pipeline
        fputs("Superscale v0.1.0 — not yet implemented. See docs/implementation-plan.md\n", stderr)
        throw ExitCode.failure
    }
}
