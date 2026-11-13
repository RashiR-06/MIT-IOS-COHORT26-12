import AVFoundation

/// Sets up the app's audio session and reports when audio must stop.
final class AudioSessionManager {
    /// Called when playback must stop: an interruption (phone call, Siri,
    /// alarm) or the headphones being unplugged.
    var onMustStop: (() -> Void)?

    private var observers: [NSObjectProtocol] = []

    init() {
        let center = NotificationCenter.default

        observers.append(center.addObserver(forName: AVAudioSession.interruptionNotification,
                                            object: nil, queue: .main) { [weak self] note in
            let type = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            // Stop when the interruption begins. We do not resume afterwards.
            guard type == AVAudioSession.InterruptionType.began.rawValue else { return }
            MainActor.assumeIsolated { self?.onMustStop?() }
        })

        observers.append(center.addObserver(forName: AVAudioSession.routeChangeNotification,
                                            object: nil, queue: .main) { [weak self] note in
            let reason = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
            // Headphones unplugged: stop rather than blast the speaker.
            guard reason == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue else { return }
            MainActor.assumeIsolated { self?.onMustStop?() }
        })
    }

    /// .playback means drums are heard even with the silent switch on.
    func activate() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            print("Audio session could not start: \(error)")
        }
    }

    var outputLatency: TimeInterval {
        AVAudioSession.sharedInstance().outputLatency
    }
}
