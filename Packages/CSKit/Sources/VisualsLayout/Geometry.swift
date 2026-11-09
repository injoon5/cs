import Foundation

// Plain geometry values so this target stays Foundation-only and builds on Linux.
// Views convert to CGPoint/CGSize at the edge.

public struct LayoutPoint: Sendable, Hashable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public static let zero = LayoutPoint(x: 0, y: 0)

    public func offsetBy(dx: Double, dy: Double) -> LayoutPoint {
        LayoutPoint(x: x + dx, y: y + dy)
    }

    func distance(to other: LayoutPoint) -> Double {
        ((other.x - x) * (other.x - x) + (other.y - y) * (other.y - y)).squareRoot()
    }
}

public struct LayoutSize: Sendable, Hashable {
    public var width: Double
    public var height: Double

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }

    public static let zero = LayoutSize(width: 0, height: 0)
}

public struct LayoutRect: Sendable, Hashable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public init(center: LayoutPoint, size: LayoutSize) {
        self.init(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height)
    }

    public var minX: Double { x }
    public var minY: Double { y }
    public var maxX: Double { x + width }
    public var maxY: Double { y + height }
    public var midX: Double { x + width / 2 }
    public var midY: Double { y + height / 2 }
    public var center: LayoutPoint { LayoutPoint(x: midX, y: midY) }
    public var size: LayoutSize { LayoutSize(width: width, height: height) }

    public func offsetBy(dx: Double, dy: Double) -> LayoutRect {
        LayoutRect(x: x + dx, y: y + dy, width: width, height: height)
    }

    public func insetBy(dx: Double, dy: Double) -> LayoutRect {
        LayoutRect(x: x + dx, y: y + dy, width: width - 2 * dx, height: height - 2 * dy)
    }

    public func intersects(_ other: LayoutRect) -> Bool {
        minX < other.maxX && other.minX < maxX && minY < other.maxY && other.minY < maxY
    }
}
