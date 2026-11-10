#if canImport(UIKit)
import SwiftUI
import UIKit
import VisualsLayout

extension LayoutMetrics {
    /// Metrics that match the fonts `SceneView` draws with at a Dynamic Type size:
    /// values in SF Mono body, labels in SF Mono caption.
    public static func system(_ dynamicTypeSize: DynamicTypeSize) -> LayoutMetrics {
        let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(dynamicTypeSize))
        let valueSize = Double(UIFont.preferredFont(forTextStyle: .body, compatibleWith: traits).pointSize)
        let labelSize = Double(UIFont.preferredFont(forTextStyle: .caption1, compatibleWith: traits).pointSize)
        let valueLine = Double(UIFont.monospacedSystemFont(ofSize: valueSize, weight: .regular).lineHeight)
        let labelLine = Double(UIFont.monospacedSystemFont(ofSize: labelSize, weight: .semibold).lineHeight)
        return LayoutMetrics(
            measureValue: { textWidth($0, size: valueSize, weight: .regular) },
            measureLabel: { textWidth($0, size: labelSize, weight: .semibold) },
            valueLineHeight: valueLine.rounded(.up),
            labelLineHeight: labelLine.rounded(.up)
        )
    }
}

/// Safe off the main thread: fonts and attributed-string measurement are thread-safe.
private func textWidth(_ text: String, size: Double, weight: UIFont.Weight) -> Double {
    let font = UIFont.monospacedSystemFont(ofSize: size, weight: weight)
    return Double(NSAttributedString(string: text, attributes: [.font: font]).size().width)
}

/// Fonts paired with `LayoutMetrics.system`.
enum SceneFont {
    static let value = Font.system(.body, design: .monospaced)
    static let label = Font.system(.caption, design: .monospaced).weight(.semibold)
    static let secondaryLabel = Font.system(.caption, design: .monospaced)
    static let index = Font.caption2.monospacedDigit()
}

/// SF Mono at subheadline size, matching the editor and console.
enum CodeFont {
    static let text = Font.system(.subheadline, design: .monospaced)

    /// Height of one code line at a Dynamic Type size: the font's line height plus room for
    /// the current-line tint above and below the glyphs.
    static func lineHeight(_ dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(dynamicTypeSize))
        let size = UIFont.preferredFont(forTextStyle: .subheadline, compatibleWith: traits).pointSize
        return UIFont.monospacedSystemFont(ofSize: size, weight: .regular).lineHeight.rounded(.up) + 4
    }
}

extension LayoutPoint {
    var cgPoint: CGPoint { CGPoint(x: x, y: y) }
}

extension LayoutSize {
    var cgSize: CGSize { CGSize(width: width, height: height) }
}

extension LayoutRect {
    var cgRect: CGRect { CGRect(x: x, y: y, width: width, height: height) }
}
#endif
