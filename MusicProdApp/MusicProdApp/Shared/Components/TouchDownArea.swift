import SwiftUI
import UIKit

/// An invisible area that reports a touch the moment a finger lands
/// (touch-down, not release), with the touch's own timestamp: when the
/// screen felt the finger, in seconds since the phone started. That is
/// more exact than the time our code gets round to handling it, and it
/// is the clock BeatPlaying.loopSeconds(heardAt:) takes. SwiftUI's tap
/// gestures fire on release and give no timestamp, hence this UIKit view.
struct TouchDownArea: UIViewRepresentable {
    let accessibilityLabel: String
    let onTouchDown: (TimeInterval) -> Void

    func makeUIView(context: Context) -> TouchDownView {
        let view = TouchDownView()
        view.isMultipleTouchEnabled = true
        view.isAccessibilityElement = true
        view.accessibilityTraits = .button
        return view
    }

    func updateUIView(_ view: TouchDownView, context: Context) {
        view.onTouchDown = onTouchDown
        view.accessibilityLabel = accessibilityLabel
    }

    final class TouchDownView: UIView {
        var onTouchDown: ((TimeInterval) -> Void)?

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            // One report per finger that lands, so two-finger drumming works.
            for touch in touches {
                onTouchDown?(touch.timestamp)
            }
        }

        /// VoiceOver double-tap: there is no touch, so use the time now.
        override func accessibilityActivate() -> Bool {
            onTouchDown?(ProcessInfo.processInfo.systemUptime)
            return true
        }
    }
}
