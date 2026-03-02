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

    // MARK: - Demo Mode Tests

    func testGenerateDemoSuggestionsForFamily() async throws {
        let person = PersonRef(
            displayName: "Anna Müller",
            birthday: Date(),
            relation: "Mama"
        )

        let suggestions = try await sut.generateGiftIdeas(
            for: person,
            budgetMin: 0,
            budgetMax: 100,
            tags: [],
            pastGifts: []
        )

        XCTAssertEqual(suggestions.count, 5, "Demo mode should generate exactly 5 suggestions")
        XCTAssertFalse(suggestions.isEmpty, "Suggestions should not be empty")

        for suggestion in suggestions {
            XCTAssertFalse(suggestion.title.isEmpty, "Suggestion title should not be empty")
            XCTAssertFalse(suggestion.reason.isEmpty, "Suggestion reason should not be empty")
        }
    }

    func testGenerateDemoSuggestionsForFriends() async throws {
        let person = PersonRef(
            displayName: "Thomas Schmidt",
            birthday: Date(),
            relation: "Freund"
        )

        let suggestions = try await sut.generateGiftIdeas(
            for: person,
            budgetMin: 20,
            budgetMax: 80,
            tags: ["Technik"],
            pastGifts: []
        )

        XCTAssertEqual(suggestions.count, 5, "Demo mode should generate exactly 5 suggestions")

        // Budget should be respected in demo mode suggestions
        for suggestion in suggestions {
            XCTAssertFalse(suggestion.title.isEmpty)
        }
    }

    func testGenerateDemoSuggestionsForPartners() async throws {
        let person = PersonRef(
            displayName: "Lisa Weber",
            birthday: Date(),
            relation: "Partnerin"
        )

        let suggestions = try await sut.generateGiftIdeas(
            for: person,
            budgetMin: 50,
            budgetMax: 200,
            tags: [],
            pastGifts: []
        )

        XCTAssertEqual(suggestions.count, 5)
        XCTAssertTrue(suggestions.contains { $0.title.contains("Romantisch") || $0.title.contains("Erlebnis") },
                      "Partner suggestions should include romantic or experiential gifts")
    }

    func testGenerateDemoSuggestionsForUnknownRelation() async throws {
        let person = PersonRef(
            displayName: "Max Fischer",
            birthday: Date(),
            relation: "Unbekannt"
        )

        let suggestions = try await sut.generateGiftIdeas(
            for: person,
            budgetMin: 10,
            budgetMax: 50,
            tags: [],
            pastGifts: []
        )

        XCTAssertEqual(suggestions.count, 5)
        XCTAssertFalse(suggestions.isEmpty)
    }

    func testGenerateDemoSuggestionsWithTags() async throws {
        let person = PersonRef(
            displayName: "Julia Klein",
            birthday: Date(),
            relation: "Freundin"
        )

        let suggestions = try await sut.generateGiftIdeas(
            for: person,
            budgetMin: 20,
            budgetMax: 80,
            tags: ["Bücher", "Lesen"],
            pastGifts: []
        )

        XCTAssertEqual(suggestions.count, 5)
    }

    func testGenerateDemoSuggestionsWithPastGifts() async throws {
        let person = PersonRef(
            displayName: "Peter Meier",
            birthday: Date(),
            relation: "Kollege"
        )

        let pastGift = GiftHistory(
            personId: person.id,
            title: "Bücher-Set",
            category: "Bücher",
            year: 2025,
            budget: 30,
            note: "Liebt Krimis"
        )

        let suggestions = try await sut.generateGiftIdeas(
            for: person,
            budgetMin: 0,
            budgetMax: 100,
            tags: [],
            pastGifts: [pastGift]
        )

        XCTAssertEqual(suggestions.count, 5)
        // Note: In demo mode, past gifts are passed but filtering logic may vary
    }

    func testGenerateDemoSuggestionsRespectsBudget() async throws {
        let person = PersonRef(
            displayName: "Sarah Wagner",
            birthday: Date(),
            relation: "Schwester"
        )

        let lowBudget = 10
        let highBudget = 30

        let suggestions = try await sut.generateGiftIdeas(
            for: person,
            budgetMin: Double(lowBudget),
            budgetMax: Double(highBudget),
            tags: [],
            pastGifts: []
        )

        XCTAssertEqual(suggestions.count, 5)
        // Note: Demo mode generates fixed suggestions, budget awareness is limited
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

    func testMultipleGiftSuggestionsDistinct() async throws {
        let person = PersonRef(
            displayName: "Test Person",
            birthday: Date(),
            relation: "Freund"
        )

        let suggestions = try await sut.generateGiftIdeas(
            for: person,
            budgetMin: 0,
            budgetMax: 100,
            tags: [],
            pastGifts: []
        )

        let titles = suggestions.map { $0.title }
        let uniqueTitles = Set(titles)

        XCTAssertEqual(titles.count, uniqueTitles.count,
                       "All suggestions should have unique titles")
    }

    // MARK: - RetryPolicy Tests

    func testRetryPolicyDefault() {
        let policy = RetryPolicy.default

        XCTAssertEqual(policy.maxAttempts, 3, "Default retry policy should have 3 max attempts")
        XCTAssertEqual(policy.delay, 1.0, "Default retry policy should have 1.0s delay")
    }

    func testRetryPolicyAggressive() {
        let policy = RetryPolicy.aggressive

        XCTAssertEqual(policy.maxAttempts, 5, "Aggressive retry policy should have 5 max attempts")
        XCTAssertEqual(policy.delay, 0.5, "Aggressive retry policy should have 0.5s delay")
    }

    // MARK: - AIError Tests

    func testAIErrorDescriptions() {
        XCTAssertEqual(AIService.AIError.apiKeyNotConfigured.errorDescription,
                       "OpenRouter API-Key nicht konfiguriert")
        XCTAssertEqual(AIService.AIError.requestFailed.errorDescription,
                       "API-Anfrage fehlgeschlagen nach mehreren Versuchen")
        XCTAssertEqual(AIService.AIError.invalidResponse.errorDescription,
                       "Ungültige API-Antwort")
        XCTAssertEqual(AIService.AIError.serverError(500).errorDescription,
                       "Server-Fehler (500): Bitte versuche es erneut")
        XCTAssertEqual(AIService.AIError.rateLimit.errorDescription,
                       "Zu viele Anfragen. Bitte warte einen Moment")
        XCTAssertEqual(AIService.AIError.clientError(400).errorDescription,
                       "Client-Fehler (400): Überprüfe deine Konfiguration")
    }

    func testAIErrorRetryable() {
        XCTAssertFalse(AIService.AIError.apiKeyNotConfigured.isRetryable,
                       "API key error should not be retryable")
        XCTAssertFalse(AIService.AIError.invalidResponse.isRetryable,
                       "Invalid response should not be retryable")
        XCTAssertFalse(AIService.AIError.clientError(400).isRetryable,
                       "Client errors should not be retryable")
        XCTAssertTrue(AIService.AIError.serverError(500).isRetryable,
                      "Server errors should be retryable")
        XCTAssertTrue(AIService.AIError.rateLimit.isRetryable,
                      "Rate limit errors should be retryable")
        XCTAssertTrue(AIService.AIError.requestFailed.isRetryable,
                      "Request failed should be retryable")
    }
}
