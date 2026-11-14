import Foundation

/// Which screen a step shows. Steps without a real screen yet show a
/// temporary placeholder with the step name and a "Next" button.
enum LessonScreen {
    case placeholder
    case intro
    case doTapPulse
    case doFindTheOne
    case doMatchTheBrief
}

/// One screen in a lesson (for example "Intro" or "Do 2").
struct LessonStep {
    /// Temporary on-screen label until the real screen is built.
    let name: String
    let primaryButtonTitle: String
    var screen: LessonScreen = .placeholder
}

/// Everything that makes one lesson different from another: its title and
/// its screens in order. The shared LessonViewModel and LessonView work with
/// any LessonContent. The progress bar has one segment per step.
struct LessonContent {
    let title: String
    let steps: [LessonStep]
}
