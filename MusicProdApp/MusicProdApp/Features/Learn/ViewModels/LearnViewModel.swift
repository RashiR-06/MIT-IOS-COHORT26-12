import Foundation
import Observation

/// One sound on the Learn cards.
enum LearnSound: Equatable {
    /// Card 1's pulse.
    case pulse
    /// Card 2: one of the two speeds (index into the rows).
    case speed(Int)
    /// Card 3: one of the four tempos.
    case energy(Int)
}

/// Runs the three Learn cards (Figma F · 1–3b): which card shows, what is
/// playing and which speeds on card 2 have been heard. Each card plays its
/// own tempo; changing card stops the sound and card 1 plays by itself.
/// Lights and timelines follow the audio clock's playhead.
@Observable
final class LearnViewModel {
    private(set) var card = 0
    private(set) var playing: LearnSound?
    /// Card 2's rows that have played all the way through.
    private(set) var heardSpeeds: Set<Int> = []

    @ObservationIgnored private let beatPlayer: any BeatPlaying
    /// The loop this screen started, so it only ever stops its own sound
    /// (not one the next screen has already started).
    @ObservationIgnored private var ownLoop: Int?

    init(beatPlayer: any BeatPlaying) {
        self.beatPlayer = beatPlayer
    }

    /// True while this sound is audible (started here, not paused).
    func isPlaying(_ sound: LearnSound) -> Bool {
        playing == sound && ownsLoop && !beatPlayer.isPaused
    }

    func hasHeard(speed index: Int) -> Bool { heardSpeeds.contains(index) }
    var bothSpeedsHeard: Bool { heardSpeeds.count == LearnCardsContent.Speeds.rows.count }

    /// Card 1's lit tile, or Card 3's lit light bar.
    func light(for sound: LearnSound) -> (index: Int, level: Double)? {
        guard isPlaying(sound), let beats = beatPlayer.playheadBeats, beats >= 0 else { return nil }
        return BeatLight.light(atBeats: beats)
    }

    /// Seconds into a speed's 4-second play, for its timeline; nil when not playing.
    func elapsed(speed index: Int) -> TimeInterval? {
        guard isPlaying(.speed(index)), let beats = beatPlayer.playheadBeats else { return nil }
        return max(beats, 0) * 60 / Double(LearnCardsContent.Speeds.rows[index].bpm)
    }

    // MARK: Actions

    /// A card is now showing: stop the last card's sound; card 1 plays.
    func show(card: Int) {
        stopOwnSound()
        self.card = card
        if card == 0 { start(.pulse) }
    }

    /// Card 1's button: pause and carry on, or start again if stopped.
    func togglePulse() {
        if playing == .pulse, ownsLoop {
            beatPlayer.isPaused ? beatPlayer.resume() : beatPlayer.pause()
        } else {
            start(.pulse)
        }
    }

    /// Card 2 and 3's buttons: play this sound, or stop it if it is playing.
    func toggle(_ sound: LearnSound) {
        if playing == sound, ownsLoop {
            stopOwnSound()
        } else {
            start(sound)
        }
    }

    /// Leaving Learn: stop the sound and put the tempo back to normal.
    func leave() {
        let owned = ownsLoop
        stopOwnSound()
        beatPlayer.onFinish = nil
        if owned { beatPlayer.setTempo(TempoLimits.normal) }
    }

    // MARK: Sound

    private var ownsLoop: Bool {
        ownLoop != nil && ownLoop == beatPlayer.loopID && beatPlayer.isLooping
    }

    private func start(_ sound: LearnSound) {
        let bpm: Double
        var duration: TimeInterval?
        switch sound {
        case .pulse:
            bpm = LearnCardsContent.Pulse.bpm
        case .speed(let index):
            bpm = Double(LearnCardsContent.Speeds.rows[index].bpm)
            duration = LearnCardsContent.Speeds.playSeconds
        case .energy(let index):
            bpm = Double(LearnCardsContent.Energy.tempos[index].bpm)
        }
        beatPlayer.onStep = nil
        beatPlayer.onFinish = { [weak self] in self?.soundFinished() }
        beatPlayer.resetDrumEffects()
        beatPlayer.startLoop(.lessonGroove, bpm: bpm, startDelay: 0.1, duration: duration)
        ownLoop = beatPlayer.loopID
        playing = sound
    }

    /// A speed on card 2 played all the way through: it counts as heard.
    private func soundFinished() {
        if case .speed(let index) = playing { heardSpeeds.insert(index) }
        playing = nil
        ownLoop = nil
    }

    private func stopOwnSound() {
        if ownsLoop { beatPlayer.stop() }
        playing = nil
        ownLoop = nil
    }
}
