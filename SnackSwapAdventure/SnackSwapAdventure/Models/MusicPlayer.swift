import AVFoundation
import Foundation

/// Lightweight procedural background loop with a bright, playful confectionery feel.
/// Falls back silently if no music file is present and generation is unavailable.
@MainActor
final class MusicPlayer {
    static let shared = MusicPlayer()

    private var player: AVAudioPlayer?
    private var isPlaying = false

    private init() {
        // Prefer an authored loop if one is bundled; otherwise generate the current
        // version into Caches so the music can evolve without a large binary asset.
        if let url = Bundle.main.url(forResource: "music_loop", withExtension: "wav")
            ?? Bundle.main.url(forResource: "music_loop", withExtension: "wav", subdirectory: "Sounds") {
            player = try? AVAudioPlayer(contentsOf: url)
        } else if let url = Self.ensureGeneratedLoop() {
            player = try? AVAudioPlayer(contentsOf: url)
        }
        player?.numberOfLoops = -1
        player?.volume = 0.20
        player?.prepareToPlay()
    }

    func play() {
        guard MetaProgress.shared.musicEnabled else { return }
        guard !isPlaying else { return }
        player?.play()
        isPlaying = true
    }

    func stop() {
        player?.stop()
        isPlaying = false
    }

    func toggle() {
        if isPlaying { stop() } else { play() }
    }

    /// Generates a cheerful 8-bar loop in Caches if an authored track is absent.
    private static func ensureGeneratedLoop() -> URL? {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        guard let dir else { return nil }
        let url = dir.appendingPathComponent("ssa_music_loop_delight_v2.wav")
        if FileManager.default.fileExists(atPath: url.path) { return url }

        let sampleRate = 22050
        let duration = 16.0
        let bpm = 120.0
        let beat = 60.0 / bpm
        let n = Int(duration * Double(sampleRate))
        var samples = [Int16](repeating: 0, count: n)
        let chords: [(root: Double, notes: [Double])] = [
            (130.81, [261.63, 329.63, 392.00]), // C
            (98.00, [196.00, 246.94, 293.66]),  // G
            (110.00, [220.00, 261.63, 329.63]),  // Am
            (87.31, [174.61, 220.00, 261.63])    // F
        ]

        // A compact melody that stays inside the chord progression and gives the
        // loop a recognizable, upbeat game identity.
        let melody: [Double] = [
            659.25, 783.99, 880.00, 783.99, 659.25, 587.33, 523.25, 587.33,
            587.33, 659.25, 783.99, 659.25, 587.33, 523.25, 493.88, 523.25,
            659.25, 783.99, 880.00, 987.77, 880.00, 783.99, 659.25, 587.33,
            698.46, 783.99, 880.00, 783.99, 698.46, 659.25, 587.33, 523.25
        ]
        let eighth = beat / 2

        for idx in 0..<n {
            let t = Double(idx) / Double(sampleRate)
            let beatPosition = t / beat
            let bar = Int(beatPosition / 4.0) % chords.count
            let chord = chords[bar]

            // Slow, warm chord bed with a gentle fifth shimmer.
            var value = 0.0
            for (noteIndex, frequency) in chord.notes.enumerated() {
                let detune = frequency * (1.0 + Double(noteIndex - 1) * 0.0015)
                value += sin(2 * .pi * detune * t) * (noteIndex == 1 ? 0.035 : 0.028)
                value += sin(2 * .pi * detune * 2.0 * t) * 0.006
            }

            // Rounded bass pulse on each beat keeps the board moving without
            // competing with match and combo sound effects.
            let beatTime = beatPosition.truncatingRemainder(dividingBy: 1.0)
            let bassEnvelope = exp(-5.5 * beatTime)
            value += sin(2 * .pi * chord.root * t) * 0.075 * bassEnvelope

            // Plucked melody with a tiny attack ramp to prevent clicks.
            let melodyPosition = t / eighth
            let melodyIndex = Int(melodyPosition) % melody.count
            let melodyTime = melodyPosition.truncatingRemainder(dividingBy: 1.0) * eighth
            let melodyEnvelope = min(1.0, melodyTime * 90.0) * exp(-7.0 * melodyTime)
            let melodyFrequency = melody[melodyIndex]
            value += sin(2 * .pi * melodyFrequency * melodyTime) * 0.09 * melodyEnvelope
            value += sin(2 * .pi * melodyFrequency * 2.0 * melodyTime) * 0.018 * melodyEnvelope

            // Soft sparkle at the end of every second bar.
            let barTime = t.truncatingRemainder(dividingBy: beat * 8.0)
            let sparkleTime = barTime - beat * 7.0
            if sparkleTime >= 0, sparkleTime < 0.45 {
                let sparkleEnvelope = exp(-8.0 * sparkleTime)
                value += sin(2 * .pi * 1318.51 * sparkleTime) * 0.035 * sparkleEnvelope
                value += sin(2 * .pi * 1567.98 * sparkleTime) * 0.022 * sparkleEnvelope
            }

            // A tiny fade at the loop boundary makes the repeat seamless.
            let edgeFade = min(1.0, t * 12.0, (duration - t) * 12.0)
            let sample = max(-1.0, min(1.0, value * edgeFade))
            samples[idx] = Int16(sample * Double(Int16.max))
        }

        // Write minimal WAV
        var data = Data()
        func appendU32(_ v: UInt32) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }
        func appendU16(_ v: UInt16) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }
        let dataSize = UInt32(samples.count * 2)
        data.append(contentsOf: Array("RIFF".utf8))
        appendU32(36 + dataSize)
        data.append(contentsOf: Array("WAVE".utf8))
        data.append(contentsOf: Array("fmt ".utf8))
        appendU32(16)
        appendU16(1)
        appendU16(1)
        appendU32(UInt32(sampleRate))
        appendU32(UInt32(sampleRate * 2))
        appendU16(2)
        appendU16(16)
        data.append(contentsOf: Array("data".utf8))
        appendU32(dataSize)
        for s in samples {
            withUnsafeBytes(of: s.littleEndian) { data.append(contentsOf: $0) }
        }
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}
