import SwiftUI

/// Learn card 1 "Feel the pulse." (Figma F · 1): the 1–2–3–4 tiles light
/// with the beat, over a "4 beats = 1 bar" bracket. Plays by itself.
struct LearnPulseCard: View {
    let viewModel: LearnViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                LearnCardHeader(title: LearnCardsContent.Pulse.title, guide: Text(LearnCardsContent.Pulse.guide))
                Spacer()
                TransportButton(isPlaying: viewModel.isPlaying(.pulse), action: viewModel.togglePulse)
                    .padding(.top, -5)
                    .padding(.trailing, -7)
            }

            TimelineView(.animation(paused: !viewModel.isPlaying(.pulse))) { _ in
                let light = viewModel.light(for: .pulse)
                CountTilesView(light: light.map { (tile: $0.index, level: $0.level) }, height: 96, spacing: 12)
            }
            .padding(.top, 28)

            BarBracket(label: LearnCardsContent.Pulse.barLabel)
                .padding(.top, 13)
        }
    }
}

/// A card's title and guide line, shared by the three Learn cards.
struct LearnCardHeader: View {
    let title: String
    let guide: Text

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.system(size: 24, weight: .semibold))
                .tracking(-0.5)
                .foregroundStyle(AppColor.textPrimary)
            guide
                .font(.system(size: 15))
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(.top, 22)
    }
}

/// The bracket under the tiles: a line with the label in its gap.
private struct BarBracket: View {
    let label: String

    var body: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 0.75, y: 0))
                path.addLine(to: CGPoint(x: 0.75, y: 8))
                path.move(to: CGPoint(x: 0, y: 8))
                path.addLine(to: CGPoint(x: 10_000, y: 8))
            }
            .stroke(AppColor.stroke, lineWidth: 1.5)
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(AppColor.stroke)
                    .frame(width: 1.5, height: 9)
                    .offset(y: -1.5)
            }
            .clipped()

            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(AppColor.textSecondary)
                .padding(.horizontal, 12)
                .background(AppColor.surface)
                .offset(y: 7)
        }
        .frame(height: 12)
    }
}
