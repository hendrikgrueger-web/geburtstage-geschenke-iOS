import Foundation
import Combine

// MARK: - AIConsentManagerProtocol

/// Protocol für den DSGVO-Einwilligungs-Manager — ermöglicht Dependency Injection und Testbarkeit.
@MainActor
protocol AIConsentManagerProtocol: AnyObject {
    var consentGiven: Bool { get }
    var consentVersion: Int { get }
    var aiEnabled: Bool { get set }
    var canUseAI: Bool { get }
    var canUseChat: Bool { get }
    func giveConsent()
    func revokeConsent()
}

// MARK: - AIConsentManager

/// Verwaltet die DSGVO-Einwilligung für KI-Features.
/// Gespeichert in UserDefaults — kein Server-Roundtrip.
///
/// ## Consent-Versionen
/// - **v1:** Geschenkvorschläge + Geburtstagsnachrichten (Vorname, Alter, Relation, Hobbies, Tags, Budget)
/// - **v2:** Zusätzlich KI-Chat mit erweiterten Daten (Vorname, Tage bis Geburtstag, Geschenk-Status, Geschenkhistorie)
///
/// Bestandsnutzer mit v1 müssen bei Nutzung des Chats erneut zustimmen (v2).
@MainActor
final class AIConsentManager: ObservableObject, AIConsentManagerProtocol {
    static let shared = AIConsentManager()

    /// Aktuelle Consent-Version. Bei Erhöhung müssen alle Nutzer erneut zustimmen.
    static let currentConsentVersion = 2

    private let consentVersionKey = "ai_dsgvo_consent_version"
    private let enabledKey = "ai_feature_enabled_v1"
    // Legacy-Key für Migration
    private let legacyConsentKey = "ai_dsgvo_consent_v1"

    @Published private(set) var consentGiven: Bool
    @Published private(set) var consentVersion: Int
    @Published var aiEnabled: Bool {
        didSet { UserDefaults.standard.set(aiEnabled, forKey: enabledKey) }
    }

    private init() {
        let storedVersion = UserDefaults.standard.integer(forKey: "ai_dsgvo_consent_version")
        let legacyConsent = UserDefaults.standard.bool(forKey: "ai_dsgvo_consent_v1")

        if storedVersion >= AIConsentManager.currentConsentVersion {
            // Aktuelle Version bereits bestätigt
            self.consentGiven = true
            self.consentVersion = storedVersion
        } else if legacyConsent && storedVersion == 0 {
            // v1-User: Consent gilt für bestehende Features, aber v2-Chat braucht Re-Consent
            self.consentGiven = true
            self.consentVersion = 1
        } else {
            self.consentGiven = false
            self.consentVersion = 0
        }

        self.aiEnabled = UserDefaults.standard.bool(forKey: "ai_feature_enabled_v1")
    }

    /// True wenn KI verwendet werden darf (Einwilligung + aktiviert + API-Key vorhanden)
    var canUseAI: Bool {
        consentGiven && aiEnabled && AIService.isAPIKeyConfigured
    }

    /// True wenn der Chat (v2) genutzt werden darf. False wenn nur v1-Consent vorliegt.
    var canUseChat: Bool {
        canUseAI && consentVersion >= 2
    }

    /// True wenn ein v1-User auf v2 upgraden muss (Chat-Consent fehlt)
    var needsChatConsentUpgrade: Bool {
        consentGiven && consentVersion < 2
    }

    func giveConsent() {
        consentGiven = true
        aiEnabled = true
        consentVersion = AIConsentManager.currentConsentVersion
        UserDefaults.standard.set(true, forKey: legacyConsentKey)
        UserDefaults.standard.set(true, forKey: enabledKey)
        UserDefaults.standard.set(AIConsentManager.currentConsentVersion, forKey: consentVersionKey)
    }

    func revokeConsent() {
        consentGiven = false
        aiEnabled = false
        consentVersion = 0
        UserDefaults.standard.set(false, forKey: legacyConsentKey)
        UserDefaults.standard.set(false, forKey: enabledKey)
        UserDefaults.standard.set(0, forKey: consentVersionKey)
    }
}
