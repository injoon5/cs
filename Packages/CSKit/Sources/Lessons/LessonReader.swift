#if canImport(UIKit)
import Contracts
import SwiftUI

/// One lesson as a vertical feed. Steps appear one at a time; finished steps stay above.
struct LessonReader: View {
    let nextLesson: Lesson?
    let library: ContentLibrary
    let runner: any PythonRunning
    let openNext: (Lesson) -> Void

    @State private var model: ReaderModel
    @Environment(\.dismiss) private var dismiss

    private static let finishID = StepAnchor.finish

    init(
        lesson: Lesson,
        unitID: String,
        nextLesson: Lesson?,
        library: ContentLibrary,
        runner: any PythonRunning,
        progress: any ProgressRecording,
        openNext: @escaping (Lesson) -> Void
    ) {
        self.nextLesson = nextLesson
        self.library = library
        self.runner = runner
        self.openNext = openNext
        _model = State(initialValue: ReaderModel(lesson: lesson, unitID: unitID, library: library, runner: runner, progress: progress))
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(0..<model.revealed, id: \.self) { index in
                        if index > 0 {
                            Divider()
                                .padding(.vertical, 28)
                        }
                        StepView(stepIndex: index, model: model, library: library, runner: runner)
                            .id(StepAnchor(index: index))
                    }
                    if model.isFinished {
                        FinishView(nextLesson: nextLesson)
                            .padding(.top, 48)
                            .id(Self.finishID)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaBar(edge: .top, spacing: 0) {
                ProgressView(value: model.fractionComplete)
                    .progressViewStyle(.linear)
                    .animation(.spring, value: model.fractionComplete)
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                    .accessibilityLabel("Step \(model.revealed) of \(model.stepCount)")
            }
            .safeAreaBar(edge: .bottom) {
                bottomButton(proxy: proxy)
            }
            .onAppear {
                model.recordOpened()
                if model.revealed > 1 {
                    proxy.scrollTo(StepAnchor(index: model.currentStep), anchor: .top)
                }
            }
            #if DEBUG
            .task { await LessonsLaunchOptions.apply(to: model, runner: runner, proxy: proxy) }
            #endif
        }
        .navigationTitle(model.lesson.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if model.revealed > 1 {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu("More", systemImage: "ellipsis") {
                        Button("Start over", systemImage: "arrow.counterclockwise") {
                            model.startOver()
                        }
                    }
                }
            }
        }
        .sensoryFeedback(trigger: model.lastCheck) { _, event in
            guard let event else { return nil }
            return event.isCorrect ? .success : .error
        }
    }

    // MARK: Bottom button

    private enum Action {
        case check, next, finish, nextLesson(Lesson), done
    }

    private var action: Action {
        if model.needsCheck { return .check }
        if !model.isAtLastStep { return .next }
        if !model.isFinished { return .finish }
        if let nextLesson { return .nextLesson(nextLesson) }
        return .done
    }

    private func bottomButton(proxy: ScrollViewProxy) -> some View {
        let action = action
        return Button {
            perform(action, proxy: proxy)
        } label: {
            ZStack {
                // Both labels keep their size so the button doesn't change height while checking.
                Text(title(action))
                    .opacity(model.isChecking ? 0 : 1)
                if model.isChecking {
                    ProgressView()
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .controlSize(.large)
        .disabled(isDisabled(action))
        .keyboardShortcut(.defaultAction)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private func title(_ action: Action) -> String {
        switch action {
        case .check: "Check"
        case .next: "Continue"
        case .finish: "Finish"
        case .nextLesson: "Next lesson"
        case .done: "Done"
        }
    }

    private func isDisabled(_ action: Action) -> Bool {
        switch action {
        case .check: !model.canCheck
        default: model.isChecking
        }
    }

    private func perform(_ action: Action, proxy: ScrollViewProxy) {
        switch action {
        case .check:
            hideKeyboard()
            Task {
                await model.check()
                // Results appear under the question; bring them into view.
                scroll(to: StepAnchor(index: model.currentStep), anchor: .bottom, proxy: proxy)
            }
        case .next:
            hideKeyboard()
            model.reveal()
            scroll(to: StepAnchor(index: model.currentStep), proxy: proxy)
        case .finish:
            model.finish()
            scroll(to: Self.finishID, proxy: proxy)
        case .nextLesson(let lesson):
            openNext(lesson)
        case .done:
            dismiss()
        }
    }

    /// New content appears in place; the scroll is what moves.
    private func scroll(to id: some Hashable, anchor: UnitPoint = .top, proxy: ScrollViewProxy) {
        Task { @MainActor in
            await Task.yield()
            withAnimation(.spring(duration: 0.5)) {
                proxy.scrollTo(id, anchor: anchor)
            }
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

/// Scroll target for a step. Its own type, so it never matches the `ForEach` ids inside steps.
enum StepAnchor: Hashable {
    case step(Int)
    case finish

    init(index: Int) {
        self = .step(index)
    }
}

/// The end of a lesson.
private struct FinishView: View {
    let nextLesson: Lesson?
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(.largeTitle))
                .imageScale(.large)
                .foregroundStyle(.green)
                .symbolEffect(.bounce, value: appeared)
                .accessibilityHidden(true)
            Text("Lesson complete")
                .font(.title2.bold())
            if let nextLesson {
                Text("Next: \(nextLesson.title)")
                    .foregroundStyle(.secondary)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .onAppear { appeared = true }
    }
}
#endif
