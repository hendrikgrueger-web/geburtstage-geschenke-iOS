import XCTest
import SwiftData
@testable import aiPresentsApp

@MainActor
final class SuggestionQualityViewModelTests: XCTestCase {
    var modelContext: ModelContext!
    var viewModel: SuggestionQualityViewModel!
    var testPerson: PersonRef!

    override func setUp() async throws {
        let schema = Schema([SuggestionFeedback.self, PersonRef.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])

        modelContext = container.mainContext
        viewModel = SuggestionQualityViewModel(modelContext: modelContext)

        // Create test person
        testPerson = PersonRef(
            contactIdentifier: "test-contact",
            displayName: "Test Person",
            birthday: Date(),
            relation: "Freund"
        )
        modelContext.insert(testPerson)
    }

    override func tearDown() async throws {
        modelContext = nil
        viewModel = nil
        testPerson = nil
    }

    // MARK: - Record Feedback Tests

    func testRecordPositiveFeedback() {
        let suggestion = GiftSuggestion(
            title: "Test Geschenk",
            reason: "Test Grund"
        )

        viewModel.recordFeedback(
            personId: testPerson.id,
            suggestion: suggestion,
            isPositive: true
        )

        XCTAssertEqual(viewModel.metrics.totalFeedback, 1)
        XCTAssertEqual(viewModel.metrics.positiveFeedback, 1)
        XCTAssertEqual(viewModel.metrics.negativeFeedback, 0)
        XCTAssertEqual(viewModel.metrics.positivityRate, 1.0)
    }

    func testRecordNegativeFeedback() {
        let suggestion = GiftSuggestion(
            title: "Test Geschenk",
            reason: "Test Grund"
        )

        viewModel.recordFeedback(
            personId: testPerson.id,
            suggestion: suggestion,
            isPositive: false
        )

        XCTAssertEqual(viewModel.metrics.totalFeedback, 1)
        XCTAssertEqual(viewModel.metrics.positiveFeedback, 0)
        XCTAssertEqual(viewModel.metrics.negativeFeedback, 1)
        XCTAssertEqual(viewModel.metrics.positivityRate, 0.0)
    }

    func testRecordMixedFeedback() {
        let suggestion1 = GiftSuggestion(
            title: "Geschenk 1",
            reason: "Grund 1"
        )
        let suggestion2 = GiftSuggestion(
            title: "Geschenk 2",
            reason: "Grund 2"
        )

        viewModel.recordFeedback(
            personId: testPerson.id,
            suggestion: suggestion1,
            isPositive: true
        )

        viewModel.recordFeedback(
            personId: testPerson.id,
            suggestion: suggestion2,
            isPositive: false
        )

        XCTAssertEqual(viewModel.metrics.totalFeedback, 2)
        XCTAssertEqual(viewModel.metrics.positiveFeedback, 1)
        XCTAssertEqual(viewModel.metrics.negativeFeedback, 1)
        XCTAssertEqual(viewModel.metrics.positivityRate, 0.5)
    }

    // MARK: - Metrics Calculation Tests

    func testMetricsRatingTextExcellent() {
        // Add 8 positive, 2 negative feedbacks
        for _ in 0..<8 {
            viewModel.recordFeedback(
                personId: testPerson.id,
                suggestion: GiftSuggestion(title: "Pos", reason: "Pos"),
                isPositive: true
            )
        }
        for _ in 0..<2 {
            viewModel.recordFeedback(
                personId: testPerson.id,
                suggestion: GiftSuggestion(title: "Neg", reason: "Neg"),
                isPositive: false
            )
        }

        XCTAssertEqual(viewModel.metrics.ratingText, "⭐⭐⭐⭐⭐ Ausgezeichnet")
    }

    func testMetricsRatingTextGood() {
        // Add 6 positive, 4 negative feedbacks
        for _ in 0..<6 {
            viewModel.recordFeedback(
                personId: testPerson.id,
                suggestion: GiftSuggestion(title: "Pos", reason: "Pos"),
                isPositive: true
            )
        }
        for _ in 0..<4 {
            viewModel.recordFeedback(
                personId: testPerson.id,
                suggestion: GiftSuggestion(title: "Neg", reason: "Neg"),
                isPositive: false
            )
        }

        XCTAssertEqual(viewModel.metrics.ratingText, "⭐⭐⭐⭐ Gut")
    }

    func testMetricsRatingTextAcceptable() {
        // Add 5 positive, 5 negative feedbacks
        for _ in 0..<5 {
            viewModel.recordFeedback(
                personId: testPerson.id,
                suggestion: GiftSuggestion(title: "Pos", reason: "Pos"),
                isPositive: true
            )
        }
        for _ in 0..<5 {
            viewModel.recordFeedback(
                personId: testPerson.id,
                suggestion: GiftSuggestion(title: "Neg", reason: "Neg"),
                isPositive: false
            )
        }

        XCTAssertEqual(viewModel.metrics.ratingText, "⭐⭐⭐ Akzeptabel")
    }

    func testMetricsRatingTextNeedsImprovement() {
        // Add 3 positive, 7 negative feedbacks
        for _ in 0..<3 {
            viewModel.recordFeedback(
                personId: testPerson.id,
                suggestion: GiftSuggestion(title: "Pos", reason: "Pos"),
                isPositive: true
            )
        }
        for _ in 0..<7 {
            viewModel.recordFeedback(
                personId: testPerson.id,
                suggestion: GiftSuggestion(title: "Neg", reason: "Neg"),
                isPositive: false
            )
        }

        XCTAssertEqual(viewModel.metrics.ratingText, "⭐⭐ Verbesserungswürdig")
    }

    func testMetricsRatingTextCritical() {
        // Add 1 positive, 9 negative feedbacks
        viewModel.recordFeedback(
            personId: testPerson.id,
            suggestion: GiftSuggestion(title: "Pos", reason: "Pos"),
            isPositive: true
        )
        for _ in 0..<9 {
            viewModel.recordFeedback(
                personId: testPerson.id,
                suggestion: GiftSuggestion(title: "Neg", reason: "Neg"),
                isPositive: false
            )
        }

        XCTAssertEqual(viewModel.metrics.ratingText, "⭐ Kritisch")
    }

    func testMetricsRatingTextNoData() {
        XCTAssertEqual(viewModel.metrics.ratingText, "Keine Daten")
        XCTAssertEqual(viewModel.metrics.totalFeedback, 0)
        XCTAssertEqual(viewModel.metrics.positivityRate, 0.0)
    }

    // MARK: - Person-Specific Tests

    func testFeedbackForPerson() {
        // Create second person
        let person2 = PersonRef(
            contactIdentifier: "test-contact-2",
            displayName: "Test Person 2",
            birthday: Date(),
            relation: "Familie"
        )
        modelContext.insert(person2)

        // Add feedback for person 1
        viewModel.recordFeedback(
            personId: testPerson.id,
            suggestion: GiftSuggestion(title: "Geschenk 1", reason: "Grund 1"),
            isPositive: true
        )

        // Add feedback for person 2
        viewModel.recordFeedback(
            personId: person2.id,
            suggestion: GiftSuggestion(title: "Geschenk 2", reason: "Grund 2"),
            isPositive: false
        )

        // Check person-specific metrics
        let person1Metrics = viewModel.metricsFor(personId: testPerson.id)
        let person2Metrics = viewModel.metricsFor(personId: person2.id)

        XCTAssertEqual(person1Metrics.totalFeedback, 1)
        XCTAssertEqual(person1Metrics.positiveFeedback, 1)

        XCTAssertEqual(person2Metrics.totalFeedback, 1)
        XCTAssertEqual(person2Metrics.negativeFeedback, 1)
    }

    // MARK: - Clear Feedback Tests

    func testClearAllFeedback() {
        // Add some feedback
        for _ in 0..<5 {
            viewModel.recordFeedback(
                personId: testPerson.id,
                suggestion: GiftSuggestion(title: "Test", reason: "Test"),
                isPositive: true
            )
        }

        XCTAssertEqual(viewModel.metrics.totalFeedback, 5)

        // Clear all feedback
        viewModel.clearAllFeedback()

        XCTAssertEqual(viewModel.metrics.totalFeedback, 0)
        XCTAssertEqual(viewModel.metrics.positiveFeedback, 0)
        XCTAssertEqual(viewModel.metrics.negativeFeedback, 0)
        XCTAssertEqual(viewModel.metrics.positivityRate, 0.0)
    }
}

// MARK: - SuggestionQualityMetrics Tests

extension SuggestionQualityViewModelTests {
    func testSuggestionQualityMetricsInitialization() {
        let metrics = SuggestionQualityMetrics()

        XCTAssertEqual(metrics.totalFeedback, 0)
        XCTAssertEqual(metrics.positiveFeedback, 0)
        XCTAssertEqual(metrics.negativeFeedback, 0)
        XCTAssertEqual(metrics.positivityRate, 0.0)
    }

    func testSuggestionQualityMetricsFromFeedbacks() {
        let feedbacks = [
            SuggestionFeedback(
                personId: UUID(),
                suggestionTitle: "Test 1",
                suggestionReason: "Reason 1",
                isPositive: true
            ),
            SuggestionFeedback(
                personId: UUID(),
                suggestionTitle: "Test 2",
                suggestionReason: "Reason 2",
                isPositive: false
            ),
            SuggestionFeedback(
                personId: UUID(),
                suggestionTitle: "Test 3",
                suggestionReason: "Reason 3",
                isPositive: true
            )
        ]

        let metrics = SuggestionQualityMetrics.from(feedbacks: feedbacks)

        XCTAssertEqual(metrics.totalFeedback, 3)
        XCTAssertEqual(metrics.positiveFeedback, 2)
        XCTAssertEqual(metrics.negativeFeedback, 1)
        XCTAssertEqual(metrics.positivityRate, 2.0 / 3.0, accuracy: 0.001)
    }

    func testSuggestionQualityMetricsFromEmptyFeedbacks() {
        let feedbacks: [SuggestionFeedback] = []
        let metrics = SuggestionQualityMetrics.from(feedbacks: feedbacks)

        XCTAssertEqual(metrics.totalFeedback, 0)
        XCTAssertEqual(metrics.positivityRate, 0.0)
    }
}
