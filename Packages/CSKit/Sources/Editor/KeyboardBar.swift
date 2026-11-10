#if canImport(UIKit)
import SwiftUI
import UIKit

/// State the keyboard bar shows. Owned by `CodeTextView`.
@Observable
@MainActor
final class KeyboardBarModel {
    var canUndo = false
    var runControl: CodeEditorRunControl?
}

/// Input accessory bar above the keyboard: `:` `()` `[]` `{}`, outdent, indent, undo, Run.
///
/// Two glass groups and a Run button, like the system's own keyboard bars on iOS 26.
@MainActor
final class KeyboardBar: UIView {
    static let height: CGFloat = 56

    let model = KeyboardBarModel()
    private let host: UIHostingController<KeyboardBarContent>

    init(textView: CodeTextView) {
        host = UIHostingController(rootView: KeyboardBarContent(model: model, textView: textView))
        super.init(frame: CGRect(x: 0, y: 0, width: 390, height: Self.height))
        autoresizingMask = .flexibleWidth
        backgroundColor = .clear
        host.view.backgroundColor = .clear
        host.sizingOptions = []
        host.view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            host.view.topAnchor.constraint(equalTo: topAnchor),
            host.view.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: Self.height)
    }

    func update(runControl: CodeEditorRunControl?) {
        model.runControl = runControl
    }

    func updateUndo(canUndo: Bool) {
        if model.canUndo != canUndo { model.canUndo = canUndo }
    }
}

struct KeyboardBarContent: View {
    let model: KeyboardBarModel
    /// Weak: the text view owns the bar.
    weak var textView: CodeTextView?

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: 6) {
                HStack(spacing: 0) {
                    characterButton(":", label: "Colon")
                    characterButton("()", label: "Parentheses")
                    characterButton("[]", label: "Brackets")
                    characterButton("{}", label: "Braces")
                }
                .glassEffect(.regular.interactive(), in: .capsule)

                Spacer(minLength: 0)

                HStack(spacing: 0) {
                    symbolButton("decrease.indent", label: "Outdent") { $0.outdentSelectedLines() }
                    symbolButton("increase.indent", label: "Indent") { $0.indentSelectedLines() }
                    symbolButton("arrow.uturn.backward", label: "Undo") { $0.performUndo() }
                        .disabled(!model.canUndo)
                }
                .glassEffect(.regular.interactive(), in: .capsule)

                if let runControl = model.runControl {
                    runButton(runControl)
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(maxHeight: .infinity)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge) // the bar can't grow; keep every key on screen
        .tint(.primary)
    }

    private func runButton(_ runControl: CodeEditorRunControl) -> some View {
        Button {
            if runControl.isRunning {
                runControl.stop()
            } else {
                _ = textView?.resignFirstResponder()
                runControl.run()
            }
        } label: {
            Image(systemName: runControl.isRunning ? "stop.fill" : "play.fill")
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 30, height: 30)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.circle)
        .tint(.accentColor)
        .accessibilityLabel(runControl.isRunning ? "Stop" : "Run")
    }

    private func characterButton(_ text: String, label: String) -> some View {
        Button {
            // The opening character; the pairing rules add the closing one.
            textView?.type(String(text.prefix(1)))
        } label: {
            Text(verbatim: text)
                .font(.system(.body, design: .monospaced).weight(.medium))
                .frame(width: 44, height: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func symbolButton(_ symbol: String, label: String, action: @escaping (CodeTextView) -> Void) -> some View {
        Button {
            if let textView { action(textView) }
        } label: {
            Image(systemName: symbol)
                .font(.body)
                .frame(width: 44, height: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
#endif
