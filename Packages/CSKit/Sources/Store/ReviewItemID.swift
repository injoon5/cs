import Foundation
import Review

/// Review item ids. Cards use their own id (`<unit>/<slug>`). Exercise items are prefixed,
/// so one exercise can be both a re-solve and an interleaved item with separate schedules.
public enum ReviewItemID {
    static let resolvePrefix = "resolve:"
    static let interleavedPrefix = "interleaved:"

    public static func resolve(exerciseID: String) -> String { resolvePrefix + exerciseID }
    public static func interleaved(exerciseID: String) -> String { interleavedPrefix + exerciseID }

    public static func kind(of itemID: String) -> ReviewItemKind {
        if itemID.hasPrefix(resolvePrefix) { return .resolve }
        if itemID.hasPrefix(interleavedPrefix) { return .interleaved }
        return .card
    }

    /// The exercise id behind a re-solve or interleaved item, nil for cards.
    public static func exerciseID(of itemID: String) -> String? {
        switch kind(of: itemID) {
        case .card: nil
        case .resolve: String(itemID.dropFirst(resolvePrefix.count))
        case .interleaved: String(itemID.dropFirst(interleavedPrefix.count))
        }
    }
}
