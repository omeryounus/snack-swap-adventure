import AVFoundation
import Foundation

/// Lightweight procedural-ish background loop using a bundled soft tone chain.
/// Falls back silently if no music file is present.
@MainActor
final class MusicPlayer {
    static let shared = MusicPlayer()

    private var player: AVAudioPlayer?
    private var isPlaying = false

    private init() {
        // Prefer optional bundled loop; otherwise synthesize a short soft pad WAV at runtime once.
        if let url = Bundle.main.url(forResource: "music_loop", withExtension: "wav")
            ?? Bundle.main.url(forResource: "music_loop", withExtension: "wav", subdirectory: "Sounds") {
            player = try? AVAudioPlayer(contentsOf: url)
        } else if let url = Self.ensureGeneratedLoop() {
            player = try? AVAudioPlayer(contentsOf: url)
        }
        player?.numberOfLoops = -1
        player?.volume = 0.22
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

    /// Generates a gentle multi-tone pad loop in Caches if missing.
    private static func ensureGeneratedLoop() -> URL? {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        guard let dir else { return nil }
        let url = dir.appendingPathComponent("ssa_music_loop.wav")
        if FileManager.default.fileExists(atPath: url.path) { return url }

        let sampleRate = 22050
        let duration = 6.0
        let n = Int(duration * Double(sampleRate))
        var samples = [Int16](repeating: 0, count: n)
        let chords: [(Double, Double, Double)] = [
            (261.63, 329.63, 392.00),
            (293.66, 349.23, 440.00),
            (246.94, 311.13, 392.00),
            (261.63, 349.23, 415.30)
        ]
        let seg = n / chords.count
        for (ci, chord) in chords.enumerated() {
            for i in 0..<seg {
                let idx = ci * seg + i
                guard idx < n else { break }
                let t = Double(i) / Double(sampleRate)
                let env = sin(Double.pi * Double(i) / Double(seg))
                let v = (sin(2 * .pi * chord.0 * t)
                         + 0.6 * sin(2 * .pi * chord.1 * t)
                         + 0.4 * sin(2 * .pi * chord.2 * t)) * 0.12 * env
                samples[idx] = Int16(max(-1, min(1, v)) * Double(Int16.max))
            }
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
