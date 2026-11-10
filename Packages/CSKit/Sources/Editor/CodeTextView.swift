#if canImport(UIKit)
import STTextKitPlus
import STTextView
import UIKit

/// `STTextView` configured for Python: SF Mono, no text substitutions, keyboard bar,
/// indent/outdent, and a highlighted line drawn behind the text.
@MainActor
final class CodeTextView: STTextView {
    static let indentUnit = "    "

    var onFocusChange: ((Bool) -> Void)?

    /// Shows a Run (or Stop) button on the keyboard bar.
    var runControl: CodeEditorRunControl? {
        didSet { keyboardBar.update(runControl: runControl) }
    }

    /// 1-based line drawn with a tinted background, or nil.
    var highlightedLine: Int? {
        didSet {
            guard highlightedLine != oldValue else { return }
            setNeedsLayout()
            if let highlightedLine { scrollToLine(highlightedLine) }
        }
    }

    private lazy var keyboardBar = KeyboardBar(textView: self)
    private let highlightedLineView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        autocorrectionType = .no
        autocapitalizationType = .none
        smartQuotesType = .no
        smartDashesType = .no
        smartInsertDeleteType = .no
        spellCheckingType = .no
        keyboardType = .asciiCapable
        keyboardDismissMode = .interactive
        alwaysBounceVertical = true

        backgroundColor = EditorTheme.background
        textColor = .label
        selectedLineHighlightColor = EditorTheme.currentLine
        isHorizontallyResizable = false // wrap long lines; no sideways scrolling on a phone

        highlightedLineView.backgroundColor = EditorTheme.highlightedLine
        highlightedLineView.isUserInteractionEnabled = false
        highlightedLineView.isHidden = true
        insertSubview(highlightedLineView, at: 0)

        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardFrameWillChange(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        center.addObserver(self, selector: #selector(keyboardFrameWillChange(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        #if DEBUG
        installDebugHooks()
        #endif
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func applyFont(_ font: UIFont) {
        self.font = font
        guard let gutterView else { return }
        // Line numbers: same size as the code so baselines line up, digits monospaced.
        gutterView.font = .monospacedDigitSystemFont(ofSize: font.pointSize, weight: .regular)
        gutterView.textColor = .tertiaryLabel
        gutterView.selectedLineTextColor = .secondaryLabel
        gutterView.highlightSelectedLine = highlightSelectedLine
        gutterView.insets = STRulerInsets(leading: 4, trailing: 10)
        gutterView.selectedLineHighlightColor = EditorTheme.currentLine
        gutterView.backgroundColor = EditorTheme.background
        gutterView.drawSeparator = false
        gutterView.minimumThickness = ceil(font.pointSize * 2.2)
        setNeedsLayout()
    }

    // MARK: Keyboard

    override var inputAccessoryView: UIView? {
        isEditable ? keyboardBar : nil
    }

    /// Keyboard frame in screen coordinates while it's up for this view.
    private var keyboardFrame: CGRect?

    @objc private func keyboardFrameWillChange(_ note: Notification) {
        let isHiding = note.name == UIResponder.keyboardWillHideNotification
        keyboardFrame = isHiding ? nil : note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        updateKeyboardInset(scrollToCaret: true)
    }

    /// Keeps the caret above the keyboard and its bar, which can overlap the editor's frame.
    /// Runs on every layout too, since the host may resize the editor as the keyboard moves.
    private func updateKeyboardInset(scrollToCaret: Bool) {
        var overlap: CGFloat = 0
        if let keyboardFrame, isFirstResponder, let window {
            let keyboardInWindow = window.convert(keyboardFrame, from: window.screen.coordinateSpace)
            overlap = max(0, convert(bounds, to: window).maxY - keyboardInWindow.minY)
        }
        guard abs(contentInset.bottom - overlap) > 0.5 else { return }
        contentInset.bottom = overlap
        verticalScrollIndicatorInsets.bottom = overlap
        if scrollToCaret, overlap > 0 { setNeedsCaretVisible() }
    }

    override func becomeFirstResponder() -> Bool {
        let became = super.becomeFirstResponder()
        if became {
            setCurrentLineHighlighted(true)
            keyboardBar.updateUndo(canUndo: undoManager?.canUndo ?? false)
            onFocusChange?(true)
        }
        return became
    }

    override func resignFirstResponder() -> Bool {
        let resigned = super.resignFirstResponder()
        if resigned {
            setCurrentLineHighlighted(false)
            onFocusChange?(false)
        }
        return resigned
    }

    /// The current line is highlighted only while editing, like Xcode's focused editor.
    private func setCurrentLineHighlighted(_ highlighted: Bool) {
        highlightSelectedLine = highlighted
        gutterView?.highlightSelectedLine = highlighted
        setNeedsLayout()
    }

    func textDidChange() {
        keyboardBar.updateUndo(canUndo: undoManager?.canUndo ?? false)
        setNeedsCaretVisible()
    }

    // MARK: Caret visibility

    private var needsCaretVisible = false
    private var lastBoundsHeight: CGFloat = 0

    /// Scrolls the caret into view after the next layout. STTextView's own scrolling uses
    /// estimated geometry near the end of long documents and can leave the caret off screen.
    private func setNeedsCaretVisible() {
        needsCaretVisible = true
        setNeedsLayout()
    }

    private func scrollCaretToVisibleIfNeeded() {
        guard needsCaretVisible, isFirstResponder,
              let caret = textLayoutManager.textSelections.last?.textRanges.last?.location
        else { return }
        needsCaretVisible = false
        textLayoutManager.ensureLayout(for: NSTextRange(location: caret))
        var rect: CGRect
        if caret.compare(textLayoutManager.documentRange.endLocation) == .orderedSame {
            // No text segment exists after the last character; the caret sits at the content's end.
            rect = CGRect(x: 0, y: contentSize.height - font.lineHeight - textContainerInset.bottom,
                          width: 1, height: font.lineHeight)
        } else if let frame = textLayoutManager.textSegmentFrame(at: caret, type: .standard) {
            rect = frame
            rect.origin.y += textContainerInset.top
        } else {
            return
        }
        rect.origin.x = 0
        rect.size.width = 1
        rect = rect.insetBy(dx: 0, dy: -font.lineHeight / 2)
        let visible = bounds.inset(by: adjustedContentInset)
        if rect.maxY > visible.maxY {
            contentOffset.y = rect.maxY - bounds.height + adjustedContentInset.bottom
        } else if rect.minY < visible.minY {
            contentOffset.y = max(-adjustedContentInset.top, rect.minY - adjustedContentInset.top)
        }
    }

    // MARK: Editing commands

    /// Types `text` as if from the keyboard, so pairing and indentation rules apply.
    func type(_ text: String) {
        insertText(text)
    }

    func performUndo() {
        undoManager?.undo()
        keyboardBar.updateUndo(canUndo: undoManager?.canUndo ?? false)
    }

    /// Adds one indent unit to the start of every line in the selection.
    func indentSelectedLines() {
        transformSelectedLines { Self.indentUnit + $0 }
    }

    /// Removes up to one indent unit (or a tab) from the start of every line in the selection.
    func outdentSelectedLines() {
        transformSelectedLines { line in
            if line.hasPrefix("\t") { return String(line.dropFirst()) }
            let spaces = line.prefix(while: { $0 == " " }).count
            return String(line.dropFirst(min(spaces, Self.indentUnit.count)))
        }
    }

    private func transformSelectedLines(_ transform: (String) -> String) {
        let string = (text ?? "") as NSString
        let selection = textSelection
        guard selection.location != NSNotFound else { return }
        let lineRange = string.lineRange(for: selection)
        let original = string.substring(with: lineRange)
        let endsWithNewline = original.hasSuffix("\n")
        var lines = original.components(separatedBy: "\n")
        if endsWithNewline { lines.removeLast() }
        let changed = lines.map(transform).joined(separator: "\n") + (endsWithNewline ? "\n" : "")
        guard changed != original else { return }

        // Keep the caret on the same character, or keep the same lines selected.
        let firstLineDelta = (transform(lines.first ?? "") as NSString).length - ((lines.first ?? "") as NSString).length
        breakUndoCoalescing()
        replaceCharacters(in: lineRange, with: changed)
        breakUndoCoalescing()
        if selection.length == 0 {
            let lineStart = lineRange.location
            let column = selection.location - lineStart
            textSelection = NSRange(location: lineStart + max(0, column + firstLineDelta), length: 0)
        } else {
            let length = (changed as NSString).length - (endsWithNewline ? 1 : 0)
            textSelection = NSRange(location: lineRange.location, length: max(0, length))
        }
        keyboardBar.updateUndo(canUndo: undoManager?.canUndo ?? false)
    }

    #if DEBUG
    /// Lets launch-argument checks type and select through the same path as the keyboard.
    private func installDebugHooks() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(debugType(_:)), name: .init("CodeEditorDebugType"), object: nil)
        center.addObserver(self, selector: #selector(debugSelect(_:)), name: .init("CodeEditorDebugSelect"), object: nil)
    }

    @objc private func debugType(_ note: Notification) {
        guard isFirstResponder, let text = note.userInfo?["text"] as? String else { return }
        for character in text.replacingOccurrences(of: "\\n", with: "\n") {
            insertText(String(character))
        }
    }

    @objc private func debugSelect(_ note: Notification) {
        let parts = (note.userInfo?["range"] as? String ?? "").split(separator: ",").compactMap { Int($0) }
        guard parts.count == 2 else { return }
        textSelection = NSRange(location: parts[0], length: parts[1])
        setNeedsCaretVisible()
    }
    #endif

    // MARK: Highlighted line

    override func layoutSubviews() {
        super.layoutSubviews()
        updateKeyboardInset(scrollToCaret: false)
        if bounds.height < lastBoundsHeight - 0.5 {
            // The keyboard took space: keep the caret on screen.
            needsCaretVisible = true
        }
        lastBoundsHeight = bounds.height
        scrollCaretToVisibleIfNeeded()
        layoutHighlightedLine()
    }

    private func layoutHighlightedLine() {
        guard let highlightedLine, let range = textRange(ofLine: highlightedLine),
              let fragment = textLayoutManager.textLayoutFragment(for: range.location)
        else {
            highlightedLineView.isHidden = true
            return
        }
        let frame = fragment.layoutFragmentFrame
        highlightedLineView.isHidden = false
        highlightedLineView.frame = CGRect(
            x: 0,
            y: textContainerInset.top + frame.minY,
            width: max(contentSize.width, bounds.width),
            height: frame.height
        )
        sendSubviewToBack(highlightedLineView)
    }

    private func textRange(ofLine line: Int) -> NSTextRange? {
        guard line >= 1, let string = text else { return nil }
        let ns = string as NSString
        var location = 0
        for _ in 1..<line {
            let next = ns.range(of: "\n", range: NSRange(location: location, length: ns.length - location))
            guard next.location != NSNotFound else { return nil }
            location = next.location + 1
        }
        guard location <= ns.length else { return nil }
        return NSTextRange(NSRange(location: location, length: 0), in: textContentManager)
    }

    private func scrollToLine(_ line: Int) {
        guard let range = textRange(ofLine: line) else { return }
        textLayoutManager.ensureLayout(for: range)
        scrollRangeToVisible(range)
    }
}
#endif
