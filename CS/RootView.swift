import Playground
import Runtime
import SwiftUI

struct RootView: View {
    /// `-RootTab playground` picks the tab at launch, for checks without UI automation.
    @State private var tab = UserDefaults.standard.string(forKey: "RootTab") ?? Self.firstTab

    #if DEBUG
    private static let firstTab = "python"
    #else
    private static let firstTab = "learn"
    #endif

    var body: some View {
        TabView(selection: $tab) {
            #if DEBUG
            Tab("Python", systemImage: "ladybug", value: "python") {
                PythonSmokeView()
            }
            #endif
            Tab("Learn", systemImage: "book", value: "learn") {
                PlaceholderScreen(title: "Learn", symbol: "book")
            }
            Tab("Practice", systemImage: "checklist", value: "practice") {
                PlaceholderScreen(title: "Practice", symbol: "checklist")
            }
            Tab("Playground", systemImage: "chevron.left.forwardslash.chevron.right", value: "playground") {
                PlaygroundView(runner: PythonRuntime.shared)
            }
            Tab("Review", systemImage: "rectangle.stack", value: "review") {
                PlaceholderScreen(title: "Review", symbol: "rectangle.stack")
            }
        }
        .task {
            // Start the interpreter early so the first run doesn't pay for it.
            await PythonRuntime.shared.start()
            #if DEBUG
            await PythonSelfCheck.runIfRequested()
            #endif
        }
    }
}

/// Stands in for each tab until its area lands.
private struct PlaceholderScreen: View {
    let title: String
    let symbol: String

    var body: some View {
        NavigationStack {
            ContentUnavailableView("Nothing here yet", systemImage: symbol)
                .navigationTitle(title)
        }
    }
}

#Preview {
    RootView()
}
