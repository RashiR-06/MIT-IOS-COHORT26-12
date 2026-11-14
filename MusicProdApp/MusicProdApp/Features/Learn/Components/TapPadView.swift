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

    /// Nil for words only ("Keep tapping…").
    let symbol: String?
    let title: String
    let detail: String
    let tone: Tone

    /// Shown when the pad is tapped before the drums are playing.
    static let pressPlayFirst = PadMessage(symbol: "play.fill", title: "Press play first",
                                           detail: "The drums start when you press play", tone: .muted)
}

/// The tap pad used by the Do activities and the Finale (Figma "Tap pad"):
/// a charcoal box with feedback in the middle. Reacts the instant a finger
/// lands, with the touch's timestamp. The Finale's pad is shorter and gets a
/// coloured border for its results.
struct TapPadView<Content: View>: View {
    var height: CGFloat = 128
    var border: Color? = nil
    let accessibilityLabel: String
    let onTouchDown: (TimeInterval) -> Void
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(AppColor.surface)
            if let border {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(border, lineWidth: 1.5)
            }

            content
                .allowsHitTesting(false)

            TouchDownArea(accessibilityLabel: "Tap pad. \(accessibilityLabel)", onTouchDown: onTouchDown)
        }
        .frame(height: height)
    }
}

/// The usual pad feedback: icon and title, the detail line, and anything
/// extra below (Do 1's Early / Late scale).
struct PadMessageView<Accessory: View>: View {
    let message: PadMessage
    var spacing: CGFloat = 8
    @ViewBuilder let accessory: Accessory

    var body: some View {
        VStack(spacing: spacing) {
            HStack(spacing: 8) {
                if let symbol = message.symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(message.tone.iconColor)
                }
                Text(message.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(message.tone.titleColor)
            }
            Text(message.detail)
                .font(.system(size: 13))
                .foregroundStyle(AppColor.textSecondary)
            accessory
        }
    }
}

extension TapPadView {
    /// A pad showing a PadMessage, with something extra below it.
    init<Accessory: View>(message: PadMessage, height: CGFloat = 128, border: Color? = nil,
                          spacing: CGFloat = 8, onTouchDown: @escaping (TimeInterval) -> Void,
                          @ViewBuilder accessory: () -> Accessory) where Content == PadMessageView<Accessory> {
        self.init(height: height, border: border, accessibilityLabel: "\(message.title). \(message.detail)",
                  onTouchDown: onTouchDown) {
            PadMessageView(message: message, spacing: spacing, accessory: accessory)
        }
    }

    /// A pad showing a PadMessage.
    init(message: PadMessage, height: CGFloat = 128, border: Color? = nil, spacing: CGFloat = 8,
         onTouchDown: @escaping (TimeInterval) -> Void) where Content == PadMessageView<EmptyView> {
        self.init(message: message, height: height, border: border, spacing: spacing,
                  onTouchDown: onTouchDown) { EmptyView() }
    }
}

extension PadMessage.Tone {
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
