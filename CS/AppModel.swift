import Content
import Contracts
import Foundation

/// App-wide objects, created once at launch.
@MainActor
final class AppModel {
    let library: ContentLibrary
    let loadError: String?
    // Replaced by the SwiftData store when it lands.
    let progress: any ProgressRecording = InMemoryProgress()

    init() {
        let root = Bundle.main.bundleURL.appending(path: "content")
        do {
            library = try ContentLibrary.load(root: root)
            loadError = nil
        } catch {
            library = ContentLibrary(tracks: [], root: root)
            loadError = String(describing: error)
        }
    }
}
