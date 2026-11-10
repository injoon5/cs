#if DEBUG && canImport(UIKit)
import Contracts
import Foundation
import UIKit

/// Launch arguments for screenshots without UI automation (use with `-RootTab practice`):
///
///     -ExercisesSeed 1            mark some exercises passed or attempted (InMemoryProgress only)
///     -ExerciseOpen <id>          open an exercise at launch
///     -ExerciseCode <code>        start with this code: `starter`, `solution`, or literal text (\\n for newline)
///     -ExerciseFocus 1            focus the editor (keyboard up)
///     -ExerciseRun 1              run the tests
///     -ExerciseHints <n>          reveal n hints and open the hints sheet
///     -ExerciseSolution 1         also show the solution in the hints sheet
///     -ExercisesAppearance dark   force light or dark for this app only
///     -ExercisesCapture <path>    write a PNG of the window to path after -ExercisesCaptureDelay seconds
@MainActor
enum ExercisesLaunchOptions {
    private static var defaults: UserDefaults { .standard }

    /// Seeds progress and returns the exercise to open.
    static func prepare(progress: any ProgressRecording, library: ContentLibrary) -> String? {
        applyAppearance()
        scheduleCapture()
        if defaults.bool(forKey: "ExercisesSeed"), let memory = progress as? InMemoryProgress {
            seed(memory, library: library)
        }
        guard let id = defaults.string(forKey: "ExerciseOpen") else { return nil }
        let hints = defaults.integer(forKey: "ExerciseHints")
        if hints > 0 { progress.recordHintsRevealed(hints, exerciseID: id) }
        if defaults.bool(forKey: "ExerciseSolution") { progress.recordSolutionViewed(exerciseID: id) }
        return id
    }

    static func code(for exercise: Exercise) -> String? {
        guard defaults.string(forKey: "ExerciseOpen") == exercise.id,
              let code = defaults.string(forKey: "ExerciseCode")
        else { return nil }
        switch code {
        case "starter": return exercise.starter
        case "solution": return exercise.solution
        default: return code.replacingOccurrences(of: "\\n", with: "\n")
        }
    }

    static func drive(focus: () -> Void, run: () -> Void, showHints: () -> Void) async {
        guard defaults.string(forKey: "ExerciseOpen") != nil else { return }
        try? await Task.sleep(for: .milliseconds(700))
        if defaults.bool(forKey: "ExerciseFocus") { focus() }
        if defaults.bool(forKey: "ExerciseRun") { run() }
        if defaults.integer(forKey: "ExerciseHints") > 0 || defaults.bool(forKey: "ExerciseSolution") { showHints() }
    }

    private static var windows: [UIWindow] {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
    }

    /// The simulator's appearance is shared with other apps; pin this app's instead.
    private static func applyAppearance() {
        let style: UIUserInterfaceStyle
        switch defaults.string(forKey: "ExercisesAppearance") {
        case "dark": style = .dark
        case "light": style = .light
        default: return
        }
        for window in windows { window.overrideUserInterfaceStyle = style }
    }

    /// Draws the app's window into a PNG after a delay, so screenshots don't depend on which
    /// app is in front of the shared simulator. The keyboard is a separate process and isn't drawn.
    private static func scheduleCapture() {
        guard let path = defaults.string(forKey: "ExercisesCapture") else { return }
        let delay = max(defaults.double(forKey: "ExercisesCaptureDelay"), 1)
        Task {
            try? await Task.sleep(for: .seconds(delay))
            // Draw only after being in front for a moment; background windows draw blank.
            var activeSince: ContinuousClock.Instant?
            while true {
                if UIApplication.shared.applicationState == .active {
                    let since = activeSince ?? .now
                    activeSince = since
                    if ContinuousClock.now - since > .seconds(1.2) { break }
                } else {
                    activeSince = nil
                }
                try? await Task.sleep(for: .milliseconds(200))
            }
            guard let window = windows.first(where: \.isKeyWindow) ?? windows.first else { return }
            let format = UIGraphicsImageRendererFormat(for: window.traitCollection)
            let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
                window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            }
            try? image.pngData()?.write(to: URL(filePath: path))
        }
    }

    /// First unit: first two passed, third attempted. Second unit: one passed, one attempted.
    private static func seed(_ progress: InMemoryProgress, library: ContentLibrary) {
        let units = library.tracks.flatMap(\.units).filter { !$0.exercises.isEmpty }
        let pattern: [[ExerciseState]] = [[.passed, .passed, .attempted], [.attempted, .notStarted, .passed]]
        for (unit, states) in zip(units, pattern) {
            for (exercise, state) in zip(unit.exercises, states) where state != .notStarted {
                progress.exercises[exercise.id] = ExerciseProgress(state: state)
            }
        }
    }
}
#endif
