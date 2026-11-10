// Editor area: the Python code editor used by Playground, Exercises and Lessons.
//
// Public API
// ----------
//
//     // Editable: fills the space it's given and scrolls.
//     CodeEditor(
//         text: $code,
//         isFocused: $editing,                 // optional; true while the keyboard is up for it
//         highlightedLine: error?.line,        // optional; 1-based, tinted and scrolled to
//         runControl: CodeEditorRunControl(    // optional; adds Run/Stop to the keyboard bar
//             isRunning: session.isRunning,
//             run: { session.run(code) },
//             stop: { session.stop() }
//         )
//     )
//
//     // Read-only (lessons, results): sizes to its content height, no scrolling, selectable.
//     CodeEditor(code: source, highlightedLine: 3, showsLineNumbers: true)
//
// Both modes: SF Mono at the body text style size (Dynamic Type), line numbers, Python
// highlighting in Xcode's default light/dark colors (follows the system appearance).
// Editable mode adds current-line highlight, bracket pairing and auto-indent (4 spaces), and
// a keyboard bar with `:` `()` `[]` `{}`, outdent, indent, undo and Run.
//
// Hardware shortcuts belong to the host: put `.keyboardShortcut("r")` on its Run button and
// `.keyboardShortcut(".")` on Stop. They work while the editor has focus.

#if canImport(UIKit)
import SwiftUI

/// Run and Stop for the editor's keyboard bar. Run also dismisses the keyboard.
public struct CodeEditorRunControl {
    public var isRunning: Bool
    public var run: () -> Void
    public var stop: () -> Void

    public init(isRunning: Bool, run: @escaping () -> Void, stop: @escaping () -> Void) {
        self.isRunning = isRunning
        self.run = run
        self.stop = stop
    }
}

/// A Python code editor. See the top of this file for usage.
public struct CodeEditor: View {
    @Binding private var text: String
    private let isFocused: Binding<Bool>?
    private let highlightedLine: Int?
    private let runControl: CodeEditorRunControl?
    private let isEditable: Bool
    private let showsLineNumbers: Bool

    /// An editable editor that fills the proposed space.
    public init(
        text: Binding<String>,
        isFocused: Binding<Bool>? = nil,
        highlightedLine: Int? = nil,
        runControl: CodeEditorRunControl? = nil
    ) {
        _text = text
        self.isFocused = isFocused
        self.highlightedLine = highlightedLine
        self.runControl = runControl
        self.isEditable = true
        self.showsLineNumbers = true
    }

    /// Read-only, selectable code that sizes to fit its content.
    public init(code: String, highlightedLine: Int? = nil, showsLineNumbers: Bool = true) {
        _text = .constant(code)
        self.isFocused = nil
        self.highlightedLine = highlightedLine
        self.runControl = nil
        self.isEditable = false
        self.showsLineNumbers = showsLineNumbers
    }

    public var body: some View {
        CodeTextViewRepresentable(
            text: $text,
            isFocused: isFocused,
            highlightedLine: highlightedLine,
            runControl: runControl,
            isEditable: isEditable,
            showsLineNumbers: showsLineNumbers
        )
    }
}
#endif
