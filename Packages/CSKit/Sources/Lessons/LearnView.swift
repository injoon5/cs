#if canImport(UIKit)
import Contracts
import SwiftUI

// Public API used by the app. Stub until the Lessons agent implements it; keep the signature.

/// The Learn tab: tracks, units and lessons, and the lesson reader.
public struct LearnView: View {
    let library: ContentLibrary
    let runner: any PythonRunning
    let progress: any ProgressRecording

    public init(library: ContentLibrary, runner: any PythonRunning, progress: any ProgressRecording) {
        self.library = library
        self.runner = runner
        self.progress = progress
    }

    public var body: some View {
        EmptyView()
    }
}
#endif
