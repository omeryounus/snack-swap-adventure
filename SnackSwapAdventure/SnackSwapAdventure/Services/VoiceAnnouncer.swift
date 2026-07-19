import AVFoundation
import Foundation

/// Spoken praise lines that scale with match quality / combo depth.
@MainActor
final class VoiceAnnouncer: NSObject {
    static let shared = VoiceAnnouncer()

    private let synthesizer = AVSpeechSynthesizer()
    private var lastSpeakAt: Date = .distantPast
    private let minGap: TimeInterval = 0.55

    private override init() {
        super.init()
    }

    /// cascadeDepth: 0 = first clear, 1 = 2x, 2 = 3x…
    /// matchedCount: how many tiles cleared this step
    /// specialsActivated: special tiles triggered
    func praiseMatch(cascadeDepth: Int, matchedCount: Int, specialsActivated: Int = 0) {
        guard MetaProgress.shared.soundEnabled else { return }

        let phrase = Self.phrase(
            cascadeDepth: cascadeDepth,
            matchedCount: matchedCount,
            specialsActivated: specialsActivated
        )
        guard let phrase else { return }

        // Avoid overlapping spam on ultra-fast cascades
        let now = Date()
        if now.timeIntervalSince(lastSpeakAt) < minGap, cascadeDepth < 3 {
            return
        }
        lastSpeakAt = now

        // Stop previous line so higher combos interrupt lower ones
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .word)
        }

        let utterance = AVSpeechUtterance(string: phrase)
        utterance.voice = preferredVoice()
        utterance.rate = Self.rate(for: cascadeDepth)
        utterance.pitchMultiplier = Self.pitch(for: cascadeDepth)
        utterance.volume = 0.95
        utterance.preUtteranceDelay = 0.02
        utterance.postUtteranceDelay = 0.01

        synthesizer.speak(utterance)
    }

    func praiseWin() {
        guard MetaProgress.shared.soundEnabled else { return }
        speak("Fantastic work!", rate: 0.48, pitch: 1.15)
    }

    private func speak(_ text: String, rate: Float, pitch: Float) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = preferredVoice()
        utterance.rate = rate
        utterance.pitchMultiplier = pitch
        utterance.volume = 0.95
        synthesizer.speak(utterance)
    }

    private func preferredVoice() -> AVSpeechSynthesisVoice? {
        // Prefer a lively English voice when available.
        let preferredIds = [
            "com.apple.voice.compact.en-US.Samantha",
            "com.apple.ttsbundle.siri_female_en-US_compact",
            "com.apple.ttsbundle.Samantha-compact"
        ]
        for id in preferredIds {
            if let v = AVSpeechSynthesisVoice(identifier: id) { return v }
        }
        return AVSpeechSynthesisVoice(language: "en-US")
            ?? AVSpeechSynthesisVoice(language: "en-GB")
    }

    // MARK: - Phrase selection

    /// Returns a spoken line, or nil for tiny boring matches.
    private static func phrase(
        cascadeDepth: Int,
        matchedCount: Int,
        specialsActivated: Int
    ) -> String? {
        // Score how "impressive" this clear is.
        let score = cascadeDepth * 3 + max(0, matchedCount - 3) + specialsActivated * 2

        // Quiet base 3-matches: only sometimes cheer so it stays special.
        if score <= 0 {
            if matchedCount >= 4 {
                return ["Quick!", "Clever!", "Nice!"].randomElement()
            }
            // 3-match: rare soft praise
            return Bool.random() ? nil : ["Good!", "Nice!"].randomElement()
        }

        switch cascadeDepth {
        case 1:
            // 2x combo
            return [
                "Amazing!",
                "Superb!",
                "Clever!",
                "Quick!",
                "Nice one!"
            ].randomElement()
        case 2:
            // 3x
            return [
                "Fantastic!",
                "Superb!",
                "Amazing!",
                "So clever!"
            ].randomElement()
        case 3:
            // 4x
            return [
                "Insane!",
                "Fantastic!",
                "Super intelligent!",
                "Genius!"
            ].randomElement()
        case 4:
            // 5x
            return [
                "Insane!",
                "Genius!",
                "Super intelligent!",
                "Absolutely amazing!"
            ].randomElement()
        default:
            // 6x+
            return [
                "Genius!",
                "Insane!",
                "Super intelligent!",
                "Unbelievable!",
                "You are a genius!"
            ].randomElement()
        }
    }

    private static func rate(for cascadeDepth: Int) -> Float {
        // Slightly faster and punchier as combos climb.
        switch cascadeDepth {
        case 0: return 0.50
        case 1: return 0.52
        case 2: return 0.54
        case 3: return 0.56
        default: return 0.58
        }
    }

    private static func pitch(for cascadeDepth: Int) -> Float {
        switch cascadeDepth {
        case 0: return 1.05
        case 1: return 1.12
        case 2: return 1.18
        case 3: return 1.22
        default: return 1.28
        }
    }
}
