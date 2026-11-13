import Observation

/// Runs the Intro: the drums play steadily, slow down to a crawl, and the
/// screen changes look as they do. Everything follows the loop's own time
/// on the audio clock: on every step we read that step's time and set the
/// tempo, pitch, filter and look for that moment. No timers.
@Observable
final class IntroViewModel {
    private(set) var phase: IntroPhase = .steady
    /// 0 → 1 across the slowdown; the lane colour fades cyan → pink with it.
    private(set) var slowdownProgress = 0.0

    @ObservationIgnored private let beatPlayer: any BeatPlaying

    init(beatPlayer: any BeatPlaying) {
        self.beatPlayer = beatPlayer
    }

    var isPlaying: Bool { beatPlayer.isLooping && !beatPlayer.isPaused }
    var playheadBeats: Double? { beatPlayer.playheadBeats }

    /// The Intro has just appeared: the drums start by themselves 2 s later.
    func start() {
        restart(after: 2)
    }

    /// Pause freezes everything; Play carries on from the same spot. If the
    /// loop was stopped (a phone call, the app going to the background) it
    /// starts again from the beginning.
    func togglePlayPause() {
        if beatPlayer.isPaused {
            beatPlayer.resume()
        } else if beatPlayer.isLooping {
            beatPlayer.pause()
        } else {
            restart(after: 0.1)
        }
    }

    /// Replay starts again from Steady.
    func replay() {
        restart(after: 0.1)
    }

    /// Leaving the Intro: stop and put tempo, pitch and filter back.
    func leave() {
        beatPlayer.onStep = nil
        beatPlayer.stop()
        beatPlayer.resetDrumEffects()
        beatPlayer.setTempo(IntroTiming.startBPM)
        phase = .steady
        slowdownProgress = 0
    }

    private func restart(after delay: Double) {
        phase = .steady
        slowdownProgress = 0
        beatPlayer.onStep = { [weak self] _ in self?.stepPlayed() }
        // Effects on before the loop starts, at "no change".
        beatPlayer.setDrumEffects(pitchRatio: 1, lowPassCutoff: IntroTiming.openCutoff)
        beatPlayer.startLoop(.introGroove, bpm: IntroTiming.startBPM, startDelay: delay)
    }

    /// Called by the audio engine every time a step plays.
    private func stepPlayed() {
        guard let seconds = beatPlayer.currentStepSeconds else { return }
        let bpm = IntroTiming.bpm(at: seconds)
        beatPlayer.setTempo(bpm)
        beatPlayer.setDrumEffects(pitchRatio: IntroTiming.pitchRatio(bpm: bpm),
                                  lowPassCutoff: IntroTiming.lowPassCutoff(at: seconds))
        slowdownProgress = IntroTiming.progress(at: seconds)
        phase = IntroTiming.phase(at: seconds)
    }
}
