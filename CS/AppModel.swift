import Content
import Contracts
import Foundation
import Store
import SwiftData

/// App-wide objects, created once at launch.
@MainActor
final class AppModel {
    let library: ContentLibrary
    let loadError: String?
    let container: ModelContainer?
    let store: SwiftDataProgress?
    /// The SwiftData store, or in-memory progress if the store can't open.
    let progress: any ProgressRecording

    init() {
        let root = Bundle.main.bundleURL.appending(path: "content")
        do {
            library = try ContentLibrary.load(root: root)
            loadError = nil
        } catch {
            library = ContentLibrary(tracks: [], root: root)
            loadError = String(describing: error)
        }

        if let container = try? StoreContainer.make(inMemory: false) {
            let store = SwiftDataProgress(context: container.mainContext)
            self.container = container
            self.store = store
            progress = store
        } else {
            container = nil
            store = nil
            progress = InMemoryProgress()
        }
    }

    /// Saves code typed in the last second, before the app is suspended.
    func flush() {
        store?.flush()
    }
}
