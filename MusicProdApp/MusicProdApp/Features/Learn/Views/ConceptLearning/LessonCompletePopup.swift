import SwiftUI

/// The "Lesson complete" pop-up (Figma H · 6): the screen dims and a card
/// shows the tempo gauge at 100, "Congratulations!", what was unlocked, and
/// the two buttons.
struct LessonCompletePopup: View {
    let onBackToStudio: () -> Void
    let onNextLesson: () -> Void

    var body: some View {
        ZStack {
            AppColor.background
                .opacity(0.65)
                .ignoresSafeArea()

            HStack(spacing: 30) {
                TempoGauge(bpm: 100)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Congratulations!")
                        .font(.system(size: 30, weight: .bold))
                        .tracking(-0.6)
                        .foregroundStyle(AppColor.textPrimary)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Tempo control unlocked!")
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColor.textPrimary)
                        Text(" Use it on your track and in the Sandbox.")
                            .foregroundStyle(AppColor.textPrimary.opacity(0.78))
                    }
                    .font(.system(size: 15))
                    .lineSpacing(3)
                    .padding(.top, 24)
                    HStack(spacing: 11.5) {
                        GlassTextButton(title: "Back to Studio", action: onBackToStudio)
                        PrimaryButton(title: "Next lesson", action: onNextLesson)
                    }
                    .padding(.top, 27)
                }
                Spacer(minLength: 0)
            }
            .padding(.leading, 40)
            .frame(width: 560, height: 250)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 28))
        }
        .accessibilityAddTraits(.isModal)
    }
}

#Preview(traits: .landscapeLeft) {
    LessonCompletePopup(onBackToStudio: {}, onNextLesson: {})
}
