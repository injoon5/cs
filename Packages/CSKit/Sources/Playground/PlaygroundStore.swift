import Foundation
import Observation

/// A saved Playground file: a plain `.py` file in Documents/Playground.
struct PlaygroundFile: Identifiable, Hashable, Sendable {
    var url: URL
    var modified: Date
    /// First non-empty line, for the list.
    var preview: String

    var id: URL { url }
    /// File name without `.py`.
    var name: String { url.deletingPathExtension().lastPathComponent }
}

/// Lists, creates, renames, deletes, reads and writes Playground files.
@Observable
@MainActor
final class PlaygroundStore {
    static let fileExtension = "py"

    let directory: URL
    private(set) var files: [PlaygroundFile] = []

    private var fileManager: FileManager { .default }

    init(directory: URL? = nil) {
        self.directory = directory ?? URL.documentsDirectory.appending(path: "Playground", directoryHint: .isDirectory)
    }

    func reload() {
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let keys: [URLResourceKey] = [.contentModificationDateKey]
        let urls = (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: keys, options: .skipsHiddenFiles)) ?? []
        files = urls
            .filter { $0.pathExtension == Self.fileExtension }
            .map { url in
                let modified = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return PlaygroundFile(url: url, modified: modified, preview: Self.preview(of: url))
            }
            .sorted { $0.modified > $1.modified }
    }

    func file(at url: URL) -> PlaygroundFile? {
        files.first { $0.url == url }
    }

    /// Creates an empty file named "Untitled", "Untitled 2", ...
    @discardableResult
    func create(named base: String = "Untitled", contents: String = "") -> PlaygroundFile? {
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = uniqueURL(for: base)
        guard (try? contents.write(to: url, atomically: true, encoding: .utf8)) != nil else { return nil }
        reload()
        return file(at: url)
    }

    /// Renames a file. Returns the renamed file, or the original when the name is empty or unchanged.
    @discardableResult
    func rename(_ file: PlaygroundFile, to newName: String) -> PlaygroundFile {
        let name = Self.sanitized(newName)
        guard !name.isEmpty, name != file.name else { return file }
        let url = uniqueURL(for: name)
        guard (try? fileManager.moveItem(at: file.url, to: url)) != nil else { return file }
        reload()
        return self.file(at: url) ?? file
    }

    func delete(_ file: PlaygroundFile) {
        try? fileManager.removeItem(at: file.url)
        files.removeAll { $0.url == file.url }
    }

    func read(_ file: PlaygroundFile) -> String {
        (try? String(contentsOf: file.url, encoding: .utf8)) ?? ""
    }

    func write(_ text: String, to url: URL) {
        guard (try? text.write(to: url, atomically: true, encoding: .utf8)) != nil else { return }
        if let index = files.firstIndex(where: { $0.url == url }) {
            files[index].modified = .now
            files[index].preview = Self.preview(of: text)
        }
    }

    private func uniqueURL(for base: String) -> URL {
        var candidate = base
        var number = 2
        while fileManager.fileExists(atPath: url(for: candidate).path(percentEncoded: false)) {
            candidate = "\(base) \(number)"
            number += 1
        }
        return url(for: candidate)
    }

    private func url(for name: String) -> URL {
        directory.appending(path: name).appendingPathExtension(Self.fileExtension)
    }

    /// Drops characters that can't be in a file name and a trailing `.py`.
    static func sanitized(_ name: String) -> String {
        var name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        if name.lowercased().hasSuffix(".\(fileExtension)") {
            name = String(name.dropLast(fileExtension.count + 1))
        }
        while name.hasPrefix(".") { name.removeFirst() }
        return name
    }

    private static func preview(of url: URL) -> String {
        preview(of: (try? String(contentsOf: url, encoding: .utf8)) ?? "")
    }

    private static func preview(of text: String) -> String {
        text.split(whereSeparator: \.isNewline)
            .lazy
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first { !$0.isEmpty } ?? ""
    }
}
