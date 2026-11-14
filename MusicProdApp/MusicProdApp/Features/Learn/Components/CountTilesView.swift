import SwiftUI

/// A ✓ or × under one count tile, showing where the last tap landed.
struct CountTileMark: Equatable {
    /// 0 is the "1" tile.
    let tile: Int
    let isHit: Bool
}

/// The four 1–2–3–4 count tiles of Do 2 (Figma "Count 1"–"Count 4"). A lit
/// tile turns cyan with a black number; `light` comes from the audio clock.
struct CountTilesView: View {
    var light: (tile: Int, level: Double)?
    var mark: CountTileMark?

    var body: some View {
        HStack(spacing: 13) {
            ForEach(0..<4, id: \.self) { tile in
                let level = light?.tile == tile ? light?.level ?? 0 : 0
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppColor.surfaceRaised)
                    // As in the mockup: from a faint glow up to solid cyan.
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppColor.accentCyan.opacity(level > 0 ? 0.25 + 0.75 * level : 0))

                    Text("\(tile + 1)")
                        .font(.system(size: tile == 0 ? 48 : 40, weight: .bold))
                        .foregroundStyle(level > 0.5 ? AppColor.background : AppColor.textSecondary)

                    if let mark, mark.tile == tile {
                        Image(systemName: mark.isHit ? "checkmark" : "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(mark.isHit ? AppColor.accentCyan : AppColor.accentPink)
                            .frame(width: 14, height: 14)
                            .offset(y: 35)
                    }
                }
                .frame(height: 100)
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview(traits: .landscapeLeft) {
    VStack(spacing: 16) {
        CountTilesView(light: (tile: 3, level: 1), mark: CountTileMark(tile: 2, isHit: false))
        CountTilesView(mark: CountTileMark(tile: 0, isHit: true))
    }
    .padding(.horizontal, 59)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColor.background)
}
