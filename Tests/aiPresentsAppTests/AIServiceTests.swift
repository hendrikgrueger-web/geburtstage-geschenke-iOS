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

    func testIsAPIKeyConfigured_matchesAppConfigValidation() {
        let secret = AppConfig.AI.proxySecret
        let expected = !secret.isEmpty && secret != "your-app-secret-here" && secret.count > 8

        XCTAssertEqual(
            AIService.isAPIKeyConfigured,
            expected,
            "AIService should mirror AppConfig.AI secret validation"
        )
    }

    // MARK: - extractJSON

    func testExtractJSON_plainJSON_passthrough() {
        let input = "{\"message\":\"test\"}"
        XCTAssertEqual(AIService.extractJSON(from: input), input,
                       "Plain JSON should be returned unchanged")
    }

    func testExtractJSON_markdownCodeBlock_stripsWrapper() {
        let input = "```json\n{\"message\":\"test\"}\n```"
        XCTAssertEqual(AIService.extractJSON(from: input), "{\"message\":\"test\"}",
                       "JSON wrapped in ```json ... ``` should be unwrapped")
    }

    func testExtractJSON_withoutLanguageLabel() {
        let input = "```\n{\"key\":\"val\"}\n```"
        XCTAssertEqual(AIService.extractJSON(from: input), "{\"key\":\"val\"}",
                       "JSON wrapped in bare ``` ... ``` should be unwrapped")
    }

    func testExtractJSON_whitespace_trimmed() {
        let input = "  {\"a\":1}  "
        XCTAssertEqual(AIService.extractJSON(from: input), "{\"a\":1}",
                       "Leading and trailing whitespace should be trimmed")
    }

    func testDecodeGiftSuggestions_stripsMarkdownWrapper() {
        let responseData = """
        ```json
        {"suggestions":[{"title":"Buch","reason":"Passt zu den Hobbys"}]}
        ```
        """.data(using: .utf8)!

        let suggestions = AIService.decodeGiftSuggestions(from: responseData)

        XCTAssertEqual(suggestions?.count, 1, "Expected one decoded suggestion")
        XCTAssertEqual(suggestions?.first?.title, "Buch")
        XCTAssertEqual(suggestions?.first?.reason, "Passt zu den Hobbys")
    }

    func testDecodeBirthdayMessage_stripsMarkdownWrapperAndAppendsSenderName() {
        let responseData = """
        ```json
        {"greeting":"Liebe Anna,","body":"alles Gute zum Geburtstag!"}
        ```
        """.data(using: .utf8)!

        let message = AIService.decodeBirthdayMessage(from: responseData, senderName: "Hendrik")

        XCTAssertEqual(message?.greeting, "Liebe Anna,")
        XCTAssertEqual(message?.body, "alles Gute zum Geburtstag!\n\nHendrik")
    }
}
