import AVFoundation
import Combine

/// Generates click sounds using AVAudioEngine for sample-accurate timing.
final class AudioEngine: ObservableObject {
    static let shared = AudioEngine()

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var clickBuffer: AVAudioPCMBuffer!
    private var accentBuffer: AVAudioPCMBuffer!
    private var subdivisionBuffer: AVAudioPCMBuffer!

    private var timer: DispatchSourceTimer?
    private let timerQueue = DispatchQueue(label: "metronome.timer", qos: .userInteractive)

    @Published var isPlaying = false
    @Published var currentBeat: Int = 0
    @Published var currentSubdivision: Int = 0

    var bpm: Double = 120
    var beatsPerMeasure: Int = 4
    var subdivision: Int = 1 // 1 = none, 2 = eighth, 3 = triplet, 4 = sixteenth

    private var beatIndex = 0
    private var subIndex = 0

    init() {
        setupAudioSession()
        generateBuffers()
        setupEngine()
    }

    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [])
        try? session.setPreferredIOBufferDuration(0.005)
        try? session.setActive(true)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: session
        )
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        if type == .ended {
            try? AVAudioSession.sharedInstance().setActive(true)
            if isPlaying {
                if !engine.isRunning { try? engine.start() }
                playerNode.play()
                scheduleTick()
                startTimer()
            }
        }
    }

    private func generateBuffers() {
        let sampleRate: Double = 44100
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        accentBuffer = synthesizeTone(frequency: 1200, duration: 0.04, sampleRate: sampleRate, format: format)
        clickBuffer = synthesizeTone(frequency: 880, duration: 0.03, sampleRate: sampleRate, format: format)
        subdivisionBuffer = synthesizeTone(frequency: 660, duration: 0.02, sampleRate: sampleRate, format: format, volume: 0.5)
    }

    private func synthesizeTone(frequency: Double, duration: Double, sampleRate: Double, format: AVAudioFormat, volume: Float = 0.8) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope = Float(max(0, 1.0 - t / duration))
            let sample = Float(sin(2.0 * .pi * frequency * t))
            data[i] = sample * envelope * envelope * volume
        }
        return buffer
    }

    private func setupEngine() {
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: clickBuffer.format)
        try? engine.start()
    }

    func start() {
        guard !isPlaying else { return }
        isPlaying = true
        beatIndex = 0
        subIndex = 0

        if !engine.isRunning {
            try? engine.start()
        }
        playerNode.play()

        scheduleTick()
        startTimer()
    }

    func stop() {
        isPlaying = false
        timer?.cancel()
        timer = nil
        playerNode.stop()

        DispatchQueue.main.async {
            self.currentBeat = 0
            self.currentSubdivision = 0
        }
    }

    private func startTimer() {
        timer?.cancel()
        let interval = tickInterval
        let t = DispatchSource.makeTimerSource(queue: timerQueue)
        t.schedule(deadline: .now() + interval, repeating: interval)
        t.setEventHandler { [weak self] in
            self?.tick()
        }
        t.resume()
        timer = t
    }

    private var tickInterval: TimeInterval {
        let beatDuration = 60.0 / bpm
        return beatDuration / Double(subdivision)
    }

    private func tick() {
        subIndex += 1
        if subIndex >= subdivision {
            subIndex = 0
            beatIndex = (beatIndex + 1) % beatsPerMeasure
        }
        scheduleTick()
    }

    private func scheduleTick() {
        let buffer: AVAudioPCMBuffer
        if subIndex == 0 && beatIndex == 0 {
            buffer = accentBuffer
        } else if subIndex == 0 {
            buffer = clickBuffer
        } else {
            buffer = subdivisionBuffer
        }

        playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)

        DispatchQueue.main.async {
            self.currentBeat = self.beatIndex
            self.currentSubdivision = self.subIndex
        }
    }

    /// Updates the timer interval without stopping playback.
    func updateTiming() {
        guard isPlaying else { return }
        startTimer()
    }

    deinit {
        timer?.cancel()
        engine.stop()
    }
}
