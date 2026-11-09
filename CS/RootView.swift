import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            Tab("Learn", systemImage: "book") {
                PlaceholderScreen(title: "Learn", symbol: "book")
            }
            Tab("Practice", systemImage: "checklist") {
                PlaceholderScreen(title: "Practice", symbol: "checklist")
            }
            Tab("Playground", systemImage: "chevron.left.forwardslash.chevron.right") {
                PlaceholderScreen(title: "Playground", symbol: "chevron.left.forwardslash.chevron.right")
            }
            Tab("Review", systemImage: "rectangle.stack") {
                PlaceholderScreen(title: "Review", symbol: "rectangle.stack")
            }
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
