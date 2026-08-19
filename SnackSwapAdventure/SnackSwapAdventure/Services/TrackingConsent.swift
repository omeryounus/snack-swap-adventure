import Foundation
import AppTrackingTransparency
import AdSupport

/// App Tracking Transparency gate.
///
/// The app was rejected under 5.1.2(i) because its privacy label declared
/// tracking while `ATTrackingManager` was never called — the usage string was
/// in Info.plist but nothing ever asked. Nothing here may collect data used
/// for tracking before `requestIfNeeded()` has returned an authorised status.
///
/// The prompt is only shown when an ad network is actually configured. Asking
/// for tracking permission the app cannot use is both a poor experience and a
/// contradiction of a "not used for tracking" privacy label.
@MainActor
final class TrackingConsent: ObservableObject {
    static let shared = TrackingConsent()

    @Published private(set) var status: ATTrackingManager.AuthorizationStatus = .notDetermined

    private var hasAsked = false

    private init() {
        status = ATTrackingManager.trackingAuthorizationStatus
    }

    /// True only when the user has explicitly allowed tracking.
    var isAuthorized: Bool { status == .authorized }

    /// The advertising identifier, or nil when tracking is not authorised.
    /// Reading it without authorisation returns zeroes anyway; returning nil
    /// keeps callers from treating that as a real identifier.
    var advertisingIdentifier: UUID? {
        guard isAuthorized else { return nil }
        let id = ASIdentifierManager.shared().advertisingIdentifier
        return id.uuidString == "00000000-0000-0000-0000-000000000000" ? nil : id
    }

    /// Asks once, and only when there is an ad network to justify it.
    /// Must run while the app is active — iOS silently denies the request
    /// otherwise, which is a common cause of a prompt that never appears.
    @discardableResult
    func requestIfNeeded() async -> ATTrackingManager.AuthorizationStatus {
        guard AdConfig.adsEnabled else { return status }
        guard !hasAsked else { return status }
        hasAsked = true

        let current = ATTrackingManager.trackingAuthorizationStatus
        guard current == .notDetermined else {
            status = current
            return current
        }

        let result = await ATTrackingManager.requestTrackingAuthorization()
        status = result
        return result
    }
}
