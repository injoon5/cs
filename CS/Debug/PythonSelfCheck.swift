#if DEBUG
import Contracts
import Foundation
import Runtime

/// End-to-end check of Runtime against the bundled `app_support`, without UI automation.
/// Launch with `-PythonSelfCheck YES` and read the console: one `SELFCHECK` line per call.
enum PythonSelfCheck {
    static func runIfRequested() async {
        guard UserDefaults.standard.bool(forKey: "PythonSelfCheck") else { return }
        let runtime = PythonRuntime.shared

        let exercise = Exercise(
            id: "first-true", title: "First true", level: .core,
            prompt: "", starter: "", solution: "",
            testLines: ["first_true([False, False, True]) == 2", "first_true([]) == 0", "spin() == 0"]
        )
        let code = """
        def first_true(xs):
            lo, hi = 0, len(xs)
            while lo < hi:
                mid = (lo + hi) // 2
                if xs[mid]: hi = mid
                else: lo = mid + 1
            return lo

        def spin():
            while True: pass
        """
        let report = await runtime.runTests(code, exercise: exercise, timeout: 1)
        log("tests", report.results.map { "\($0.passed ? "pass" : "fail") \($0.name) got=\($0.got ?? "-") error=\($0.error?.type ?? "-")" }.joined(separator: " | ") + " loadError=\(report.loadError?.message ?? "-")")

        let trace = await runtime.trace("a = [3, 1]\nb = a\nb.append(2)\nprint(a)")
        log("trace", "steps=\(trace.steps.count) lastLine=\(trace.steps.last?.line ?? -1) stdout=\(trace.steps.last?.stdout.debugDescription ?? "-") error=\(trace.error?.type ?? "-")")

        let viz = await runtime.visualize("import viz\na = [2, 1]\nviz.array(a, pointers={'i': 0})\na[0], a[1] = a[1], a[0]\nviz.array(a)")
        log("viz", "frames=\(viz.frames.count) outcome=\(viz.result.outcome)")
    }

    private static func log(_ name: String, _ message: String) {
        print("SELFCHECK \(name): \(message)")
    }
}
#endif
