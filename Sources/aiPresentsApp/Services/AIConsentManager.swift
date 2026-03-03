import Foundation
import Combine

/// Verwaltet die DSGVO-Einwilligung für KI-Features.
/// Gespeichert in UserDefaults — kein Server-Roundtrip.
@MainActor
final class AIConsentManager: ObservableObject {
    static let shared = AIConsentManager()

    private let consentKey = "ai_dsgvo_consent_v1"
    private let enabledKey = "ai_feature_enabled_v1"

    @Published private(set) var consentGiven: Bool
    @Published var aiEnabled: Bool {
        didSet { UserDefaults.standard.set(aiEnabled, forKey: enabledKey) }
    }

    private init() {
        self.consentGiven = UserDefaults.standard.bool(forKey: "ai_dsgvo_consent_v1")
        self.aiEnabled = UserDefaults.standard.bool(forKey: "ai_feature_enabled_v1")
    }

    /// True wenn KI verwendet werden darf (Einwilligung + aktiviert + API-Key vorhanden)
    var canUseAI: Bool {
        consentGiven && aiEnabled && AIService.isAPIKeyConfigured
    }

    func giveConsent() {
        consentGiven = true
        aiEnabled = true
        UserDefaults.standard.set(true, forKey: consentKey)
        UserDefaults.standard.set(true, forKey: enabledKey)
    }

    func revokeConsent() {
        consentGiven = false
        aiEnabled = false
        UserDefaults.standard.set(false, forKey: consentKey)
        UserDefaults.standard.set(false, forKey: enabledKey)
    }
}
