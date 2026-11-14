import SwiftUI

/// Learn card 2 "BPM: beats per minute." (Figma F · 2a–c): 60 and 120 BPM,
/// each played for 4 seconds on a timeline. Once both have been heard the
/// guide line resolves.
struct LearnBPMCard: View {
    let viewModel: LearnViewModel

    private typealias Content = LearnCardsContent.Speeds

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            LearnCardHeader(title: Content.title, guide: guide)

            // Second marks over the timelines.
            ZStack(alignment: .topLeading) {
                ForEach(0...BeatTimeline.seconds, id: \.self) { second in
                    Text("\(second)s")
                        .font(.system(size: 11))
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize()
                        .position(x: Self.timelineX + BeatTimeline.x(at: Double(second)), y: 7)
                }
            }
            .frame(height: 14)
            .padding(.top, 14)

            VStack(spacing: 18) {
                ForEach(Content.rows.indices, id: \.self) { index in
                    row(index)
                }
            }
            .padding(.top, 5)
        }
    }

    /// Where the timelines start, from the card's content edge.
    private static let timelineX: CGFloat = 170

    private var guide: Text {
        viewModel.bothSpeedsHeard
            ? Text("\(Text(Content.resolvedLead).foregroundStyle(AppColor.textPrimary))\(Content.resolvedRest)")
            : Text(Content.guide)
    }

    private func row(_ index: Int) -> some View {
        let speed = Content.rows[index]
        return HStack(spacing: 0) {
            TransportButton(isPlaying: viewModel.isPlaying(.speed(index))) {
                viewModel.toggle(.speed(index))
            }
            .padding(.leading, -3)
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(speed.bpm)")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppColor.textPrimary)
                    Text("BPM")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColor.accentCyan)
                }
                Text(speed.caption)
                    .font(.system(size: 12))
                    .foregroundStyle(AppColor.textSecondary)
            }
            .padding(.leading, 9)
            Spacer(minLength: 0)
            TimelineView(.animation(paused: !viewModel.isPlaying(.speed(index)))) { _ in
                BeatTimeline(bpm: speed.bpm, elapsed: viewModel.elapsed(speed: index),
                             heard: viewModel.hasHeard(speed: index))
            }
        }
        .frame(height: 50)
    }
}
