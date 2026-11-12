import Foundation

/// One step in a lesson (for example "Intro" or "Do 2").
struct LessonStep {
    /// Temporary on-screen label until the real screen is built.
    let name: String
    /// How many progress-bar segments are lit on this step (1 to 10).
    let progressSegments: Int
    let primaryButtonTitle: String
}

/// Everything that makes one lesson different from another: its title and
/// its steps in order. The shared LessonViewModel and LessonView work with
/// any LessonContent.
struct LessonContent {
    let title: String
    let steps: [LessonStep]
}
