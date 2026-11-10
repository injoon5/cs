#if canImport(UIKit)
import Contracts
import SwiftUI

/// Launch arguments for screenshots without UI automation (DEBUG builds only):
///
///     -LessonsOpen complexity                  open a unit
///     -LessonsOpen complexity/counting-steps   open a lesson
///     -LessonsStep 3                           show steps 1...3 (1-based)
///     -LessonsAnswer right|wrong               answer the last step's questions and check
///     -LessonsRunCells YES                     run every cell on screen
///     -LessonsFinish YES                       show the end of the lesson
enum LessonsLaunchOptions {
    @MainActor
    static var initialPath: [LearnRoute] {
        #if DEBUG
        guard let target = UserDefaults.standard.string(forKey: "LessonsOpen") else { return [] }
        let parts = target.split(separator: "/").map(String.init)
        var path: [LearnRoute] = [.unit(parts[0])]
        if parts.count > 1 {
            path.append(.lesson(unitID: parts[0], lessonID: parts[1]))
        }
        return path
        #else
        return []
        #endif
    }

    #if DEBUG
    static var runsCells: Bool {
        UserDefaults.standard.bool(forKey: "LessonsRunCells")
    }

    @MainActor
    static func apply(to model: ReaderModel, runner: any PythonRunning, proxy: ScrollViewProxy) async {
        let defaults = UserDefaults.standard
        let step = defaults.integer(forKey: "LessonsStep")
        let answer = defaults.string(forKey: "LessonsAnswer")
        let finish = defaults.bool(forKey: "LessonsFinish")
        guard step > 0 || answer != nil || finish else { return }

        if step > 0 { model.debugShow(steps: step) }
        if let answer { await model.debugAnswer(correctly: answer == "right") }
        if finish {
            model.debugShow(steps: model.stepCount)
            model.finish()
        }
        try? await Task.sleep(for: .milliseconds(800))
        proxy.scrollTo(finish ? StepAnchor.finish : StepAnchor(index: model.currentStep), anchor: finish ? .bottom : .top)
    }
    #endif
}

#if DEBUG
extension ReaderModel {
    func debugShow(steps: Int) {
        while revealed < min(steps, stepCount) {
            if needsCheck { debugMarkChecked() }
            reveal()
        }
    }

    func debugAnswer(correctly: Bool) async {
        for (index, block) in lesson.steps[currentStep].blocks.enumerated() {
            let id = BlockID(step: currentStep, block: index)
            switch block {
            case .choice(let question):
                let options = question.options.indices
                choiceSelections[id] = correctly
                    ? Set(options.filter { question.options[$0].isCorrect })
                    : Set(options.filter { !question.options[$0].isCorrect }.prefix(1))
            case .code(let code) where code.role == .predict:
                predictAnswers[id] = correctly ? (code.recordedOutput ?? "") : "8"
            case .code(let code) where code.role == .arrange:
                if correctly {
                    arrangeOrders[id] = Array(ArrangeShuffle.lines(of: code.source).indices)
                }
            default:
                break
            }
        }
        await check()
    }
}
#endif
#endif
