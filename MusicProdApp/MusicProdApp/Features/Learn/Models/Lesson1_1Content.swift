import Foundation

extension LessonContent {
    /// Lesson 1.1: Tempo and Beats. Each step lights one more segment.
    static let lesson1_1 = LessonContent(
        title: "1.1  Tempo and Beats",
        steps: [
            LessonStep(name: "Intro", progressSegments: 1, primaryButtonTitle: "Fix the drums"),
            LessonStep(name: "Learn 1", progressSegments: 2, primaryButtonTitle: "Next"),
            LessonStep(name: "Learn 2", progressSegments: 3, primaryButtonTitle: "Next"),
            LessonStep(name: "Learn 3", progressSegments: 4, primaryButtonTitle: "Next"),
            LessonStep(name: "Do 1", progressSegments: 5, primaryButtonTitle: "Next"),
            LessonStep(name: "Do 2", progressSegments: 6, primaryButtonTitle: "Next"),
            LessonStep(name: "Do 3", progressSegments: 7, primaryButtonTitle: "Next"),
            LessonStep(name: "Finale", progressSegments: 8, primaryButtonTitle: "Next"),
            LessonStep(name: "Complete", progressSegments: 9, primaryButtonTitle: "Next"),
        ]
    )
}
