#if canImport(UIKit)
import Contracts
import SwiftUI

// Public API used by Lessons. Stubs until the Visuals agent implements them; keep the signatures.

/// A compact step-through inside lesson text (PLAN.md, Inline trace).
public struct InlineTraceView: View {
    let code: String
    let trace: Trace
    let stop: Int?

    /// `stop` is 1-based: playback pauses showing step `stop` (docs/contracts.md, Trace stops).
    public init(code: String, trace: Trace, stop: Int? = nil) {
        self.code = code
        self.trace = trace
        self.stop = stop
    }

    public var body: some View {
        Text(code).font(.system(.subheadline, design: .monospaced))
    }
}

/// A static ```diagram block (PLAN.md, Lesson diagrams).
public struct DiagramView: View {
    let diagram: Diagram

    public init(diagram: Diagram) {
        self.diagram = diagram
    }

    public var body: some View {
        EmptyView()
    }
}
#endif
