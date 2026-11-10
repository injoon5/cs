#if canImport(UIKit)
import Contracts
import Editor
import SwiftUI
import Textual

/// Prompt on top, editor below, floating Run button and results pill. Results and hints open as sheets.
struct ExerciseScreen: View {
    enum ActiveSheet: String, Identifiable {
        case results, hints
        var id: String { rawValue }
    }

    let exercise: Exercise
    let progress: any ProgressRecording
    @State private var session: ExerciseSession
    @State private var text: String
    @State private var editorFocused = false
    /// Hides the error line highlight once the code changes after a run.
    @State private var editedSinceRun = false
    @State private var sheet: ActiveSheet?
    @State private var confirmingReset = false
    @State private var saveTask: Task<Void, Never>?
    @State private var isDirty = false
    @Environment(\.scenePhase) private var scenePhase

    init(exercise: Exercise, runner: any PythonRunning, progress: any ProgressRecording) {
        self.exercise = exercise
        self.progress = progress
        _session = State(initialValue: ExerciseSession(runner: runner))
        var code = progress.exerciseProgress(exercise.id).savedCode ?? exercise.starter
        #if DEBUG
        code = ExercisesLaunchOptions.code(for: exercise) ?? code
        #endif
        _text = State(initialValue: code)
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                if !editorFocused {
                    PromptView(markdown: exercise.prompt, maxHeight: promptMaxHeight(in: geometry.size))
                        .transition(.move(edge: .top).combined(with: .opacity))
                    Divider()
                }
                editor
            }
        }
        .animation(.smooth, value: editorFocused)
        .navigationTitle(exercise.title)
        .navigationSubtitle(exercise.level.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarRole(.editor)
        .toolbar(.hidden, for: .tabBar)
        .toolbar { toolbar }
        .sheet(item: $sheet) { sheet in
            switch sheet {
            case .results:
                if let completed = session.last {
                    TestResultsView(completed: completed)
                }
            case .hints:
                HintsSheet(exercise: exercise, progress: progress)
            }
        }
        .confirmationDialog("Reset to starter code?", isPresented: $confirmingReset, titleVisibility: .visible) {
            Button("Reset", role: .destructive, action: reset)
        }
        .sensoryFeedback(trigger: session.last) { _, completed in
            guard let report = completed?.report, !report.wasStopped else { return nil }
            return report.passed ? .success : .error
        }
        .onChange(of: text) {
            editedSinceRun = true
            isDirty = true
            scheduleSave()
        }
        .onChange(of: editorFocused) {
            if editorFocused, sheet == .results { sheet = nil }
        }
        .onChange(of: scenePhase) {
            if scenePhase != .active { saveNow() }
        }
        .onDisappear { saveNow() }
        #if DEBUG
        .task {
            await ExercisesLaunchOptions.drive(
                focus: { editorFocused = true },
                run: run,
                showHints: { sheet = .hints }
            )
        }
        #endif
    }

    // MARK: Editor

    /// The keyboard bar has Run while typing, and sheets cover the bottom (their glass would show the controls through).
    private var hidesFloatingControls: Bool {
        editorFocused || sheet != nil
    }

    private var editor: some View {
        CodeEditor(
            text: $text,
            isFocused: $editorFocused,
            highlightedLine: editedSinceRun ? nil : session.last?.report.errorLine,
            runControl: CodeEditorRunControl(isRunning: session.isRunning, run: run, stop: stop)
        )
        .overlay(alignment: .bottom) {
            HStack {
                ResultsPill(session: session) { sheet = .results }
                Spacer()
                runButton
            }
            .padding()
            .opacity(hidesFloatingControls ? 0 : 1)
            .allowsHitTesting(!hidesFloatingControls)
            .animation(.smooth, value: hidesFloatingControls)
        }
    }

    private var runButton: some View {
        Button {
            session.isRunning ? stop() : run()
        } label: {
            Image(systemName: session.isRunning ? "stop.fill" : "play.fill")
                .font(.title2)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.circle)
        .keyboardShortcut(session.isRunning ? "." : "r", modifiers: .command)
        .accessibilityLabel(session.isRunning ? "Stop" : "Run tests")
    }

    /// The prompt takes at most a third of the screen and scrolls past that.
    private func promptMaxHeight(in size: CGSize) -> CGFloat {
        max(120, (size.height * 0.34).rounded())
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button("Hints", systemImage: "lightbulb") { sheet = .hints }
        }
        ToolbarItem(placement: .primaryAction) {
            Menu("More", systemImage: "ellipsis") {
                Button("Reset to starter", systemImage: "arrow.counterclockwise") {
                    confirmingReset = true
                }
                .disabled(text == exercise.starter)
            }
        }
    }

    // MARK: Actions

    private func run() {
        guard !session.isRunning else { return }
        saveNow()
        editorFocused = false
        editedSinceRun = false
        if sheet == .results { sheet = nil }
        let code = text
        Task {
            guard let completed = await session.run(code, exercise: exercise) else { return }
            let report = completed.report
            guard !report.wasStopped else { return }
            progress.recordAttempt(exerciseID: exercise.id, report: report)
            sheet = .results
        }
    }

    private func stop() {
        Task { await session.stop() }
    }

    private func reset() {
        text = exercise.starter
        session.clear()
        saveNow()
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            saveNow()
        }
    }

    private func saveNow() {
        saveTask?.cancel()
        saveTask = nil
        guard isDirty else { return }
        isDirty = false
        progress.saveCode(text, exerciseID: exercise.id)
    }
}

/// The exercise statement, scrolling only when it's taller than its space.
private struct PromptView: View {
    let markdown: String
    let maxHeight: CGFloat
    @State private var contentHeight: CGFloat?

    var body: some View {
        ScrollView {
            StructuredText(markdown: markdown)
                .textual.textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .onGeometryChange(for: CGFloat.self, of: \.size.height) { contentHeight = $0 }
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicatorsFlash(onAppear: true)
        .frame(height: min(contentHeight ?? maxHeight, maxHeight))
    }
}

/// Bottom-leading glass pill: "Running" while tests run, then the summary. Opens the results.
private struct ResultsPill: View {
    let session: ExerciseSession
    let open: () -> Void

    var body: some View {
        if session.isRunning {
            HStack(spacing: 8) {
                ProgressView()
                Text("Running")
            }
            .font(.subheadline)
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .glassEffect()
            .transition(.opacity)
        } else if let completed = session.last {
            Button(action: open) {
                Label {
                    Text(completed.report.summary)
                        .monospacedDigit()
                } icon: {
                    ResultSymbol(passed: completed.report.passed)
                        .symbolEffect(.bounce, value: completed.report.passed ? completed.id : 0)
                }
                .font(.subheadline)
                .frame(minHeight: 44)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.capsule)
            .transition(.opacity)
        }
    }
}

/// Green checkmark or red cross.
struct ResultSymbol: View {
    let passed: Bool

    var body: some View {
        Image(systemName: passed ? "checkmark.circle.fill" : "xmark.circle.fill")
            .foregroundStyle(passed ? .green : .red)
            .accessibilityLabel(passed ? "Passed" : "Failed")
    }
}
#endif
