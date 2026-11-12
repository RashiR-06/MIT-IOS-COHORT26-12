import SwiftUI

/// Temporary blank screen shown after leaving or finishing a lesson.
/// Replace it once the Home / Learn map exists.
struct TemporaryBlankView: View {
    var body: some View {
        AppColor.background
            .ignoresSafeArea()
    }
}

#Preview(traits: .landscapeLeft) {
    TemporaryBlankView()
}
