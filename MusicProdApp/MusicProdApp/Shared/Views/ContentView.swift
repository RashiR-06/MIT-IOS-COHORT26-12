import SwiftUI

// Temporary design-system preview for Block 1. Next, Back and Close step
// through the progress segments so every state can be checked.
struct ContentView: View {
    @State private var segment = 1

    var body: some View {
        VStack(spacing: 0) {
            LessonTopBar(
                title: "1.1  Tempo and Beats",
                currentSegment: segment,
                onBack: { segment = max(segment - 1, 1) },
                onClose: { segment = 1 }
            )
            .padding(.top, 11)
            Spacer()
            HStack {
                Spacer()
                PrimaryButton(title: "Next") {
                    segment = min(segment + 1, SegmentedProgressBar.segmentCount)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.background)
    }
}

#Preview(traits: .landscapeLeft) {
    ContentView()
}
