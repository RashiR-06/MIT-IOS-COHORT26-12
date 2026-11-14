import Foundation
import Observation

/// Runs Do 3 "Match the brief": the learner turns the tempo dial until the
/// beat fits the brief, then presses Check. A wrong Check reveals the zone
/// on the dial and the feedback then follows the dial live; a right one
/// stops the drums and offers Next (Figma G · 3a–d, Do mockup).
@Observable
final class DoThreeViewModel {
    let brief: TempoBrief

    /// The dial's value. The beat follows it live while playing.
    var bpm: Int {
        didSet { beatPlayer.setTempo(Double(bpm)) }
    }
    private(set) var zoneRevealed = false
    private(set) var isComplete = false
    private(set) var hintOpen = false
    /// After each Check the result shows big in the centre, then glides
    /// into its place (see CheckAlert).
    private(set) var checkAlert = CheckAlert.hidden
    /// The result shown in the alert, as it was when Check was pressed.
    private(set) var alertMessage: PadMessage?

    /// How long the result stays big in the centre. A visual pause only:
    /// Do 3 can be checked before Play and its tempo changes, so it is not
    /// tied to the music.
    static let alertHold: Duration = .seconds(1.5)

    @ObservationIgnored private let beatPlayer: any BeatPlaying

    init(beatPlayer: any BeatPlaying, brief: TempoBrief = .lateNight) {
        self.beatPlayer = beatPlayer
        self.brief = brief
        self.bpm = brief.startBPM
    }

    var isPlaying: Bool { beatPlayer.isLooping && !beatPlayer.isPaused }
    /// The zone drawn on the dial: only once a Check has revealed it.
    var shownZone: ClosedRange<Int>? { zoneRevealed ? brief.zone : nil }
    var primaryTitle: String { isComplete ? "Next" : "Check" }
    /// The dial and buttons wait while the result is on show.
    var inputsLocked: Bool { checkAlert != .hidden }
    var tempoFeels: [TempoFeel] { TempoFeel.all }

    /// The result under the dial: nothing before the first Check, then live
    /// as the dial moves, and the "fits" message once done.
    var feedback: PadMessage? {
        if isComplete {
            return PadMessage(symbol: "checkmark", title: brief.fitsTitle, detail: brief.fitsDetail, tone: .good)
        }
        guard zoneRevealed else { return nil }
        switch TempoZone.position(of: bpm, in: brief.zone) {
        case .above(let by):
            return PadMessage(symbol: "arrow.down", title: "Too fast",
                              detail: "\(by) BPM above the \(brief.zoneName) zone. Turn it down.", tone: .bad)
        case .below(let by):
            return PadMessage(symbol: "arrow.up", title: "Too slow",
                              detail: "\(by) BPM below the zone. Turn it up a little.", tone: .bad)
        case .inside:
            return PadMessage(symbol: "checkmark", title: "In the zone",
                              detail: "Press Check to lock it in.", tone: .good)
        }
    }

    /// The screen has appeared. Nothing autoplays: start fresh at the
    /// brief's tempo and get the audio ready.
    func enter() {
        beatPlayer.onStep = nil
        beatPlayer.stop()
        beatPlayer.resetDrumEffects()
        reset()
        beatPlayer.prepare()
    }

    /// Pause freezes the drums and Play carries on. If the drums are
    /// stopped they start again at the dial's tempo.
    func togglePlayPause() {
        if beatPlayer.isPaused {
            beatPlayer.resume()
        } else if beatPlayer.isLooping {
            beatPlayer.pause()
        } else {
            beatPlayer.startLoop(.lessonGroove, bpm: Double(bpm))
        }
    }

    /// Check: inside the zone finishes (the drums stop); outside reveals
    /// the zone and the live feedback.
    func check() {
        guard checkAlert == .hidden else { return }
        zoneRevealed = true
        hintOpen = false
        if TempoZone.position(of: bpm, in: brief.zone) == .inside {
            isComplete = true
            beatPlayer.stop()
        }
        alertMessage = feedback
        checkAlert = .showing
    }

    /// The hold is over: the result glides into its place.
    func checkAlertHoldEnded() {
        if checkAlert == .showing { checkAlert = .settling }
    }

    /// The result has settled into its place.
    func checkAlertDidSettle() {
        checkAlert = .hidden
    }

    func toggleHint() {
        hintOpen.toggle()
    }

    /// Leaving Do 3: stop the drums and put the tempo back to normal so
    /// later screens are not affected.
    func leave() {
        beatPlayer.stop()
        reset()
        beatPlayer.setTempo(TempoLimits.normal)
    }

    private func reset() {
        bpm = brief.startBPM
        zoneRevealed = false
        isComplete = false
        hintOpen = false
        checkAlert = .hidden
        alertMessage = nil
    }
}

/// The result alert after Check.
enum CheckAlert {
    case hidden
    /// Big in the centre, screen dimmed, inputs paused.
    case showing
    /// Gliding into the feedback's place.
    case settling
}
