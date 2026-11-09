import Foundation

/// Text measurement and spacing, supplied by the caller so layout stays Foundation-only.
/// The SwiftUI side builds this from the current Dynamic Type size; tests use `.monospaced()`.
public struct LayoutMetrics: Sendable {
    /// Width of a value in the value font (SF Mono, body).
    public var measureValue: @Sendable (String) -> Double
    /// Width of a label in the label font (SF Mono, caption).
    public var measureLabel: @Sendable (String) -> Double
    public var valueLineHeight: Double
    public var labelLineHeight: Double

    /// Inside a cell, around the value.
    public var cellPadding: Double
    /// Between neighboring cells.
    public var cellSpacing: Double
    /// Between a row of cells and its labels (pointers, indices).
    public var labelSpacing: Double
    /// Between shapes stacked in one scene.
    public var shapeSpacing: Double
    /// Height of the caret under a pointer name.
    public var caretHeight: Double
    /// Horizontal gap between sibling tree nodes and between graph layers' nodes.
    public var nodeSpacing: Double
    /// Vertical gap between tree levels and graph layers.
    public var levelSpacing: Double
    /// Length of a linked list `next` arrow.
    public var linkLength: Double

    public init(
        measureValue: @escaping @Sendable (String) -> Double,
        measureLabel: @escaping @Sendable (String) -> Double,
        valueLineHeight: Double,
        labelLineHeight: Double,
        cellPadding: Double? = nil,
        cellSpacing: Double = 4,
        labelSpacing: Double = 4,
        shapeSpacing: Double = 24,
        caretHeight: Double? = nil,
        nodeSpacing: Double = 12,
        levelSpacing: Double? = nil,
        linkLength: Double = 24
    ) {
        self.measureValue = measureValue
        self.measureLabel = measureLabel
        self.valueLineHeight = valueLineHeight
        self.labelLineHeight = labelLineHeight
        self.cellPadding = cellPadding ?? (valueLineHeight * 0.3).rounded()
        self.cellSpacing = cellSpacing
        self.labelSpacing = labelSpacing
        self.shapeSpacing = shapeSpacing
        self.caretHeight = caretHeight ?? (labelLineHeight * 0.5).rounded()
        self.nodeSpacing = nodeSpacing
        self.levelSpacing = levelSpacing ?? (valueLineHeight * 1.1).rounded()
        self.linkLength = linkLength
    }

    /// Fixed advance per character. Good enough for SF Mono and for tests.
    public static func monospaced(valueAdvance: Double = 10.3, valueLineHeight: Double = 22, labelAdvance: Double = 7.2, labelLineHeight: Double = 16) -> LayoutMetrics {
        LayoutMetrics(
            measureValue: { Double($0.count) * valueAdvance },
            measureLabel: { Double($0.count) * labelAdvance },
            valueLineHeight: valueLineHeight,
            labelLineHeight: labelLineHeight
        )
    }

    /// Height of a cell; also the minimum cell width so short values make square cells.
    public var cellHeight: Double { (valueLineHeight + 2 * cellPadding).rounded() }

    /// Height of one pointer row: the name plus its caret.
    var pointerRowHeight: Double { labelLineHeight + caretHeight }
}

/// Caches measurements for one layout run. Not shared across threads.
final class TextMeasurer {
    private let metrics: LayoutMetrics
    private var values: [String: Double] = [:]
    private var labels: [String: Double] = [:]

    init(_ metrics: LayoutMetrics) {
        self.metrics = metrics
    }

    func value(_ text: String) -> Double {
        if let cached = values[text] { return cached }
        let width = metrics.measureValue(text).rounded(.up)
        values[text] = width
        return width
    }

    func label(_ text: String) -> Double {
        if let cached = labels[text] { return cached }
        let width = metrics.measureLabel(text).rounded(.up)
        labels[text] = width
        return width
    }

    /// Width of a cell that fits every value in `texts`.
    func cellWidth<S: Sequence>(fitting texts: S) -> Double where S.Element == String {
        var widest = 0.0
        for text in texts { widest = max(widest, value(text)) }
        return max(metrics.cellHeight, widest + 2 * metrics.cellPadding)
    }
}

/// Formats each element id once per run instead of once per frame, so a 1,000-frame run
/// shares one string per element rather than allocating one per element per frame.
struct IndexedIDs {
    private let prefix: String
    private var cache: [String] = []

    init(_ prefix: String) {
        self.prefix = prefix
    }

    mutating func callAsFunction(_ index: Int) -> String {
        guard index >= 0 else { return prefix + String(index) }
        while cache.count <= index { cache.append(prefix + String(cache.count)) }
        return cache[index]
    }
}

struct KeyedIDs {
    private let prefix: String
    private var cache: [String: String] = [:]

    init(_ prefix: String) {
        self.prefix = prefix
    }

    mutating func callAsFunction(_ key: String) -> String {
        if let cached = cache[key] { return cached }
        let id = prefix + key
        cache[key] = id
        return id
    }
}
