import SwiftUI

/// The pad's feedback: an icon and words, coloured by tone.
struct PadMessage: Equatable {
    enum Tone {
        /// White words, as before the first tap.
        case plain
        /// Cyan: a good tap or finished.
        case good
        /// Pink: a miss.
        case bad
        /// White words with a grey icon: "Press play first".
        case muted
    }

    let symbol: String
    let title: String
    let detail: String
    let tone: Tone

    /// Shown when the pad is tapped before the drums are playing.
    static let pressPlayFirst = PadMessage(symbol: "play.fill", title: "Press play first",
                                           detail: "The drums start when you press play", tone: .muted)
}

/// The tap pad used by the Do activities (Figma "Tap pad"): a charcoal box
/// with the feedback in the middle and anything extra (Do 1's Early / Late
/// scale) below it. Reacts the instant a finger lands, with the touch's
/// timestamp.
struct TapPadView<Accessory: View>: View {
    let message: PadMessage
    let onTouchDown: (TimeInterval) -> Void
    @ViewBuilder let accessory: Accessory

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(AppColor.surface)

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: message.symbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(message.tone.iconColor)
                    Text(message.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(message.tone.titleColor)
                }
                Text(message.detail)
                    .font(.system(size: 13))
                    .foregroundStyle(AppColor.textSecondary)
                accessory
            }
            .allowsHitTesting(false)

            TouchDownArea(accessibilityLabel: "Tap pad. \(message.title). \(message.detail)",
                          onTouchDown: onTouchDown)
        }
        .frame(height: 128)
    }
}

extension TapPadView where Accessory == EmptyView {
    init(message: PadMessage, onTouchDown: @escaping (TimeInterval) -> Void) {
        self.init(message: message, onTouchDown: onTouchDown) { EmptyView() }
    }
}

private extension PadMessage.Tone {
    var titleColor: Color {
        switch self {
        case .plain, .muted: AppColor.textPrimary
        case .good: AppColor.accentCyan
        case .bad: AppColor.accentPink
        }
    }

    var iconColor: Color {
        self == .muted ? AppColor.textSecondary : titleColor
    }
}

#Preview(traits: .landscapeLeft) {
    VStack(spacing: 16) {
        TapPadView(message: PadMessage(symbol: "hand.point.up.left", title: "Tap here",
                                       detail: "on every beat", tone: .plain)) { _ in }
        TapPadView(message: .pressPlayFirst) { _ in }
    }
    .padding(.horizontal, 59)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColor.background)
}
