import SwiftUI

/// Learn card 3 "Tempo sets the energy." (Figma F · 3a–b): four tempos, each
/// with its feel and genres. The playing one gets a cyan border and its
/// light bars pulse with the beat.
struct LearnEnergyCard: View {
    let viewModel: LearnViewModel

    private typealias Content = LearnCardsContent.Energy

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            LearnCardHeader(title: Content.title, guide: Text(Content.guide))

            TimelineView(.animation(paused: !Content.tempos.indices.contains { viewModel.isPlaying(.energy($0)) })) { _ in
                // Worked out here, once per frame, and handed to each tile
                // so the tiles redraw as it changes.
                let lights = Content.tempos.indices.map { viewModel.light(for: .energy($0)) }
                HStack(spacing: 8) {
                    ForEach(Content.tempos.indices, id: \.self) { index in
                        tile(index, light: lights[index])
                    }
                }
            }
            .padding(.top, 18)

            HStack(spacing: 0) {
                Text(Content.slowEnd)
                Rectangle()
                    .fill(AppColor.stroke)
                    .frame(height: 1.5)
                    .overlay(alignment: .trailing) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .offset(x: 4)
                    }
                    .padding(.horizontal, 21)
                Text(Content.fastEnd)
            }
            .font(.system(size: 12))
            .foregroundStyle(AppColor.textSecondary)
            .padding(.top, 13)
        }
    }

    private func tile(_ index: Int, light: (index: Int, level: Double)?) -> some View {
        let tempo = Content.tempos[index]
        let sound = LearnSound.energy(index)
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 7) {
                TransportButton(isPlaying: viewModel.isPlaying(sound)) { viewModel.toggle(sound) }
                VStack(alignment: .leading, spacing: 2) {
                    Text(tempo.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("\(tempo.bpm) BPM")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColor.accentCyan)
                }
                .padding(.top, 5)
            }
            Text(tempo.genres)
                .font(.system(size: 12))
                .foregroundStyle(AppColor.textSecondary)
                .padding(.top, 13)
            HStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { bar in
                    let level = light?.index == bar ? light?.level ?? 0 : 0
                    RoundedRectangle(cornerRadius: 3)
                        .fill(level > 0 ? AppColor.accentCyan.opacity(0.3 + 0.7 * level) : AppColor.stroke)
                        .frame(width: bar == 0 ? 20 : 14, height: 6)
                }
            }
            .padding(.top, 7)
        }
        .padding(9)
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        .background(AppColor.surfaceRaised, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(viewModel.isPlaying(sound) ? AppColor.accentCyan : .clear, lineWidth: 1.5)
        }
    }
}
