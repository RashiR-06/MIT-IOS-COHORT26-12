import Observation

/// Moves through any lesson's steps. Holds all navigation logic so the
/// views only draw state and forward taps.
@Observable
final class LessonViewModel {
    let content: LessonContent
    private(set) var stepIndex = 0
    /// True once the learner has left or finished the lesson.
    private(set) var hasExited = false
    var showLeaveAlert = false

    init(content: LessonContent) {
        self.content = content
    }

    var currentStep: LessonStep {
        content.steps[stepIndex]
    }

    var progress: Int {
        currentStep.progressSegments
    }

    /// Next step, or exit after the last step.
    func next() {
        if stepIndex < content.steps.count - 1 {
            stepIndex += 1
        } else {
            hasExited = true
        }
    }

    /// Previous step. On the first step, Back behaves like Close.
    func back() {
        if stepIndex > 0 {
            stepIndex -= 1
        } else {
            close()
        }
    }

    func close() {
        showLeaveAlert = true
    }

    func leave() {
        hasExited = true
    }
}
