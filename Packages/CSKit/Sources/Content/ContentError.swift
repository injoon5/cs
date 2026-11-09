import Foundation

/// A problem in a content file. `path` is relative to the content root (empty when the
/// parser was given a bare string); `line` is 1-based in that file.
public struct ContentError: Error, Sendable, Hashable, CustomStringConvertible {
    public var path: String
    public var line: Int?
    public var message: String

    public init(path: String = "", line: Int? = nil, message: String) {
        self.path = path
        self.line = line
        self.message = message
    }

    /// `path:line: message`, like a compiler diagnostic.
    public var description: String {
        var prefix = path
        if let line {
            prefix += prefix.isEmpty ? "line \(line)" : ":\(line)"
        }
        return prefix.isEmpty ? message : "\(prefix): \(message)"
    }

    /// Re-anchors an error from a nested parser: sets the path and shifts the line.
    func located(in path: String, lineOffset: Int = 0) -> ContentError {
        var copy = self
        copy.path = path
        if let line { copy.line = line + lineOffset }
        return copy
    }
}
