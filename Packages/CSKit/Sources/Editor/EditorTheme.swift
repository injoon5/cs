#if canImport(UIKit)
import STPluginNeon
import UIKit

/// Xcode's default light and dark source editor colors, keyed by tree-sitter-python capture names
/// (`highlights.scm` in STTextView-Plugin-Neon).
///
/// Captures are applied in order (shallow to deep, then by pattern), so a later capture wins.
/// `variable` and `operator` have no entry on purpose: a token without a color keeps the color
/// of the capture before it, so `def name`, `Constructor` and `CONSTANT` keep their colors under
/// the catch-all `(identifier) @variable`, and plain identifiers keep the text color.
@MainActor
enum EditorTheme {
    static func neonTheme(font: UIFont) -> Theme {
        let bold = font.withWeight(.semibold)
        var colors: [String: UIColor] = [:]
        var fonts: [String: UIFont] = [:]
        for (capture, style) in styles {
            colors[capture] = style.color
            fonts[capture] = style.isBold ? bold : font
        }
        return Theme(colors: Theme.Colors(colors: colors), fonts: Theme.Fonts(fonts: fonts))
    }

    /// Text editor background. Matches the grouped and plain backgrounds of the system.
    static let background = UIColor.systemBackground

    /// Xcode "Current Line" highlight.
    static let currentLine = UIColor(light: 0xE8F2FF, dark: 0x23252B)

    /// Background of a line called out by the host, such as the line that raised an error.
    static let highlightedLine = UIColor.systemRed.withAlphaComponent(0.16)

    private struct Style {
        var color: UIColor
        var isBold = false
    }

    // Xcode 16 "Default (Light)" / "Default (Dark)".
    private static let keyword = UIColor(light: 0x9B2393, dark: 0xFC5FA3)
    private static let string = UIColor(light: 0xC41A16, dark: 0xFC6A5D)
    private static let number = UIColor(light: 0x1C00CF, dark: 0xD0BF69)
    private static let comment = UIColor(light: 0x5D6C79, dark: 0x6C7986)
    private static let otherFunction = UIColor(light: 0x6C36A9, dark: 0xA167E6)
    private static let otherType = UIColor(light: 0x3900A0, dark: 0xD0A8FF)
    private static let projectFunction = UIColor(light: 0x326D74, dark: 0x67B7A4)
    private static let projectType = UIColor(light: 0x1C464A, dark: 0x9EF1DD)

    private static let styles: [String: Style] = [
        "keyword": Style(color: keyword, isBold: true),
        "constant.builtin": Style(color: keyword, isBold: true), // None, True, False
        "string": Style(color: string),
        "punctuation.special": Style(color: string), // `{` `}` around f-string fields
        "embedded": Style(color: .label), // f-string field contents
        "escape": Style(color: number),
        "number": Style(color: number),
        "comment": Style(color: comment),
        "function.builtin": Style(color: otherFunction),
        "function.method": Style(color: otherFunction),
        "function": Style(color: projectFunction), // definitions, calls, decorators
        "property": Style(color: projectFunction),
        "constant": Style(color: projectFunction),
        "constructor": Style(color: projectType),
        "type": Style(color: otherType),
    ]
}

extension UIColor {
    convenience init(light: UInt32, dark: UInt32) {
        self.init { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
        }
    }

    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension UIFont {
    /// SF Mono at the subheadline text style's size for the current Dynamic Type setting.
    /// Body size wraps ordinary nested loops on the smallest iPhone.
    static func editorFont(compatibleWith traits: UITraitCollection? = nil) -> UIFont {
        let size = UIFont.preferredFont(forTextStyle: .subheadline, compatibleWith: traits).pointSize
        return .monospacedSystemFont(ofSize: size, weight: .regular)
    }

    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        .monospacedSystemFont(ofSize: pointSize, weight: weight)
    }
}
#endif
