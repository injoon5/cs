import Contracts
import Foundation
import Testing
@testable import Runtime

// Python is embedded only in the iOS app. Elsewhere the runtime must fail cleanly, not crash.
@Suite struct StubRuntimeTests {
    let runtime = PythonRuntime(configuration: .init(
        home: URL(filePath: "/nonexistent"),
        searchPaths: [],
        scratchDirectory: FileManager.default.temporaryDirectory
    ))

    @Test func unavailableOffIOS() {
        #if !os(iOS)
        #expect(!PythonRuntime.isAvailable)
        #endif
    }

    @Test func runFailsWithError() async throws {
        try #require(!PythonRuntime.isAvailable)
        let result = await runtime.run("print(1)", output: { _ in }, readLine: { _ in nil })
        guard case .failed(let error) = result.outcome else {
            Issue.record("expected failure, got \(result.outcome)")
            return
        }
        #expect(error.type == "RuntimeError")
        #expect(error.message.contains("isn't available"))
    }

    @Test func otherCallsFailWithError() async throws {
        try #require(!PythonRuntime.isAvailable)
        let exercise = Exercise(id: "x", title: "X", level: .warmup, prompt: "", starter: "", solution: "")
        #expect(await runtime.runTests("", exercise: exercise, timeout: 1).loadError != nil)
        #expect(await runtime.trace("").error != nil)
        #expect(await runtime.visualize("").frames.isEmpty)
        await runtime.stop()
    }
}
