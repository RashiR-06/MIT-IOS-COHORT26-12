import SwiftUI

/// The cyan call-to-action button (Figma "iOS/Btn Primary"), using Apple's
/// native Liquid Glass prominent style.
struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(AppColor.background)
        }
        .buttonStyle(.glassProminent)
        .controlSize(.large)
        .tint(AppColor.accentCyan)
    }
}

#Preview(traits: .landscapeLeft) {
    PrimaryButton(title: "Next") {}
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.background)
}
