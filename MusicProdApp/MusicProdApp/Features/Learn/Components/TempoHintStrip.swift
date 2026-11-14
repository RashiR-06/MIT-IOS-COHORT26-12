import SwiftUI

/// Do 3's hint (Figma "Hint popover · tempo feels"): one strip of tempo
/// feels, each a name over its BPM range, with thin dividers between.
struct TempoHintStrip: View {
    let feels: [TempoFeel]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(feels.enumerated()), id: \.element.id) { index, feel in
                if index > 0 {
                    Rectangle()
                        .fill(AppColor.surfaceRaised)
                        .frame(width: 1, height: 28)
                        .padding(.trailing, 11)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(feel.name)
                        .font(.system(size: 14))
                        .foregroundStyle(AppColor.textPrimary)
                    Text(feel.range)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColor.accentCyan)
                }
                .frame(width: 90, alignment: .leading)
            }
        }
        .lineLimit(1)
        .padding(.leading, 16)
        .frame(width: 420, height: 48, alignment: .leading)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Hint. Tempo feels: " + feels.map { "\($0.name), \($0.range)" }.joined(separator: "; "))
    }
}

#Preview(traits: .landscapeLeft) {
    TempoHintStrip(feels: TempoFeel.all)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.background)
}
