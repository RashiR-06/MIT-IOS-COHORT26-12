import SwiftUI

/// Root view. For now it opens Lesson 1.1 directly and shows a blank
/// screen once the learner leaves or finishes it. Debug builds also show
/// an "Audio test" button that opens the audio test screen (see DebugFlags).
struct ContentView: View {
    let beatPlayer: any BeatPlaying
    @State private var lessonViewModel = LessonViewModel(content: .lesson1_1)
    @State private var introViewModel: IntroViewModel
    @State private var showAudioTest = false

    init(beatPlayer: any BeatPlaying) {
        self.beatPlayer = beatPlayer
        _introViewModel = State(initialValue: IntroViewModel(beatPlayer: beatPlayer))
    }

    var body: some View {
        Group {
            if lessonViewModel.hasExited {
                TemporaryBlankView()
            } else {
                LessonView(viewModel: lessonViewModel, introViewModel: introViewModel)
            }
        }
        // Bottom centre: the corners hold the lesson's own buttons.
        .overlay(alignment: .bottom) {
            if DebugFlags.showAudioDebug {
                GlassTextButton(title: "Audio test") { showAudioTest = true }
            }
        }
        .fullScreenCover(isPresented: $showAudioTest) {
            AudioDebugView(beatPlayer: beatPlayer)
        }
    }
}

#Preview(traits: .landscapeLeft) {
    ContentView(beatPlayer: BeatPlayer())
}
