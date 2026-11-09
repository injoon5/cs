import Foundation

/// What `tools/` recorded for a `predict` or `trace` block, found by `RecordedHash`.
public struct RecordedEntry: Sendable, Hashable {
    /// From `{"output": ...}`.
    public var output: String?
    /// True for `{"trace": ...}`.
    public var hasTrace: Bool

    public init(output: String? = nil, hasTrace: Bool = false) {
        self.output = output
        self.hasTrace = hasTrace
    }
}

/// Looks up a recorded entry by block hash.
public typealias RecordedLookup = (_ hash: String) -> RecordedEntry?

/// FNV-1a 64 of a block's normalized source (docs/contracts.md, "Recorded outputs").
/// `tools/` mirrors this in Python:
///
///     def normalize(src): return "\n".join(l.rstrip(" \t\r\x0b\x0c") for l in src.split("\n")).rstrip("\n")
///     def block_hash(src):
///         h = 0xcbf29ce484222325
///         for b in normalize(src).encode("utf-8"):
///             h = ((h ^ b) * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF
///         return format(h, "016x")
public enum RecordedHash {
    public static let offsetBasis: UInt64 = 0xcbf2_9ce4_8422_2325
    public static let prime: UInt64 = 0x100_0000_01b3

    /// FNV-1a 64 over raw bytes: xor each byte, then multiply, wrapping at 64 bits.
    public static func fnv1a64<S: Sequence>(_ bytes: S) -> UInt64 where S.Element == UInt8 {
        var hash = offsetBasis
        for byte in bytes {
            hash ^= UInt64(byte)
            hash = hash &* prime
        }
        return hash
    }

    /// UTF-8 bytes of `source` with trailing space, tab, CR, VT and FF removed from every line
    /// (lines split on LF only) and trailing newlines removed.
    public static func normalizedBytes(_ source: String) -> [UInt8] {
        let strip: Set<UInt8> = [0x20, 0x09, 0x0D, 0x0B, 0x0C]
        var lines: [[UInt8]] = [[]]
        for byte in source.utf8 {
            if byte == 0x0A {
                lines.append([])
            } else {
                lines[lines.count - 1].append(byte)
            }
        }
        var out: [UInt8] = []
        for (index, var line) in lines.enumerated() {
            while let last = line.last, strip.contains(last) { line.removeLast() }
            if index > 0 { out.append(0x0A) }
            out.append(contentsOf: line)
        }
        while out.last == 0x0A { out.removeLast() }
        return out
    }

    /// 16 lowercase hex digits.
    public static func hash(source: String) -> String {
        hex(fnv1a64(normalizedBytes(source)))
    }

    public static func hex(_ value: UInt64) -> String {
        let digits = String(value, radix: 16)
        return String(repeating: "0", count: max(0, 16 - digits.count)) + digits
    }

    /// `_recorded/<hash>.json`, relative to the content root.
    public static func relativePath(forHash hash: String) -> String {
        "_recorded/\(hash).json"
    }
}
