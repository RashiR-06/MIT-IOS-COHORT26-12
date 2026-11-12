import Observation

/// Moves through any lesson's steps. Holds all navigation logic so the
/// views only draw state and forward taps.
@Observable
final class LessonViewModel {
    let content: LessonContent
    private(set) var stepIndex = 0
    /// True once the learner has left or finished the lesson.
    private(set) var hasExited = false
    private(set) var showCompletePopup = false
    var showLeaveAlert = false

    init(content: LessonContent) {
        self.content = content
    }

    var currentStep: LessonStep {
        content.steps[stepIndex]
    }

    /// Each step lights one more segment; the last step fills the bar.
    var progress: Int {
        stepIndex + 1
    }

    var segmentCount: Int {
        content.steps.count
    }

    /// Next step, or the "Lesson complete" pop-up after the last step.
    func next() {
        if stepIndex < content.steps.count - 1 {
            stepIndex += 1
        } else {
            showCompletePopup = true
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

    /// Either pop-up button. Both go to the temporary blank screen for now.
    func finish() {
        hasExited = true
    }
}
