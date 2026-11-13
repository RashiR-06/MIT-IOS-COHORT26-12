import SwiftUI

/// Root view. For now it opens Lesson 1.1 directly and shows a blank
/// screen once the learner leaves or finishes it. In debug builds it can
/// show the audio test screen instead (see DebugFlags).
struct ContentView: View {
    let beatPlayer: any BeatPlaying
    @State private var lessonViewModel = LessonViewModel(content: .lesson1_1)

    var body: some View {
        if DebugFlags.showAudioDebug {
            AudioDebugView(beatPlayer: beatPlayer)
        } else if lessonViewModel.hasExited {
            TemporaryBlankView()
        } else {
            LessonView(viewModel: lessonViewModel)
        }
    }
}

#Preview(traits: .landscapeLeft) {
    ContentView(beatPlayer: BeatPlayer())
}
