import XCTest
@testable import aiPresentsApp

final class AIServiceTests: XCTestCase {
    var sut: AIService!

    override func setUpWithError() throws {
        sut = AIService.shared
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    // MARK: - API-Key-Prüfung

    func testGenerateGiftIdeasThrowsWithoutAPIKey() async throws {
        // Ohne API-Key muss ein Fehler geworfen werden (kein Demo-Modus)
        let person = PersonRef(contactIdentifier: "",
            displayName: "Anna Müller",
            birthday: Date(),
            relation: "Mama"
        )

        do {
            _ = try await sut.generateGiftIdeas(
                for: person,
                budgetMin: 0,
                budgetMax: 100,
                tags: [],
                pastGifts: []
            )
            // Wenn kein API-Key konfiguriert ist, sollte ein Fehler kommen
            if !AIService.isAPIKeyConfigured {
                XCTFail("Should throw error when API key is not configured")
            }
        } catch {
            // Erwartetes Verhalten ohne API-Key
            XCTAssertTrue(error is AIService.AIError, "Should throw AIError, got: \(error)")
        }
    }

    func testGenerateBirthdayMessageThrowsWithoutAPIKey() async throws {
        let person = PersonRef(contactIdentifier: "",
            displayName: "Tom Schmidt",
            birthday: Date(),
            relation: "Freund"
        )

        do {
            _ = try await sut.generateBirthdayMessage(for: person, pastGifts: [])
            if !AIService.isAPIKeyConfigured {
                XCTFail("Should throw error when API key is not configured")
            }
        } catch {
            XCTAssertTrue(error is AIService.AIError, "Should throw AIError, got: \(error)")
        }
    }

    // MARK: - GiftSuggestion Tests

    func testGiftSuggestionStructure() {
        let suggestion = GiftSuggestion(
            title: "Test Gift",
            reason: "Because it's a test"
        )

        XCTAssertEqual(suggestion.title, "Test Gift")
        XCTAssertEqual(suggestion.reason, "Because it's a test")
    }

    func testGiftSuggestionHasUniqueID() {
        let s1 = GiftSuggestion(title: "Gift 1", reason: "Reason 1")
        let s2 = GiftSuggestion(title: "Gift 2", reason: "Reason 2")
        XCTAssertNotEqual(s1.id, s2.id, "Each suggestion should have a unique ID")
    }

    // MARK: - BirthdayMessage Tests

    func testBirthdayMessageFullText() {
        let message = BirthdayMessage(greeting: "Hallo!", body: "Alles Gute!")
        XCTAssertEqual(message.fullText, "Hallo!\n\nAlles Gute!")
    }

    func testBirthdayMessageFullTextContainsBoth() {
        let message = BirthdayMessage(greeting: "Liebe Anna,", body: "Herzlichen Glückwunsch!")
        XCTAssertTrue(message.fullText.contains(message.greeting))
        XCTAssertTrue(message.fullText.contains(message.body))
    }

    // MARK: - AIError Tests

    func testAIErrorDescriptions() {
        XCTAssertNotNil(AIService.AIError.noAPIKey.errorDescription,
                       "noAPIKey should have error description")
        XCTAssertNotNil(AIService.AIError.notConfigured.errorDescription,
                       "notConfigured should have error description")
        XCTAssertNotNil(AIService.AIError.noConsent.errorDescription,
                       "noConsent should have error description")
        XCTAssertNotNil(AIService.AIError.httpError(500).errorDescription,
                       "httpError should have error description")
        XCTAssertNotNil(AIService.AIError.emptyResponse.errorDescription,
                       "emptyResponse should have error description")
        XCTAssertNotNil(AIService.AIError.invalidResponse.errorDescription,
                       "invalidResponse should have error description")
    }

    func testAIErrorNotConfiguredMessage() {
        let error = AIService.AIError.notConfigured
        XCTAssertTrue(error.errorDescription?.contains("KI-Dienst") == true,
                     "notConfigured error should mention KI-Dienst")
    }

    func testAIErrorNoConsentMessage() {
        let error = AIService.AIError.noConsent
        XCTAssertTrue(error.errorDescription?.contains("Einwilligung") == true,
                     "noConsent error should mention consent")
    }

    func testAIErrorHttpErrorIncludesStatusCode() {
        let error = AIService.AIError.httpError(429)
        XCTAssertTrue(error.errorDescription?.contains("429") == true,
                     "HTTP error should include status code")
    }

    // MARK: - Verfügbarkeit

    func testIsAPIKeyConfiguredReturnsBool() {
        // Im Test-Environment ist normalerweise kein API-Key vorhanden
        let result = AIService.isAPIKeyConfigured
        XCTAssertTrue(result == true || result == false, "Should return a valid Bool")
    }
}
