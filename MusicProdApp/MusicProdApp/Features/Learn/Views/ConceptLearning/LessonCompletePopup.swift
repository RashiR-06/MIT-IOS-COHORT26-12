import SwiftUI

/// Placeholder for the Figma "Lesson complete" pop-up (frame H · 6): a dimmed
/// background, a card, and the two Figma buttons. Real content comes later.
struct LessonCompletePopup: View {
    let onBackToStudio: () -> Void
    let onNextLesson: () -> Void

    var body: some View {
        ZStack {
            AppColor.background
                .opacity(0.6)
                .ignoresSafeArea()
            VStack(spacing: 24) {
                Text("Lesson complete")
                    .font(.largeTitle)
                    .foregroundStyle(AppColor.textSecondary)
                HStack(spacing: 12) {
                    Button(action: onBackToStudio) {
                        Text("Back to Studio")
                            .font(.headline)
                            .foregroundStyle(AppColor.textPrimary)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.large)
                    PrimaryButton(title: "Next lesson", action: onNextLesson)
                }
            }
            .frame(width: 560, height: 250)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(AppColor.stroke))
        }
    }
}

#Preview(traits: .landscapeLeft) {
    LessonCompletePopup(onBackToStudio: {}, onNextLesson: {})
}
