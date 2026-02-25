import AVFoundation

@MainActor
final class SoundManager {

    static let shared = SoundManager()

    private var bgmPlayer: AVAudioPlayer?
    private var audioEngine: AVAudioEngine
    private let sampleRate: Double = 44100

    // Separate player node per sound type so they can overlap
    private var jumpNode: AVAudioPlayerNode
    private var scoreNode: AVAudioPlayerNode
    private var goldenNode: AVAudioPlayerNode
    private var gameOverNode: AVAudioPlayerNode

    // Pre-rendered buffers
    private var jumpBuffer: AVAudioPCMBuffer!
    private var scoreBuffer: AVAudioPCMBuffer!
    private var goldenBuffer: AVAudioPCMBuffer!
    private var gameOverBuffer: AVAudioPCMBuffer!

    private init() {
        audioEngine = AVAudioEngine()
        jumpNode = AVAudioPlayerNode()
        scoreNode = AVAudioPlayerNode()
        goldenNode = AVAudioPlayerNode()
        gameOverNode = AVAudioPlayerNode()

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        for node in [jumpNode, scoreNode, goldenNode, gameOverNode] {
            audioEngine.attach(node)
            audioEngine.connect(node, to: audioEngine.mainMixerNode, format: format)
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            try audioEngine.start()
            for node in [jumpNode, scoreNode, goldenNode, gameOverNode] {
                node.play()
            }
        } catch {
            print("SoundManager: audio engine start failed: \(error)")
        }

        // Pre-render all buffers at init
        jumpBuffer = generateSweepBuffer(
            waveform: .triangle,
            startFreq: 300, endFreq: 600,
            sweepDuration: 0.15, totalDuration: 0.2,
            startVolume: 0.15, endVolume: 0.01
        )
        scoreBuffer = generateTwoToneBuffer(
            waveform: .sine,
            freq1: 523, freq2: 659,
            switchTime: 0.08, totalDuration: 0.2,
            startVolume: 0.12, endVolume: 0.01
        )
        goldenBuffer = generateMultiNoteBuffer(
            waveform: .sine,
            notes: [(523, 0.0, 0.15), (659, 0.08, 0.15), (784, 0.16, 0.15)],
            totalDuration: 0.31,
            peakVolume: 0.15, rampUp: 0.02
        )
        gameOverBuffer = generateMultiNoteBuffer(
            waveform: .square,
            notes: [(400, 0.0, 0.25), (300, 0.15, 0.25), (200, 0.30, 0.25)],
            totalDuration: 0.55,
            peakVolume: 0.10, rampUp: 0.02
        )
    }

    // MARK: - BGM

    func startBGM() {
        guard let url = Bundle.main.url(forResource: "Pixel_Pulse_Panic", withExtension: "mp3") else {
            print("SoundManager: BGM file not found")
            return
        }
        do {
            bgmPlayer = try AVAudioPlayer(contentsOf: url)
            bgmPlayer?.numberOfLoops = -1
            bgmPlayer?.volume = 0.4
            bgmPlayer?.play()
        } catch {
            print("SoundManager: BGM play failed: \(error)")
        }
    }

    func stopBGM() {
        bgmPlayer?.stop()
        bgmPlayer?.currentTime = 0
    }

    // MARK: - Synth Effects

    func playJumpSound() {
        playOnNode(jumpNode, buffer: jumpBuffer)
    }

    func playScoreSound() {
        playOnNode(scoreNode, buffer: scoreBuffer)
    }

    func playGoldenSound() {
        playOnNode(goldenNode, buffer: goldenBuffer)
    }

    func playGameOverSound() {
        playOnNode(gameOverNode, buffer: gameOverBuffer)
    }

    private func playOnNode(_ node: AVAudioPlayerNode, buffer: AVAudioPCMBuffer) {
        if !audioEngine.isRunning {
            do {
                try audioEngine.start()
                for n in [jumpNode, scoreNode, goldenNode, gameOverNode] {
                    n.play()
                }
            } catch {
                return
            }
        }
        // Interrupt any currently playing buffer on this node
        node.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
    }

    // MARK: - Buffer Generation

    private enum Waveform {
        case sine, triangle, square
    }

    private func waveformSample(_ type: Waveform, phase: Double) -> Double {
        switch type {
        case .sine:
            return sin(phase)
        case .triangle:
            let p = phase / (.pi * 2)
            let frac = p - floor(p)
            return frac < 0.5 ? (4 * frac - 1) : (3 - 4 * frac)
        case .square:
            let p = phase / (.pi * 2)
            let frac = p - floor(p)
            return frac < 0.5 ? 1.0 : -1.0
        }
    }

    private func generateSweepBuffer(
        waveform: Waveform,
        startFreq: Double, endFreq: Double,
        sweepDuration: Double, totalDuration: Double,
        startVolume: Double, endVolume: Double
    ) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(sampleRate * totalDuration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let data = buffer.floatChannelData![0]
        var phase = 0.0

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let freqT = min(t / sweepDuration, 1.0)
            let freq = startFreq * pow(endFreq / startFreq, freqT)
            let volT = t / totalDuration
            let vol = startVolume * pow(endVolume / startVolume, volT)

            let sample = waveformSample(waveform, phase: phase) * vol
            data[i] = Float(sample)
            phase += 2.0 * .pi * freq / sampleRate
        }
        return buffer
    }

    private func generateTwoToneBuffer(
        waveform: Waveform,
        freq1: Double, freq2: Double,
        switchTime: Double, totalDuration: Double,
        startVolume: Double, endVolume: Double
    ) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(sampleRate * totalDuration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let data = buffer.floatChannelData![0]
        var phase = 0.0

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let freq = t < switchTime ? freq1 : freq2
            let volT = t / totalDuration
            let vol = startVolume * pow(max(endVolume / startVolume, 0.001), volT)

            let sample = waveformSample(waveform, phase: phase) * vol
            data[i] = Float(sample)
            phase += 2.0 * .pi * freq / sampleRate
        }
        return buffer
    }

    private func generateMultiNoteBuffer(
        waveform: Waveform,
        notes: [(freq: Double, start: Double, dur: Double)],
        totalDuration: Double,
        peakVolume: Double,
        rampUp: Double
    ) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(sampleRate * totalDuration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let data = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            data[i] = 0
        }

        for note in notes {
            var phase = 0.0
            let startFrame = Int(note.start * sampleRate)
            let endFrame = min(Int((note.start + note.dur) * sampleRate), Int(frameCount))

            for i in startFrame..<endFrame {
                let localT = Double(i - startFrame) / sampleRate
                var vol: Double
                if localT < rampUp {
                    vol = peakVolume * (localT / rampUp)
                } else {
                    let decay = (localT - rampUp) / (note.dur - rampUp)
                    vol = peakVolume * pow(max(0.01 / peakVolume, 0.001), decay)
                }
                let sample = waveformSample(waveform, phase: phase) * vol
                data[i] += Float(sample)
                phase += 2.0 * .pi * note.freq / sampleRate
            }
        }
        return buffer
    }
}
