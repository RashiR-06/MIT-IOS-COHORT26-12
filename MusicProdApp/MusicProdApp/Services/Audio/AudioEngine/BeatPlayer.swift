import AVFoundation
import Observation

/// Plays drum samples and loops patterns on one AVAudioEngine.
///
/// How the loop stays in time: every hit is given an exact sample time on
/// the audio clock before it plays (step n plays at n × step length). A
/// silent "clock" node also plays a tick on every step. When a tick has
/// been heard, we publish the step and queue the hits a few steps ahead.
/// Those callbacks only add future hits; they never decide when a hit
/// plays, so a late callback cannot make the beat drift.
@Observable
final class BeatPlayer: BeatPlaying {
    private(set) var isLooping = false
    private(set) var currentStep: Int?
    @ObservationIgnored var onStep: ((Int) -> Void)?

    var outputLatency: TimeInterval { session.outputLatency }

    /// How many steps are queued ahead of what you hear.
    private static let lookaheadSteps = 4
    /// A player node plays its buffers one after another, so a drum needs
    /// a few nodes ("voices") for hits that overlap. 3 covers ~150 BPM.
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

    // Loop state.
    @ObservationIgnored private var pattern = DrumPattern.lessonGroove
    @ObservationIgnored private var bpm = 100.0
    @ObservationIgnored private var nextStepNumber = 0
    @ObservationIgnored private var nextStepSeconds: TimeInterval = 0
    /// Changes on every start and stop, so ticks from an old loop are ignored.
    @ObservationIgnored private var loopID = 0

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

        // One set of voices per drum, each connected in that file's own format.
        for sound in DrumSound.allCases {
            do {
                let buffer = try DrumSampleLoader.load(sound)
                samples[sound] = buffer
                voices[sound] = (0..<Self.voicesPerDrum).map { _ in
                    let node = AVAudioPlayerNode()
                    engine.attach(node)
                    engine.connect(node, to: engine.mainMixerNode, format: buffer.format)
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

    func startLoop(_ pattern: DrumPattern, bpm: Double) {
        stop()
        guard startEngineIfNeeded(), !pattern.steps.isEmpty else { return }
        self.pattern = pattern
        self.bpm = bpm
        nextStepNumber = 0
        nextStepSeconds = 0
        loopID += 1
        isLooping = true

        // Start every node together, 0.1 s from now. From then on, each
        // node's own timeline counts samples from this shared moment.
        let delay = AVAudioTime.hostTime(forSeconds: 0.1)
        let startTime = AVAudioTime(hostTime: mach_absolute_time() + delay)
        for node in allNodes {
            node.stop()
            node.play(at: startTime)
        }

        for _ in 0..<Self.lookaheadSteps {
            scheduleNextStep()
        }
    }

    func stop() {
        loopID += 1
        isLooping = false
        currentStep = nil
        guard isSetUp else { return }
        for node in allNodes {
            node.stop()
        }
    }

    // MARK: - Scheduling

    /// Queues every hit of the next step, plus a clock tick, at the step's
    /// exact time on the audio clock.
    private func scheduleNextStep() {
        let step = nextStepNumber % pattern.steps.count
        let seconds = nextStepSeconds

        for hit in pattern.steps[step] {
            guard let buffer = sample(hit.sound, volume: hit.volume),
                  let node = takeVoice(for: hit.sound) else { continue }
            node.scheduleBuffer(buffer, at: Self.time(seconds, rate: buffer.format.sampleRate))
        }

        if let tick = tickBuffer {
            let id = loopID
            clockNode.scheduleBuffer(tick, at: Self.time(seconds, rate: tick.format.sampleRate),
                                     completionCallbackType: .dataPlayedBack) { [weak self] _ in
                // Arrives on an audio thread; hop to the main thread.
                guard let self else { return }
                Task { @MainActor in self.tickWasHeard(step: step, loopID: id) }
            }
        }

        nextStepNumber += 1
        nextStepSeconds += DrumPattern.stepDuration(bpm: bpm)
    }

    private func tickWasHeard(step: Int, loopID id: Int) {
        guard isLooping, id == loopID else { return }
        currentStep = step
        onStep?(step)
        scheduleNextStep()
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
