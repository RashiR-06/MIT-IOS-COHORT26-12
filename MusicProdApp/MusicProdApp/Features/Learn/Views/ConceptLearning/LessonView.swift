import SwiftUI

/// The shared lesson screen: top bar, the current step, and the primary
/// button. The step area is a temporary label until real screens exist.
struct LessonView: View {
    @Bindable var viewModel: LessonViewModel

    var body: some View {
        VStack(spacing: 0) {
            LessonTopBar(
                title: viewModel.content.title,
                currentSegment: viewModel.progress,
                segmentCount: viewModel.segmentCount,
                onBack: viewModel.back,
                onClose: viewModel.close
            )
            .padding(.top, 11)
            Spacer()
            Text(viewModel.currentStep.name)
                .font(.largeTitle)
                .foregroundStyle(AppColor.textSecondary)
            Spacer()
            HStack {
                Spacer()
                PrimaryButton(title: viewModel.currentStep.primaryButtonTitle, action: viewModel.next)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.background)
        .overlay {
            if viewModel.showCompletePopup {
                LessonCompletePopup(onBackToStudio: viewModel.finish, onNextLesson: viewModel.finish)
            }
        }
        .alert("Leave the lesson?", isPresented: $viewModel.showLeaveAlert) {
            Button("Stay", role: .cancel) {}
            Button("Leave", role: .destructive, action: viewModel.leave)
        }
    }
}

#Preview(traits: .landscapeLeft) {
    LessonView(viewModel: LessonViewModel(content: .lesson1_1))
}
