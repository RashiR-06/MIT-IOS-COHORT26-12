import SwiftUI

/// The shared lesson screen: top bar, then the current step. Steps with a
/// real screen (the Intro, Do 1–3) show it; the rest show a temporary label and
/// the primary button.
struct LessonView: View {
    @Bindable var viewModel: LessonViewModel
    let introViewModel: IntroViewModel
    let doOneViewModel: DoOneViewModel
    let doTwoViewModel: DoTwoViewModel
    let doThreeViewModel: DoThreeViewModel

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

            switch viewModel.currentStep.screen {
            case .intro:
                IntroView(viewModel: introViewModel, onFixTheDrums: viewModel.next)
            case .doTapPulse:
                DoOneView(viewModel: doOneViewModel, onNext: viewModel.next)
            case .doFindTheOne:
                DoTwoView(viewModel: doTwoViewModel, onNext: viewModel.next)
            case .doMatchTheBrief:
                DoThreeView(viewModel: doThreeViewModel, onNext: viewModel.next)
            case .placeholder:
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
    let beatPlayer = BeatPlayer()
    LessonView(viewModel: LessonViewModel(content: .lesson1_1),
               introViewModel: IntroViewModel(beatPlayer: beatPlayer),
               doOneViewModel: DoOneViewModel(beatPlayer: beatPlayer),
               doTwoViewModel: DoTwoViewModel(beatPlayer: beatPlayer),
               doThreeViewModel: DoThreeViewModel(beatPlayer: beatPlayer))
}
