#if canImport(UIKit)
import Contracts
import SwiftUI

/// The Playground tab: saved files and a screen to edit and run each one.
public struct PlaygroundView: View {
    private let runner: any PythonRunning
    @State private var store: PlaygroundStore
    @State private var path: [URL] = []
    @State private var renaming: PlaygroundFile?
    @State private var newName = ""

    /// - Parameters:
    ///   - runner: Runs the code. The app passes `PythonRuntime.shared`.
    ///   - directory: Folder of `.py` files. Defaults to Documents/Playground.
    public init(runner: any PythonRunning, directory: URL? = nil) {
        self.runner = runner
        _store = State(initialValue: PlaygroundStore(directory: directory))
    }

    public var body: some View {
        NavigationStack(path: $path) {
            list
                .navigationTitle("Playground")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("New file", systemImage: "plus", action: createFile)
                    }
                }
                .navigationDestination(for: URL.self) { url in
                    if let file = store.file(at: url) {
                        PlaygroundFileView(file: file, store: store, runner: runner)
                    }
                }
        }
        .alert("Rename", isPresented: isRenaming) {
            TextField("Name", text: $newName)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button("Cancel", role: .cancel) {}
            Button("Rename") {
                if let renaming { store.rename(renaming, to: newName) }
            }
        }
        .task {
            store.reload()
            #if DEBUG
            if let url = PlaygroundLaunchOptions.prepare(store) { path = [url] }
            #endif
        }
    }

    @ViewBuilder
    private var list: some View {
        if store.files.isEmpty {
            ContentUnavailableView {
                Label("No files", systemImage: "doc.text")
            } actions: {
                Button("New file", action: createFile)
            }
        } else {
            List {
                ForEach(store.files) { file in
                    NavigationLink(value: file.url) {
                        FileRow(file: file)
                    }
                    .swipeActions {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            withAnimation { store.delete(file) }
                        }
                        Button("Rename", systemImage: "pencil") { startRename(file) }
                            .tint(.orange)
                    }
                    .contextMenu {
                        Button("Rename", systemImage: "pencil") { startRename(file) }
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            withAnimation { store.delete(file) }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    private var isRenaming: Binding<Bool> {
        Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })
    }

    private func startRename(_ file: PlaygroundFile) {
        newName = file.name
        renaming = file
    }

    private func createFile() {
        guard let file = store.create() else { return }
        path = [file.url]
    }
}

private struct FileRow: View {
    let file: PlaygroundFile

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(file.name)
                .font(.body)
                .lineLimit(1)
            HStack(spacing: 6) {
                Text(dateText)
                    .monospacedDigit()
                if !file.preview.isEmpty {
                    Text(verbatim: file.preview)
                        .lineLimit(1)
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    /// Like Notes: the time for today, the date otherwise.
    private var dateText: String {
        Calendar.current.isDateInToday(file.modified)
            ? file.modified.formatted(date: .omitted, time: .shortened)
            : file.modified.formatted(date: .numeric, time: .omitted)
    }
}
#endif
