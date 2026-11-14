import AVFoundation
import Observation

/// Plays drum samples and loops patterns on one AVAudioEngine.
///
/// How the loop stays in time: every hit is given an exact sample time on
/// the audio clock before it plays. Each step's time is the previous step's
/// time plus one step length. A silent "clock" node also plays a tick on
/// every step. When a tick has been rendered, we publish the step and top
/// the queue up a little further. Those callbacks only add future hits;
/// they never decide when a hit plays, so a late callback cannot make the
/// beat drift.
///
/// Changing tempo: setTempo only changes the step length used for steps not
/// queued yet. Queued hits keep their times, so the new tempo starts at the
/// next step boundary with no stop, gap or double hit.
@Observable
final class BeatPlayer: BeatPlaying {
    private(set) var isLooping = false
    private(set) var isPaused = false
    private(set) var currentStep: Int?
    private(set) var bpm = 100.0
    @ObservationIgnored private(set) var currentStepSeconds: TimeInterval?
    @ObservationIgnored var onStep: ((Int) -> Void)?
    @ObservationIgnored var onFinish: (() -> Void)?

    var outputLatency: TimeInterval { session.outputLatency }

    /// Spare time between topping up the queue and the next hit it adds.
    /// Small, so tempo changes are heard quickly at any tempo.
    private static let safetyMargin: TimeInterval = 0.25
    /// A player node plays its buffers one after another, so a drum needs
    /// a few nodes ("voices") for hits that overlap. 3 covers 160 BPM.
    private static let voicesPerDrum = 3

    @ObservationIgnored private let engine = AVAudioEngine()
    @ObservationIgnored private let session = AudioSessionManager()
    @ObservationIgnored private var samples: [DrumSound: AVAudioPCMBuffer] = [:]
    @ObservationIgnored private var softerSamples: [String: AVAudioPCMBuffer] = [:]
    @ObservationIgnored private var voices: [DrumSound: [AVAudioPlayerNode]] = [:]
    @ObservationIgnored private var nextVoice: [DrumSound: Int] = [:]
    @ObservationIgnored private let clockNode = AVAudioPlayerNode()
    @ObservationIgnored private var tickBuffer: AVAudioPCMBuffer?
    @ObservationIgnored private var configObserver: NSObjectProtocol?
    /// Audio is set up on first use, not at app launch.
    @ObservationIgnored private var isSetUp = false

    // Drum effects: every drum voice goes through a small bus, then a pitch
    // shifter and a low-pass filter. Both are bypassed (off) unless a screen
    // such as the Intro switches them on.
    @ObservationIgnored private let drumBus = AVAudioMixerNode()
    /// Changes pitch without changing speed (rate stays 1), so hits keep
    /// their exact times on the audio clock.
    @ObservationIgnored private let pitchShift = AVAudioUnitTimePitch()
    @ObservationIgnored private let lowPass = AVAudioUnitEQ(numberOfBands: 1)
    private static let openCutoff: Float = 16_000
    /// Where the playhead stopped when paused, so the lane holds still.
    @ObservationIgnored private var pausedPlayheadBeats: Double?

    // Loop state.
    @ObservationIgnored private var pattern = DrumPattern.lessonGroove
    @ObservationIgnored private var nextStepNumber = 0
    /// Time of the most recently queued step, or nil before the first one.
    @ObservationIgnored private var lastQueuedSeconds: TimeInterval?
    /// The most recent queued steps and their exact times, used to work out
    /// the playhead position between steps.
    @ObservationIgnored private var stepTimes: [(step: Int, seconds: TimeInterval)] = []
    /// Changes on every start and stop, so ticks from an old loop are ignored.
    @ObservationIgnored private(set) var loopID = 0
    /// For a loop with a play length: when it ends, and whether its end
    /// has been booked.
    @ObservationIgnored private var loopEnd: TimeInterval?
    @ObservationIgnored private var loopEndQueued = false

    /// Cheap: only listens for notifications. No audio starts here, so app
    /// launch is never held up by the audio session or engine.
    init() {
        session.onMustStop = { [weak self] in self?.stop() }

        // A route or sample-rate change stops the engine; restart it.
        configObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.stop()
                self?.startEngineIfNeeded()
            }
        }
    }

    /// Loads the drums and builds the node graph the first time audio is needed.
    private func setUpIfNeeded() {
        guard !isSetUp else { return }
        isSetUp = true

        // Drum bus → pitch → low-pass → main mixer. Effects start bypassed.
        let busFormat = engine.mainMixerNode.outputFormat(forBus: 0)
        [drumBus, pitchShift, lowPass].forEach { engine.attach($0) }
        engine.connect(drumBus, to: pitchShift, format: busFormat)
        engine.connect(pitchShift, to: lowPass, format: busFormat)
        engine.connect(lowPass, to: engine.mainMixerNode, format: busFormat)
        lowPass.bands[0].filterType = .lowPass
        lowPass.bands[0].bypass = false
        resetDrumEffects()

        // One set of voices per drum, each connected in that file's own format.
        for sound in DrumSound.allCases {
            do {
                let buffer = try DrumSampleLoader.load(sound)
                samples[sound] = buffer
                voices[sound] = (0..<Self.voicesPerDrum).map { _ in
                    let node = AVAudioPlayerNode()
                    engine.attach(node)
                    engine.connect(node, to: drumBus, format: buffer.format)
                    return node
                }
                nextVoice[sound] = 0
            } catch {
                print("Could not load \(sound): \(error)")
            }
        }

        // The silent clock: a very short buffer of zeros at the output rate.
        let rate = engine.mainMixerNode.outputFormat(forBus: 0).sampleRate
        if let format = AVAudioFormat(standardFormatWithSampleRate: rate, channels: 1),
           let tick = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 64) {
            tick.frameLength = 64
            tickBuffer = tick
            engine.attach(clockNode)
            engine.connect(clockNode, to: engine.mainMixerNode, format: format)
        }

        engine.prepare()
    }

    // MARK: - BeatPlaying

    func prepare() {
        startEngineIfNeeded()
    }

    func play(_ sound: DrumSound) {
        guard startEngineIfNeeded(), let buffer = samples[sound], let node = takeVoice(for: sound) else { return }
        node.scheduleBuffer(buffer, at: nil)
        if !node.isPlaying { node.play() }
    }

    func startLoop(_ pattern: DrumPattern, bpm: Double, startDelay: TimeInterval, duration: TimeInterval?) {
        stop()
        guard startEngineIfNeeded(), !pattern.steps.isEmpty else { return }
        self.pattern = pattern
        self.bpm = Self.clamped(bpm)
        loopEnd = duration
        loopEndQueued = false
        nextStepNumber = 0
        lastQueuedSeconds = nil
        stepTimes = []
        loopID += 1
        isLooping = true

        // Start every node together, startDelay from now (booked on the
        // audio clock). From then on, each node's own timeline counts
        // samples from this shared moment.
        let delay = AVAudioTime.hostTime(forSeconds: max(startDelay, 0.05))
        let startTime = AVAudioTime(hostTime: mach_absolute_time() + delay)
        for node in allNodes {
            node.stop()
            node.play(at: startTime)
        }

        fillQueue(afterStep: -1, at: 0)
    }

    func setTempo(_ bpm: Double) {
        // Only the length of steps not queued yet changes; see the class note.
        self.bpm = Self.clamped(bpm)
    }

    func stop() {
        loopID += 1
        isLooping = false
        isPaused = false
        pausedPlayheadBeats = nil
        currentStep = nil
        currentStepSeconds = nil
        guard isSetUp else { return }
        for node in allNodes {
            node.stop()
        }
    }

    /// Freezes everything where it is. Pausing the engine pauses the audio
    /// clock itself, so every queued hit keeps its place.
    func pause() {
        guard isLooping, !isPaused else { return }
        pausedPlayheadBeats = playheadBeats
        engine.pause()
        isPaused = true
    }

    /// Carries on from exactly where pause stopped.
    func resume() {
        guard isPaused else { return }
        isPaused = false
        pausedPlayheadBeats = nil
        startEngineIfNeeded()
    }

    func setDrumEffects(pitchRatio: Double, lowPassCutoff: Double) {
        setUpIfNeeded()
        pitchShift.bypass = false
        lowPass.bypass = false
        // Pitch is in cents: 1200 cents is one octave.
        pitchShift.pitch = Float(1200 * log2(max(pitchRatio, 0.01)))
        lowPass.bands[0].frequency = Float(min(max(lowPassCutoff, 20), 20_000))
    }

    func resetDrumEffects() {
        pitchShift.rate = 1
        pitchShift.pitch = 0
        lowPass.bands[0].frequency = Self.openCutoff
        pitchShift.bypass = true
        lowPass.bypass = true
    }

    // MARK: - Scheduling

    /// Queues every hit of the next step, plus a clock tick, at the step's
    /// exact time on the audio clock.
    private func scheduleNextStep() {
        let stepNumber = nextStepNumber
        let step = stepNumber % pattern.steps.count
        let seconds = upcomingStepSeconds

        for hit in pattern.steps[step] {
            guard let buffer = sample(hit.sound, volume: hit.volume),
                  let node = takeVoice(for: hit.sound) else { continue }
            node.scheduleBuffer(buffer, at: Self.time(seconds, rate: buffer.format.sampleRate))
        }

        if let tick = tickBuffer {
            let id = loopID
            // .dataRendered fires as the tick is produced, before any
            // Bluetooth delay, so topping up the queue is never held back.
            clockNode.scheduleBuffer(tick, at: Self.time(seconds, rate: tick.format.sampleRate),
                                     completionCallbackType: .dataRendered) { [weak self] _ in
                // Arrives on an audio thread; hop to the main thread.
                guard let self else { return }
                Task { @MainActor in
                    self.tickWasRendered(stepNumber: stepNumber, step: step, at: seconds, loopID: id)
                }
            }
        }

        stepTimes.append((step: stepNumber, seconds: seconds))
        if stepTimes.count > 32 { stepTimes.removeFirst() }

        nextStepNumber += 1
        lastQueuedSeconds = seconds
    }

    /// When the next step would play: one step (at today's tempo) after the
    /// last queued step. Worked out at queue time, so a new tempo always
    /// starts at the next step that is not queued yet.
    private var upcomingStepSeconds: TimeInterval {
        guard let last = lastQueuedSeconds else { return 0 }
        return last + pattern.stepDuration(bpm: bpm)
    }

    private func tickWasRendered(stepNumber: Int, step: Int, at seconds: TimeInterval, loopID id: Int) {
        guard isLooping, id == loopID else { return }
        currentStep = step
        currentStepSeconds = seconds
        onStep?(step)
        fillQueue(afterStep: stepNumber, at: seconds)
    }

    /// Tops the queue up after a step has been rendered. Two rules:
    /// 1. Always keep at least one step queued after it, so the ticks (and
    ///    the loop) can never run out, even after a big tempo jump.
    /// 2. Keep about one step plus the safety margin of drums queued.
    private func fillQueue(afterStep stepNumber: Int, at seconds: TimeInterval) {
        let horizon = seconds + pattern.stepDuration(bpm: bpm) + Self.safetyMargin
        while nextStepNumber <= stepNumber + 1 || upcomingStepSeconds < horizon {
            // A loop with a play length queues no hits at or after its end;
            // a last silent tick at the end stops it.
            if let end = loopEnd, upcomingStepSeconds >= end - 0.000_1 {
                if !loopEndQueued { scheduleEnd(at: end) }
                return
            }
            scheduleNextStep()
        }
    }

    /// Books a silent tick at the loop's end; when it is rendered the loop
    /// stops and onFinish is called.
    private func scheduleEnd(at seconds: TimeInterval) {
        loopEndQueued = true
        guard let tick = tickBuffer else { return }
        let id = loopID
        clockNode.scheduleBuffer(tick, at: Self.time(seconds, rate: tick.format.sampleRate),
                                 completionCallbackType: .dataRendered) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                guard self.isLooping, id == self.loopID else { return }
                self.stop()
                self.onFinish?()
            }
        }
    }

    // MARK: - Playhead

    var playheadBeats: Double? {
        if isPaused { return pausedPlayheadBeats }
        guard isLooping, let now = heardSeconds, !stepTimes.isEmpty else { return nil }
        // The last queued step that has already started.
        guard let index = stepTimes.lastIndex(where: { $0.seconds <= now }) else { return 0 }
        let current = stepTimes[index]
        // The next step's real time, so a tempo change bends the motion
        // at the step boundary instead of jumping.
        let nextSeconds = index + 1 < stepTimes.count
            ? stepTimes[index + 1].seconds
            : current.seconds + pattern.stepDuration(bpm: bpm)
        let fraction = min(max((now - current.seconds) / (nextSeconds - current.seconds), 0), 1)
        return (Double(current.step) + fraction) / Double(pattern.stepsPerBeat)
    }

    func loopSeconds(heardAt uptime: TimeInterval) -> TimeInterval? {
        guard isLooping, !isPaused else { return nil }
        return heardLoopSeconds(at: uptime)
    }

    /// The loop's time that is reaching your ears now. The time since the
    /// last render is kept between 0 and 0.05 s so the playhead never runs
    /// ahead if rendering stalls.
    private var heardSeconds: TimeInterval? {
        heardLoopSeconds(at: AVAudioTime.seconds(forHostTime: mach_absolute_time()), sinceRenderLimit: 0...0.05)
    }

    /// The loop's time that reached your ears at a moment on the host clock
    /// (seconds since the phone started): the last rendered moment on the
    /// clock node's timeline, plus the time between that render and the
    /// moment, minus the output latency.
    private func heardLoopSeconds(at hostSeconds: TimeInterval,
                                  sinceRenderLimit: ClosedRange<TimeInterval>? = nil) -> TimeInterval? {
        guard let render = clockNode.lastRenderTime, render.isHostTimeValid,
              let player = clockNode.playerTime(forNodeTime: render) else { return nil }
        var sinceRender = hostSeconds - AVAudioTime.seconds(forHostTime: render.hostTime)
        if let limit = sinceRenderLimit {
            sinceRender = min(max(sinceRender, limit.lowerBound), limit.upperBound)
        }
        let rendered = Double(player.sampleTime) / player.sampleRate
        // The pitch shifter delays the drums a little while it is on.
        let effectDelay = pitchShift.bypass ? 0 : pitchShift.auAudioUnit.latency
        return rendered + sinceRender - session.outputLatency - effectDelay
    }

    private static func clamped(_ bpm: Double) -> Double {
        min(max(bpm, TempoLimits.range.lowerBound), TempoLimits.range.upperBound)
    }

    /// A sample-accurate time on a node's own timeline.
    private static func time(_ seconds: TimeInterval, rate: Double) -> AVAudioTime {
        AVAudioTime(sampleTime: AVAudioFramePosition(seconds * rate), atRate: rate)
    }

    // MARK: - Helpers

    /// Every attached player node (the clock only if it was set up).
    private var allNodes: [AVAudioPlayerNode] {
        let drums = voices.values.flatMap { $0 }
        return clockNode.engine == nil ? drums : drums + [clockNode]
    }

    /// Picks the next voice for a drum, in turn.
    private func takeVoice(for sound: DrumSound) -> AVAudioPlayerNode? {
        guard let nodes = voices[sound], let index = nextVoice[sound] else { return nil }
        nextVoice[sound] = (index + 1) % nodes.count
        return nodes[index]
    }

    /// The sample at a given volume. Quieter copies are made once and kept.
    private func sample(_ sound: DrumSound, volume: Float) -> AVAudioPCMBuffer? {
        guard let original = samples[sound] else { return nil }
        if volume == 1 { return original }
        let key = "\(sound)-\(volume)"
        if let cached = softerSamples[key] { return cached }
        guard let copy = AVAudioPCMBuffer(pcmFormat: original.format, frameCapacity: original.frameLength),
              let source = original.floatChannelData, let target = copy.floatChannelData else { return nil }
        copy.frameLength = original.frameLength
        for channel in 0..<Int(original.format.channelCount) {
            for frame in 0..<Int(original.frameLength) {
                target[channel][frame] = source[channel][frame] * volume
            }
        }
        softerSamples[key] = copy
        return copy
    }

    @discardableResult
    private func startEngineIfNeeded() -> Bool {
        setUpIfNeeded()
        if engine.isRunning { return true }
        session.activate()
        do {
            try engine.start()
            return true
        } catch {
            print("Audio engine could not start: \(error)")
            return false
        }
    }
}
