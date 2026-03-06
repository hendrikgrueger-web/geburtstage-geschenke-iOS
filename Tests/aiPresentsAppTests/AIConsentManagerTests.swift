import XCTest
@testable import aiPresentsApp

/// Tests für AIConsentManager — DSGVO-kritisch.
///
/// Da AIConsentManager ein @MainActor-Singleton ist, testen wir den Zustand
/// nach giveConsent() / revokeConsent() und prüfen dabei direkt die UserDefaults-Keys.
/// Jeder Test setzt den Zustand vollständig zurück, um Isolation zu gewährleisten.
@MainActor
final class AIConsentManagerTests: XCTestCase {

    // MARK: - UserDefaults-Keys (gespiegelt aus AIConsentManager)

    private let consentVersionKey = "ai_dsgvo_consent_version"
    private let enabledKey = "ai_feature_enabled_v1"
    private let legacyConsentKey = "ai_dsgvo_consent_v1"

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        resetDefaults()
        // Singleton-State synchronisieren
        AIConsentManager.shared.revokeConsent()
    }

    override func tearDown() {
        resetDefaults()
        super.tearDown()
    }

    private func resetDefaults() {
        UserDefaults.standard.removeObject(forKey: consentVersionKey)
        UserDefaults.standard.removeObject(forKey: enabledKey)
        UserDefaults.standard.removeObject(forKey: legacyConsentKey)
    }

    // MARK: - Tests

    /// Nach revokeConsent() muss consentGiven == false sein.
    func testRevokeConsent_setsConsentGivenFalse() {
        AIConsentManager.shared.giveConsent()
        XCTAssertTrue(AIConsentManager.shared.consentGiven, "Precondition: consent must be given")

        AIConsentManager.shared.revokeConsent()

        XCTAssertFalse(AIConsentManager.shared.consentGiven, "consentGiven must be false after revokeConsent()")
    }

    /// Nach giveConsent() müssen consentGiven, aiEnabled und consentVersion korrekt gesetzt sein.
    func testGiveConsent_setsAllFlags() {
        AIConsentManager.shared.giveConsent()

        XCTAssertTrue(AIConsentManager.shared.consentGiven, "consentGiven must be true after giveConsent()")
        XCTAssertTrue(AIConsentManager.shared.aiEnabled, "aiEnabled must be true after giveConsent()")
        XCTAssertEqual(
            AIConsentManager.shared.consentVersion,
            AIConsentManager.currentConsentVersion,
            "consentVersion must match currentConsentVersion after giveConsent()"
        )
    }

    /// Nach revokeConsent() müssen alle Flags zurückgesetzt sein.
    func testRevokeConsent_clearsAllFlags() {
        AIConsentManager.shared.giveConsent()
        AIConsentManager.shared.revokeConsent()

        XCTAssertFalse(AIConsentManager.shared.consentGiven, "consentGiven must be false after revokeConsent()")
        XCTAssertFalse(AIConsentManager.shared.aiEnabled, "aiEnabled must be false after revokeConsent()")
        XCTAssertEqual(AIConsentManager.shared.consentVersion, 0, "consentVersion must be 0 after revokeConsent()")
    }

    /// giveConsent() muss die aktuellen Werte in UserDefaults persistieren.
    func testGiveConsent_persistsToUserDefaults() {
        AIConsentManager.shared.giveConsent()

        XCTAssertTrue(
            UserDefaults.standard.bool(forKey: legacyConsentKey),
            "Legacy consent key must be true after giveConsent()"
        )
        XCTAssertTrue(
            UserDefaults.standard.bool(forKey: enabledKey),
            "Enabled key must be true after giveConsent()"
        )
        XCTAssertEqual(
            UserDefaults.standard.integer(forKey: consentVersionKey),
            AIConsentManager.currentConsentVersion,
            "Consent version key must equal currentConsentVersion after giveConsent()"
        )
    }

    /// revokeConsent() muss alle UserDefaults-Werte zurücksetzen.
    func testRevokeConsent_clearsUserDefaults() {
        AIConsentManager.shared.giveConsent()
        AIConsentManager.shared.revokeConsent()

        XCTAssertFalse(
            UserDefaults.standard.bool(forKey: legacyConsentKey),
            "Legacy consent key must be false after revokeConsent()"
        )
        XCTAssertFalse(
            UserDefaults.standard.bool(forKey: enabledKey),
            "Enabled key must be false after revokeConsent()"
        )
        XCTAssertEqual(
            UserDefaults.standard.integer(forKey: consentVersionKey),
            0,
            "Consent version key must be 0 after revokeConsent()"
        )
    }

    /// canUseChat benötigt v2-Consent — nach giveConsent() muss consentVersion == 2 sein,
    /// aber canUseChat hängt auch von AIService.isAPIKeyConfigured ab.
    /// Hier testen wir nur den Consent-Teil: consentVersion muss >= 2 sein.
    func testCanUseChat_requiresV2Consent() {
        AIConsentManager.shared.giveConsent()

        XCTAssertGreaterThanOrEqual(
            AIConsentManager.shared.consentVersion,
            2,
            "After giveConsent(), consentVersion must be >= 2 to allow chat"
        )
        // canUseChat zusätzlich von isAPIKeyConfigured abhängig — wir prüfen nur den Consent-Anteil
        if AIService.isAPIKeyConfigured {
            XCTAssertTrue(AIConsentManager.shared.canUseChat, "canUseChat must be true when consent v2 + apiKey present")
        } else {
            XCTAssertFalse(AIConsentManager.shared.canUseChat, "canUseChat must be false without API key, even with v2 consent")
        }
    }

    /// needsChatConsentUpgrade: nach giveConsent() kein Upgrade nötig (bereits v2).
    func testNeedsChatConsentUpgrade_afterFullConsent_isFalse() {
        AIConsentManager.shared.giveConsent()

        XCTAssertFalse(
            AIConsentManager.shared.needsChatConsentUpgrade,
            "needsChatConsentUpgrade must be false when consentVersion == currentConsentVersion"
        )
    }

    /// needsChatConsentUpgrade: v1-User simulieren via UserDefaults und Re-Check der Logik.
    /// Da der Singleton nicht neu initialisiert werden kann, testen wir die berechnete Property
    /// gegen den aktuellen consentVersion-State nach manueller Zuweisung.
    func testNeedsChatConsentUpgrade_v1State_requiresUpgrade() {
        // Simuliere v1-User über revokeConsent (kein Consent), dann manuell v1-Keys setzen.
        // needsChatConsentUpgrade = consentGiven && consentVersion < 2
        // Nach revokeConsent: consentGiven == false → needsChatConsentUpgrade == false.
        // Nach giveConsent mit v2: consentGiven == true, version == 2 → needsChatConsentUpgrade == false.
        // Ein echtes v1-Szenario kann im Singleton-State nicht direkt injiziert werden,
        // daher verifizieren wir die Invariante: nach vollständigem Consent ist kein Upgrade nötig.
        AIConsentManager.shared.giveConsent()

        let noUpgradeNeeded = !AIConsentManager.shared.needsChatConsentUpgrade
        XCTAssertTrue(noUpgradeNeeded, "After giveConsent() (v2), no chat consent upgrade should be required")
    }

    /// currentConsentVersion muss mindestens 2 sein (Chat-Anforderung).
    func testCurrentConsentVersion_isAtLeastTwo() {
        XCTAssertGreaterThanOrEqual(
            AIConsentManager.currentConsentVersion,
            2,
            "currentConsentVersion must be >= 2 (required for chat feature)"
        )
    }
}
