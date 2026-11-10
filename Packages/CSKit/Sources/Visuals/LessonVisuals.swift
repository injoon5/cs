#if canImport(UIKit)
import Contracts
import SwiftUI
import VisualsLayout

// Public API used by Lessons. Keep the signatures.

/// A compact step-through inside lesson text (PLAN.md, Inline trace): the code with the current
/// line tinted, plain playback controls, the innermost frame's variables as chips, and output
/// once something prints.
///
/// Everything it draws per step is computed once per trace and cached, so stepping is a lookup.
/// The code block and the variable rows keep one size for the whole trace; only the output,
/// at the bottom, grows.
public struct InlineTraceView: View {
    let code: String
    let trace: Trace
    let stop: Int?

    @State private var player: ScenePlayer
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// `stop` is 1-based: playback pauses showing step `stop` (docs/contracts.md, Trace stops).
    public init(code: String, trace: Trace, stop: Int? = nil) {
        self.init(code: code, trace: trace, stop: stop, startAt: 0)
    }

    /// `startAt` is a 0-based step to open on, for the debug gallery.
    init(code: String, trace: Trace, stop: Int?, startAt: Int) {
        self.code = code
        self.trace = trace
        self.stop = stop
        let player = ScenePlayer(frameCount: trace.steps.count, interval: .milliseconds(700))
        player.seek(to: startAt)
        _player = State(initialValue: player)
    }

    public var body: some View {
        let entry = LessonVisualsCache.trace(code: code, trace: trace)
        let index = min(max(player.currentIndex, 0), entry.model.steps.count - 1)
        let step = index >= 0 ? entry.model.steps[index] : nil
        let lineHeight = CodeFont.lineHeight(dynamicTypeSize)

        VStack(alignment: .leading, spacing: 4) {
            TraceCodeView(
                lines: entry.lines,
                current: (step?.line ?? 0) - 1,
                isError: step?.event == .exception,
                lineHeight: lineHeight
            )
            TraceControls(player: player)
            if !entry.model.slots.isEmpty, let step {
                TraceVariablesView(
                    model: entry.model,
                    step: step,
                    stepIndex: index,
                    arrays: LessonVisualsCache.arrays(for: entry, dynamicTypeSize: dynamicTypeSize)
                )
                .padding(.bottom, 8)
            }
            if let output = output(at: index, step: step) {
                TraceOutputView(text: output.text, isError: output.isError)
                    .transition(.opacity)
            }
        }
        .onChange(of: stop, initial: true) {
            player.stopIndex = stop.map { $0 - 1 }
        }
        .onChange(of: trace.steps.count) {
            player.setFrameCount(trace.steps.count)
            player.seek(to: 0)
        }
        .onChange(of: reduceMotion, initial: true) {
            player.reduceMotion = reduceMotion
        }
        .onDisappear { player.pause() }
    }

    /// Output so far, plus the error on the last step of a run that raised.
    private func output(at index: Int, step: InlineTraceModel.Step?) -> (text: String, isError: Bool)? {
        var text = step?.output ?? ""
        if text.hasSuffix("\n") { text.removeLast() }
        var isError = false
        if let error = trace.error, index == trace.steps.count - 1 {
            if !text.isEmpty { text += "\n" }
            text += error.message.isEmpty ? error.type : "\(error.type): \(error.message)"
            isError = true
        }
        return text.isEmpty ? nil : (text, isError)
    }
}

/// A static ```diagram block (PLAN.md, Lesson diagrams). Laid out once per diagram and Dynamic
/// Type size, then cached. Sized to its content; scrolls sideways only when it is wider than the
/// reading width, so cells never shrink.
public struct DiagramView: View {
    let diagram: Diagram

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(diagram: Diagram) {
        self.diagram = diagram
    }

    public var body: some View {
        let scene = LessonVisualsCache.diagram(diagram, dynamicTypeSize: dynamicTypeSize)
        ViewThatFits(in: .horizontal) {
            SceneView(scene: scene)
            ScrollView(.horizontal) {
                SceneView(scene: scene)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ShapeDescription.describe(diagram))
    }
}

/// Lesson visuals are laid out once and kept for the session, keyed by the block they come
/// from (PLAN.md, Rendering and performance: Lessons).
@MainActor
enum LessonVisualsCache {
    final class TraceEntry {
        let key: String
        let lines: [String]
        let model: InlineTraceModel

        init(key: String, lines: [String], model: InlineTraceModel) {
            self.key = key
            self.lines = lines
            self.model = model
        }
    }

    private struct DiagramKey: Hashable {
        var diagram: Diagram
        var dynamicTypeSize: DynamicTypeSize
    }

    private struct ArraysKey: Hashable {
        var trace: String
        var dynamicTypeSize: DynamicTypeSize
    }

    /// Lessons hold a few dozen blocks; past this, start over rather than track recency.
    private static let limit = 128
    private static var traces: [String: TraceEntry] = [:]
    private static var arrays: [ArraysKey: [Int: SceneTimeline]] = [:]
    private static var diagrams: [DiagramKey: SceneLayout] = [:]

    /// Keyed by the block's source: a recorded trace is a function of its code.
    static func trace(code: String, trace: Trace) -> TraceEntry {
        let key = "\(trace.steps.count)\u{0}\(code)"
        if let cached = traces[key] { return cached }
        var lines = code.components(separatedBy: "\n")
        while lines.count > 1, lines.last?.isEmpty == true { lines.removeLast() }
        let entry = TraceEntry(key: key, lines: lines, model: InlineTraceModel(trace: trace))
        if traces.count >= limit { traces.removeAll() }
        traces[key] = entry
        return entry
    }

    /// One timeline per list variable, so each keeps one size for the whole trace.
    static func arrays(for entry: TraceEntry, dynamicTypeSize: DynamicTypeSize) -> [Int: SceneTimeline] {
        let key = ArraysKey(trace: entry.key, dynamicTypeSize: dynamicTypeSize)
        if let cached = arrays[key] { return cached }
        let metrics = LayoutMetrics.system(dynamicTypeSize)
        var timelines: [Int: SceneTimeline] = [:]
        for (index, slot) in entry.model.slots.enumerated() where slot.isSequence {
            timelines[index] = SceneLayoutEngine.layout(entry.model.arrayFrames(slot: index), metrics: metrics)
        }
        if arrays.count >= limit { arrays.removeAll() }
        arrays[key] = timelines
        return timelines
    }

    static func diagram(_ diagram: Diagram, dynamicTypeSize: DynamicTypeSize) -> SceneLayout {
        let key = DiagramKey(diagram: diagram, dynamicTypeSize: dynamicTypeSize)
        if let cached = diagrams[key] { return cached }
        let scene = SceneLayoutEngine.layout(diagram, metrics: .system(dynamicTypeSize))
        if diagrams.count >= limit { diagrams.removeAll() }
        diagrams[key] = scene
        return scene
    }
}
#endif
