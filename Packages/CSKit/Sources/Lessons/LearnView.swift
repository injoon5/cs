#if canImport(UIKit)
import Contracts
import Exercises
import SwiftUI

/// The Learn tab: tracks, units and lessons, and the lesson reader.
public struct LearnView: View {
    let library: ContentLibrary
    let runner: any PythonRunning
    let progress: any ProgressRecording

    @State private var path: [LearnRoute] = LessonsLaunchOptions.initialPath

    public init(library: ContentLibrary, runner: any PythonRunning, progress: any ProgressRecording) {
        self.library = library
        self.runner = runner
        self.progress = progress
    }

    public var body: some View {
        let index = LibraryIndex(library: library)
        NavigationStack(path: $path) {
            TrackListView(index: index, progress: progress)
                .navigationTitle("Learn")
                .navigationDestination(for: LearnRoute.self) { route in
                    destination(route, index: index)
                }
        }
    }

    @ViewBuilder
    private func destination(_ route: LearnRoute, index: LibraryIndex) -> some View {
        switch route {
        case .unit(let id):
            if let unit = index.unit(id) {
                UnitView(unit: unit, progress: progress)
            } else {
                missing
            }
        case .lesson(let unitID, let lessonID):
            if let lesson = index.lesson(lessonID, in: unitID) {
                LessonReader(
                    lesson: lesson,
                    unitID: unitID,
                    nextLesson: index.lesson(after: lessonID, in: unitID),
                    library: library,
                    runner: runner,
                    progress: progress,
                    openNext: { next in openNext(next, unitID: unitID) }
                )
                .id(lessonID)
            } else {
                missing
            }
        case .exercise(let id):
            if let exercise = library.exercise(id: id) {
                ExerciseView(exercise: exercise, runner: runner, progress: progress)
            } else {
                missing
            }
        }
    }

    /// Replaces the finished lesson with the next one, so Back still goes to the unit.
    private func openNext(_ lesson: Lesson, unitID: String) {
        guard !path.isEmpty else { return }
        path[path.count - 1] = .lesson(unitID: unitID, lessonID: lesson.id)
    }

    private var missing: some View {
        ContentUnavailableView("Not found", systemImage: "questionmark.folder")
    }
}

/// Tracks as sections, units as rows, with a suggested next lesson on top.
private struct TrackListView: View {
    let index: LibraryIndex
    let progress: any ProgressRecording

    var body: some View {
        if index.isEmpty {
            ContentUnavailableView("No lessons", systemImage: "book")
        } else {
            List {
                if let next = NextLessonSuggestion.suggest(in: index.library.tracks, progress: progress) {
                    Section("Up next") {
                        NavigationLink(value: LearnRoute.lesson(unitID: next.unit.id, lessonID: next.lesson.id)) {
                            UpNextRow(unit: next.unit, lesson: next.lesson)
                        }
                    }
                }
                ForEach(index.library.tracks) { track in
                    if !track.units.isEmpty {
                        Section(track.title) {
                            ForEach(track.units) { unit in
                                NavigationLink(value: LearnRoute.unit(unit.id)) {
                                    UnitRow(unit: unit, progress: progress)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}

private struct UpNextRow: View {
    let unit: CourseUnit
    let lesson: Lesson

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(lesson.title)
            Text(unit.title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

private struct UnitRow: View {
    let unit: CourseUnit
    let progress: any ProgressRecording

    var body: some View {
        let done = unit.lessons.filter { progress.lessonProgress($0.id).state == .completed }.count
        LabeledContent {
            Text("\(done)/\(unit.lessons.count)")
                .monospacedDigit()
                .accessibilityLabel("\(done) of \(unit.lessons.count) lessons done")
        } label: {
            Text(unit.title)
        }
    }
}
#endif
