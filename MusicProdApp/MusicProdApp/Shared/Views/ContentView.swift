import SwiftUI

/// Root view. For now it opens Lesson 1.1 directly and shows a blank
/// screen once the learner leaves or finishes it. Debug builds also show
/// an "Audio test" button that opens the audio test screen (see DebugFlags).
struct ContentView: View {
    let beatPlayer: any BeatPlaying
    @State private var lessonViewModel = LessonViewModel(content: .lesson1_1)
    @State private var showAudioTest = false

    var body: some View {
        Group {
            if lessonViewModel.hasExited {
                TemporaryBlankView()
            } else {
                LessonView(viewModel: lessonViewModel)
            }
        }
        .overlay(alignment: .bottomLeading) {
            if DebugFlags.showAudioDebug {
                Button {
                    showAudioTest = true
                } label: {
                    Text("Audio test")
                        .font(.headline)
                        .foregroundStyle(AppColor.textPrimary)
                }
                .buttonStyle(.glass)
                .controlSize(.large)
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
