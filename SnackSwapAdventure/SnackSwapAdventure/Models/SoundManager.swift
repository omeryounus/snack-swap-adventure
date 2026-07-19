import AVFoundation
import SpriteKit

/// Central SFX player for juicy match-3 feedback.
/// Preloads short WAVs and plays them with light pitch variation so repeats stay fresh.
@MainActor
final class SoundManager {
    static let shared = SoundManager()

    enum Effect: String, CaseIterable {
        case select
        case swap
        case invalid
        case match
        case combo2
        case combo3
        case land
        case win
        case lose
        case uiTap = "ui_tap"
        case timerTick = "timer_tick"
        case timerUrgent = "timer_urgent"
        case timerExpire = "timer_expire"
        case extend
        case special
    }

    private var players: [Effect: [AVAudioPlayer]] = [:]
    private var enabled = true
    private let poolSize = 4

    private init() {
        configureSession()
        preloadAll()
    }

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            // Non-fatal: sounds simply won't play if session setup fails.
            print("SoundManager: audio session error \(error)")
        }
    }

    private func preloadAll() {
        for effect in Effect.allCases {
            var pool: [AVAudioPlayer] = []
            for _ in 0..<poolSize {
                if let player = makePlayer(for: effect) {
                    pool.append(player)
                }
            }
            players[effect] = pool
        }
    }

    private func makePlayer(for effect: Effect) -> AVAudioPlayer? {
        let name = effect.rawValue
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav")
                ?? Bundle.main.url(forResource: name, withExtension: "wav", subdirectory: "Sounds")
                ?? Bundle.main.url(forResource: name, withExtension: "wav", subdirectory: "Resources/Sounds")
        else {
            print("SoundManager: missing \(name).wav")
            return nil
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.volume = 1.0
            return player
        } catch {
            print("SoundManager: failed to load \(name): \(error)")
            return nil
        }
    }

    func setEnabled(_ on: Bool) {
        enabled = on
    }

    func play(_ effect: Effect, volume: Float = 1.0, rate: Float = 1.0) {
        guard enabled, MetaProgress.shared.soundEnabled else { return }
        guard let pool = players[effect], !pool.isEmpty else { return }

        // Prefer an idle player so overlapping pops don't cut each other off.
        let player = pool.first(where: { !$0.isPlaying }) ?? pool.randomElement()!
        player.stop()
        player.currentTime = 0
        player.volume = min(1.0, max(0.0, volume))
        player.enableRate = true
        player.rate = min(2.0, max(0.5, rate))
        player.play()
    }

    /// Match / cascade SFX that steps up with combo depth.
    func playMatch(cascadeDepth: Int) {
        switch cascadeDepth {
        case 0:
            play(.match, volume: 0.9, rate: 1.0 + Float.random(in: -0.04...0.04))
        case 1:
            play(.combo2, volume: 0.95, rate: 1.0 + Float.random(in: -0.03...0.05))
        default:
            play(.combo3, volume: 1.0, rate: 1.0 + Float.random(in: 0...0.08))
        }
    }

    func playSelect() {
        play(.select, volume: 0.55, rate: 1.0 + Float.random(in: -0.05...0.08))
    }

    func playSwap() {
        play(.swap, volume: 0.7, rate: 1.0 + Float.random(in: -0.03...0.03))
    }

    func playInvalid() {
        play(.invalid, volume: 0.65)
    }

    func playLand() {
        play(.land, volume: 0.35, rate: 1.0 + Float.random(in: -0.06...0.06))
    }

    func playWin() {
        play(.win, volume: 1.0)
    }

    func playLose() {
        play(.lose, volume: 0.85)
    }

    func playUITap() {
        play(.uiTap, volume: 0.55)
    }

    func playTimerTick(urgent: Bool = false) {
        if urgent {
            play(.timerUrgent, volume: 0.45)
        } else {
            play(.timerTick, volume: 0.28)
        }
    }

    func playTimerExpire() {
        play(.timerExpire, volume: 0.85)
    }

    func playExtend() {
        play(.extend, volume: 0.9)
    }

    func playSpecial() {
        play(.special, volume: 0.85, rate: 1.0 + Float.random(in: -0.04...0.06))
    }
}
