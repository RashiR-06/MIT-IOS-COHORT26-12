import Foundation

/// The drum sounds the app can play.
enum DrumSound: CaseIterable {
    case kick
    case snare
    case hatClosed
}

/// What views and view models use to play drums. Only Services/Audio
/// knows about AVFoundation; everything else talks to this protocol.
protocol BeatPlaying: AnyObject {
    /// True while a pattern is looping.
    var isLooping: Bool { get }
    /// The pattern step (0-based) that was just heard, or nil when stopped.
    var currentStep: Int? { get }
    /// Called on the main thread each time a step is heard.
    var onStep: ((Int) -> Void)? { get set }
    /// Seconds between the app producing sound and it reaching the speaker
    /// or headphones. Bluetooth makes this much larger.
    var outputLatency: TimeInterval { get }

    /// Plays one drum straight away.
    func play(_ sound: DrumSound)
    /// Loops a pattern at the given tempo, timed by the audio clock.
    func startLoop(_ pattern: DrumPattern, bpm: Double)
    /// Stops the loop and any drums still ringing.
    func stop()
}
