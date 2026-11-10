#if canImport(UIKit)
import Contracts
import Editor
import SwiftUI

/// One file: editor on top, console below, floating Run/Stop button.
struct PlaygroundFileView: View {
    private let store: PlaygroundStore
    @State private var file: PlaygroundFile
    @State private var text: String
    @State private var session: RunSession
    @State private var editorFocused = false
    /// Hides the error line highlight once the code changes after a run.
    @State private var editedSinceRun = false
    @State private var saveTask: Task<Void, Never>?
    @State private var isDirty = false
    @Environment(\.scenePhase) private var scenePhase

    init(file: PlaygroundFile, store: PlaygroundStore, runner: any PythonRunning) {
        self.store = store
        _file = State(initialValue: file)
        _text = State(initialValue: store.read(file))
        _session = State(initialValue: RunSession(runner: runner))
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                editor
                if !editorFocused {
                    ConsoleView(session: session)
                        .frame(height: consoleHeight(in: geometry.size))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .animation(.smooth, value: editorFocused)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarRole(.editor)
        .toolbar(.hidden, for: .tabBar)
        .onChange(of: text) {
            editedSinceRun = true
            isDirty = true
            scheduleSave()
        }
        .onChange(of: scenePhase) {
            if scenePhase != .active { saveNow() }
        }
        .onDisappear { saveNow() }
        #if DEBUG
        .task { await PlaygroundLaunchOptions.drive(session: session, code: { text }, focus: { editorFocused = true }) }
        #endif
    }

    private var editor: some View {
        CodeEditor(
            text: $text,
            isFocused: $editorFocused,
            highlightedLine: editedSinceRun ? nil : session.errorLine,
            runControl: CodeEditorRunControl(isRunning: session.isRunning, run: run, stop: stop)
        )
        .overlay(alignment: .bottomTrailing) {
            runButton
                .padding()
                .opacity(editorFocused ? 0 : 1)
                .allowsHitTesting(!editorFocused)
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
        .accessibilityLabel(session.isRunning ? "Stop" : "Run")
    }

    /// Console takes about two fifths of the screen, never less than a few lines.
    private func consoleHeight(in size: CGSize) -> CGFloat {
        max(180, (size.height * 0.4).rounded())
    }

    private var title: Binding<String> {
        Binding(
            get: { file.name },
            set: { newName in
                saveNow()
                file = store.rename(file, to: newName)
            }
        )
    }

    private func run() {
        saveNow()
        editorFocused = false
        editedSinceRun = false
        let code = text
        Task { await session.run(code) }
    }

    private func stop() {
        Task { await session.stop() }
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
        store.write(text, to: file.url)
    }
}
#endif
