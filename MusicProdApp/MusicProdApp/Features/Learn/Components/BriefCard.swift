import SwiftUI

/// The brief in Do 3 (Figma "Brief"): an icon, the vibe's name and its
/// tags, in a charcoal card with a soft cyan border.
struct BriefCard: View {
    let brief: TempoBrief

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(AppColor.accentCyan.opacity(0.14))
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: brief.symbol)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(AppColor.accentCyan)
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(brief.title)
                    .font(.system(size: 28, weight: .semibold))
                    .tracking(-0.6)
                    .foregroundStyle(AppColor.textPrimary)
                Text(brief.tags)
                    .font(.system(size: 13))
                    .foregroundStyle(AppColor.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.leading, 14.5)
        .frame(width: 270, height: 104)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(AppColor.accentCyan.opacity(0.5), lineWidth: 1.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Brief: \(brief.title). \(brief.tags)")
    }
}

#Preview(traits: .landscapeLeft) {
    BriefCard(brief: .lateNight)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.background)
}
