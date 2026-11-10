import Contracts
import Foundation

extension ContentLibrary {
    /// Loads every track under `root`. Throws the first content error.
    public static func load(root: URL) throws -> ContentLibrary {
        ContentLibrary(tracks: try ContentLoader.load(root: root), root: root)
    }
}
