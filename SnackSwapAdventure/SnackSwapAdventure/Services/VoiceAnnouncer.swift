import AVFoundation
import Foundation

/// Pre-recorded voice announcer that plays Firefly-generated WAV clips
/// instead of on-device TTS synthesis.
@MainActor
final class VoiceAnnouncer: NSObject {
    static let shared = VoiceAnnouncer()

    // MARK: - Voice clip catalog

    /// All available pre-recorded voice clips
    enum Clip: String, CaseIterable {
        case nice           = "vo_nice"
        case sweet          = "vo_sweet"
        case fantastic      = "vo_fantastic"
        case amazing        = "vo_amazing"
        case streak         = "vo_streak"
        case levelStart     = "vo_level_start"
        case halfway        = "vo_halfway"
        case almost         = "vo_almost"
        case thirtySec      = "vo_thirty_sec"
        case tenSec         = "vo_ten_sec"
        case win            = "vo_win"
        case lose           = "vo_lose"
        case threeStars     = "vo_three_stars"
        case highScore      = "vo_high_score"
    }

    // MARK: - Playback state

    private var player: AVAudioPlayer?
    private var lastPlayedAt: Date = .distantPast
    private let minGap: TimeInterval = 0.55

    // MARK: - Cascade tracking

    private var maxCascadeDepthThisMove = -1
    private var maxMatchedCountThisMove = 0
    private var totalSpecialsActivatedThisMove = 0

    private override init() {
        super.init()
    }

    // MARK: - Public API (unchanged signatures)

    /// Reset cascade tracking at the beginning of a move
    func resetCascadeTracking() {
        maxCascadeDepthThisMove = -1
        maxMatchedCountThisMove = 0
        totalSpecialsActivatedThisMove = 0
    }

    /// Track each step in the cascade
    func trackCascadeStep(cascadeDepth: Int, matchedCount: Int, specialsActivated: Int) {
        maxCascadeDepthThisMove = max(maxCascadeDepthThisMove, cascadeDepth)
        maxMatchedCountThisMove = max(maxMatchedCountThisMove, matchedCount)
        totalSpecialsActivatedThisMove += specialsActivated
    }

    /// Announce the final combo reached during this move
    func announceFinalCombo() {
        guard maxCascadeDepthThisMove >= 0 else { return }

        let depth = maxCascadeDepthThisMove
        let count = maxMatchedCountThisMove
        let specials = totalSpecialsActivatedThisMove

        // Reset immediately for the next move
        resetCascadeTracking()

        praiseMatch(cascadeDepth: depth, matchedCount: count, specialsActivated: specials)
    }

    // MARK: - Gameplay event hooks

    func praiseWin() {
        playClip(.win)
    }

    func praiseLose() {
        playClip(.lose)
    }

    func announceLevelStart() {
        playClip(.levelStart)
    }

    func announceHalfway() {
        playClip(.halfway, respectGap: true)
    }

    func announceAlmostDone() {
        playClip(.almost, respectGap: true)
    }

    func announceThirtySeconds() {
        playClip(.thirtySec)
    }

    func announceTenSeconds() {
        playClip(.tenSec)
    }

    func announceThreeStars() {
        playClip(.threeStars)
    }

    func announceHighScore() {
        playClip(.highScore)
    }

    // MARK: - Match praise (maps cascade depth → clip)

    private func praiseMatch(cascadeDepth: Int, matchedCount: Int, specialsActivated: Int) {
        guard MetaProgress.shared.soundEnabled else { return }

        let clip = Self.clipForMatch(
            cascadeDepth: cascadeDepth,
            matchedCount: matchedCount,
            specialsActivated: specialsActivated
        )
        guard let clip else { return }

        // Don't interrupt a clip that's already playing
        if let p = player, p.isPlaying { return }

        // Throttle rapid-fire on small matches
        let now = Date()
        if now.timeIntervalSince(lastPlayedAt) < minGap, cascadeDepth < 3 {
            return
        }

        playClip(clip, respectGap: false)
    }

    /// Maps cascade depth + match quality → the right pre-recorded clip
    private static func clipForMatch(
        cascadeDepth: Int,
        matchedCount: Int,
        specialsActivated: Int
    ) -> Clip? {
        switch cascadeDepth {
        case 0:
            if specialsActivated > 0 || matchedCount >= 5 {
                return .amazing
            }
            if matchedCount == 4 {
                return .sweet
            }
            // 3-match: occasional soft praise
            return Bool.random() ? nil : .nice
        case 1:
            // 2x combo
            return .sweet
        case 2:
            // 3x combo
            return .amazing
        case 3:
            // 4x combo
            return .fantastic
        case 4:
            // 5x combo
            return [Clip.fantastic, .streak].randomElement()
        default:
            // 6x+ godlike
            return .fantastic
        }
    }

    // MARK: - Core playback

    private func playClip(_ clip: Clip, respectGap: Bool = false) {
        guard MetaProgress.shared.soundEnabled else { return }

        if respectGap {
            let now = Date()
            if now.timeIntervalSince(lastPlayedAt) < minGap { return }
        }

        // Don't interrupt a currently playing clip
        if let p = player, p.isPlaying { return }

        guard let url = Bundle.main.url(forResource: clip.rawValue, withExtension: "wav")
                ?? Bundle.main.url(forResource: clip.rawValue, withExtension: "wav", subdirectory: "Sounds")
                ?? Bundle.main.url(forResource: clip.rawValue, withExtension: "wav", subdirectory: "Resources/Sounds")
        else {
            print("VoiceAnnouncer: missing \(clip.rawValue).wav")
            return
        }

        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.volume = 0.92
            p.prepareToPlay()
            p.play()
            player = p
            lastPlayedAt = Date()
        } catch {
            print("VoiceAnnouncer: playback error \(clip.rawValue): \(error)")
        }
    }
}
