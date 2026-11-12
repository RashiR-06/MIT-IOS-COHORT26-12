import SwiftUI

/// Root view. For now it opens Lesson 1.1 directly and shows a blank
/// screen once the learner leaves or finishes it.
struct ContentView: View {
    @State private var lessonViewModel = LessonViewModel(content: .lesson1_1)

    var body: some View {
        if lessonViewModel.hasExited {
            TemporaryBlankView()
        } else {
            LessonView(viewModel: lessonViewModel)
        }
    }
}

#Preview(traits: .landscapeLeft) {
    ContentView()
}
