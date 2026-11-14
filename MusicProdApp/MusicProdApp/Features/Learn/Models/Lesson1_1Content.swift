import Foundation

extension LessonContent {
    /// Lesson 1.1: Tempo and Beats. "Lesson complete" is a pop-up over the
    /// Finale, not a step.
    static let lesson1_1 = LessonContent(
        title: "1.1  Tempo and Beats",
        steps: [
            LessonStep(name: "Intro", primaryButtonTitle: "Fix the drums", screen: .intro),
            LessonStep(name: "Learn 1", primaryButtonTitle: "Next"),
            LessonStep(name: "Learn 2", primaryButtonTitle: "Next"),
            LessonStep(name: "Learn 3", primaryButtonTitle: "Next"),
            LessonStep(name: "Do 1", primaryButtonTitle: "Next", screen: .doTapPulse),
            LessonStep(name: "Do 2", primaryButtonTitle: "Next", screen: .doFindTheOne),
            LessonStep(name: "Do 3", primaryButtonTitle: "Next"),
            LessonStep(name: "Finale", primaryButtonTitle: "Next"),
        ]
    )
}
