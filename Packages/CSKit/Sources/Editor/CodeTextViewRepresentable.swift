#if canImport(UIKit)
import STPluginNeon
import STTextView
import SwiftUI
import TextFormation
import TextFormationPlugin

struct CodeTextViewRepresentable: UIViewRepresentable {
    @Binding var text: String
    let isFocused: Binding<Bool>?
    let highlightedLine: Int?
    let runControl: CodeEditorRunControl?
    let isEditable: Bool
    let showsLineNumbers: Bool

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> CodeTextView {
        let textView = CodeTextView()
        let coordinator = context.coordinator
        coordinator.parent = self
        // Plugins only run when the text view has a delegate.
        textView.textDelegate = coordinator

        textView.isEditable = isEditable
        textView.isSelectable = true
        textView.showsLineNumbers = showsLineNumbers
        textView.isScrollEnabled = isEditable
        // With a Run control the host floats a button over the bottom edge; let the last line scroll clear of it.
        let bottom: CGFloat = runControl == nil ? 8 : 88
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: bottom, right: 8)

        let font = UIFont.editorFont(compatibleWith: traits(for: dynamicTypeSize))
        textView.applyFont(font)
        coordinator.dynamicTypeSize = dynamicTypeSize
        coordinator.colorScheme = colorScheme

        textView.text = text
        coordinator.lastText = text
        // Start with the caret at the top, not where `text =` left it.
        textView.textSelection = NSRange(location: 0, length: 0)
        textView.contentOffset = .zero

        coordinator.installHighlighter(in: textView, font: font)
        if isEditable {
            textView.addPlugin(Self.formattingPlugin())
        }

        textView.onFocusChange = { focused in
            guard let isFocused = coordinator.parent?.isFocused, isFocused.wrappedValue != focused else { return }
            // Focus can change inside `updateUIView`; publish it after the update.
            Task { @MainActor in isFocused.wrappedValue = focused }
        }
        textView.runControl = runControl
        textView.highlightedLine = highlightedLine
        return textView
    }

    func updateUIView(_ textView: CodeTextView, context: Context) {
        let coordinator = context.coordinator
        coordinator.parent = self

        if text != coordinator.lastText {
            coordinator.lastText = text
            textView.text = text
        }

        if coordinator.dynamicTypeSize != dynamicTypeSize {
            coordinator.dynamicTypeSize = dynamicTypeSize
            let font = UIFont.editorFont(compatibleWith: traits(for: dynamicTypeSize))
            textView.applyFont(font)
            coordinator.installHighlighter(in: textView, font: font)
        }

        if coordinator.colorScheme != colorScheme {
            coordinator.colorScheme = colorScheme
            // Highlight colors are dynamic; redraw so they resolve for the new appearance.
            textView.textLayoutManager.invalidateLayout(for: textView.textLayoutManager.documentRange)
            textView.setNeedsLayout()
        }

        textView.runControl = runControl
        textView.highlightedLine = highlightedLine

        if let isFocused {
            if isFocused.wrappedValue, !textView.isFirstResponder, textView.window != nil {
                _ = textView.becomeFirstResponder()
            } else if !isFocused.wrappedValue, textView.isFirstResponder {
                _ = textView.resignFirstResponder()
            }
        }
    }

    /// Read-only editors size to their content; editable ones fill the proposed space.
    func sizeThatFits(_ proposal: ProposedViewSize, uiView textView: CodeTextView, context: Context) -> CGSize? {
        guard !isEditable, let width = proposal.width, width.isFinite, width > 0 else { return nil }
        if textView.bounds.width != width {
            textView.frame.size.width = width
        }
        textView.layoutIfNeeded()
        let layoutManager = textView.textLayoutManager
        layoutManager.ensureLayout(for: layoutManager.documentRange)
        var height = layoutManager.usageBoundsForTextContainer.height
        if height <= 0 { height = textView.font.lineHeight }
        let insets = textView.textContainerInset
        return CGSize(width: width, height: ceil(height + insets.top + insets.bottom))
    }

    static func dismantleUIView(_ textView: CodeTextView, coordinator: Coordinator) {
        textView.onFocusChange = nil
    }

    private func traits(for size: DynamicTypeSize) -> UITraitCollection {
        UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(size))
    }

    private static func formattingPlugin() -> TextFormationPlugin {
        let pairs = [("(", ")"), ("[", "]"), ("{", "}"), ("\"", "\""), ("'", "'")]
        let filters: [Filter] = pairs.map { StandardOpenPairFilter(open: $0.0, close: $0.1) }
            + [NewlineProcessingFilter()]
            + pairs.map { DeleteCloseFilter(open: $0.0, close: $0.1) }
        let indenter = TextualIndenter(patterns: PythonIndentation.patterns)
        let providers = WhitespaceProviders(
            leadingWhitespace: indenter.substitionProvider(indentationUnit: CodeTextView.indentUnit, width: 4),
            trailingWhitespace: WhitespaceProviders.removeAllProvider
        )
        return TextFormationPlugin(filters: filters, whitespaceProviders: providers)
    }

    @MainActor
    final class Coordinator {
        var parent: CodeTextViewRepresentable?
        var lastText = ""
        var dynamicTypeSize: DynamicTypeSize?
        var colorScheme: ColorScheme?
        private let highlighterID = STPluginIdentifier("highlighter")

        func installHighlighter(in textView: CodeTextView, font: UIFont) {
            textView.removePlugin(highlighterID)
            textView.addPlugin(NeonPlugin(theme: EditorTheme.neonTheme(font: font), language: .python), id: highlighterID)
        }
    }
}

extension CodeTextViewRepresentable.Coordinator: @preconcurrency STTextViewDelegate {
    func textViewDidChangeText(_ notification: Notification) {
        guard let textView = notification.object as? CodeTextView else { return }
        let newText = textView.text ?? ""
        textView.textDidChange()
        guard newText != lastText else { return }
        lastText = newText
        parent?.text = newText
    }
}

/// Indentation rules for Python: indent after a line ending in `:` or an open bracket,
/// outdent after a line that leaves the block, outdent a line starting with a close bracket.
enum PythonIndentation {
    static var patterns: [PatternMatcher] {
        [
            PreceedingLineSuffixIndenter(suffix: ":"),
            PreceedingLineSuffixIndenter(suffix: "("),
            PreceedingLineSuffixIndenter(suffix: "["),
            PreceedingLineSuffixIndenter(suffix: "{"),
            CurrentLinePrefixOutdenter(prefix: ")"),
            CurrentLinePrefixOutdenter(prefix: "]"),
            CurrentLinePrefixOutdenter(prefix: "}"),
            BlockExitOutdenter(),
        ]
    }
}

/// Outdents the line after `return`, `pass`, `break`, `continue` or `raise`.
private struct BlockExitOutdenter: PatternMatcher {
    private static let keywords = ["return", "pass", "break", "continue", "raise"]

    func action(for context: TextualContext) -> Indentation? {
        let line = context.strippedPreceedingLine
        for keyword in Self.keywords where line.hasPrefix(keyword) {
            let rest = line.dropFirst(keyword.count)
            if rest.isEmpty || rest.first == " " || rest.first == "(" {
                return .relativeDecrease(context.preceedingLineRange)
            }
        }
        return nil
    }
}
#endif
