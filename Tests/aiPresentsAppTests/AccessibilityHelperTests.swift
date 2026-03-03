import XCTest
@testable import aiPresentsApp

final class AccessibilityHelperTests: XCTestCase {
    // MARK: - Date Formatting Tests

    func testFormatDateReturnsNonEmpty() {
        let date = Date()
        let formatted = AccessibilityHelper.formatDate(date)

        XCTAssertFalse(formatted.isEmpty, "Formatted date should not be empty")
    }

    func testFormatDateContainsYear() {
        let date = createDate(year: 2026, month: 6, day: 15)
        let formatted = AccessibilityHelper.formatDate(date)

        XCTAssertTrue(formatted.contains("2026"), "Should contain the year")
    }

    // MARK: - Days Until Formatting Tests

    func testFormatDaysUntilToday() {
        let formatted = AccessibilityHelper.formatDaysUntil(0)

        XCTAssertEqual(formatted, "Heute", "Today should be formatted as 'Heute'")
    }

    func testFormatDaysUntilTomorrow() {
        let formatted = AccessibilityHelper.formatDaysUntil(1)

        XCTAssertEqual(formatted, "Morgen", "Tomorrow should be formatted as 'Morgen'")
    }

    func testFormatDaysUntilLessThanAWeek() {
        let formatted = AccessibilityHelper.formatDaysUntil(5)

        XCTAssertEqual(formatted, "In 5 Tagen", "Less than a week should be 'In X Tagen'")
    }

    func testFormatDaysUntilLessThanAMonth() {
        let formatted = AccessibilityHelper.formatDaysUntil(20)

        XCTAssertEqual(formatted, "In 20 Tagen", "Less than a month should be 'In X Tagen'")
    }

    func testFormatDaysUntilMoreThanAMonth() {
        let formatted = AccessibilityHelper.formatDaysUntil(45)

        XCTAssertEqual(formatted, "45 Tage ab heute", "More than a month should be 'X Tage ab heute'")
    }

    // MARK: - Budget Formatting Tests

    func testFormatBudgetEqualMinMax() {
        let formatted = AccessibilityHelper.formatBudget(50, 50)

        XCTAssertTrue(formatted.contains("50"), "Should contain budget")
        XCTAssertTrue(formatted.contains("Euro"), "Should contain 'Euro'")
        XCTAssertFalse(formatted.contains("bis"), "Should not contain 'bis'")
    }

    func testFormatBudgetMinZero() {
        let formatted = AccessibilityHelper.formatBudget(0, 100)

        XCTAssertTrue(formatted.contains("bis"), "Should contain 'bis'")
        XCTAssertTrue(formatted.contains("100"), "Should contain max budget")
        XCTAssertTrue(formatted.contains("Euro"), "Should contain 'Euro'")
    }

    func testFormatBudgetRange() {
        let formatted = AccessibilityHelper.formatBudget(25, 75)

        XCTAssertTrue(formatted.contains("25"), "Should contain min budget")
        XCTAssertTrue(formatted.contains("75"), "Should contain max budget")
        XCTAssertTrue(formatted.contains("Euro"), "Should contain 'Euro'")
        XCTAssertTrue(formatted.contains("bis"), "Should contain 'bis'")
    }

    func testFormatBudgetZero() {
        let formatted = AccessibilityHelper.formatBudget(0, 0)

        XCTAssertEqual(formatted, "0 Euro", "Zero budget should be '0 Euro'")
    }

    // MARK: - Tags Formatting Tests

    func testFormatTagsEmpty() {
        let formatted = AccessibilityHelper.formatTags([])

        XCTAssertEqual(formatted, "Keine Tags", "Empty tags should be 'Keine Tags'")
    }

    func testFormatTagsSingle() {
        let formatted = AccessibilityHelper.formatTags(["Geburtstag"])

        XCTAssertTrue(formatted.contains("Tags:"), "Should contain 'Tags:'")
        XCTAssertTrue(formatted.contains("#Geburtstag"), "Should format with # prefix")
    }

    func testFormatTagsMultiple() {
        let formatted = AccessibilityHelper.formatTags(["Geburtstag", "Geschenk"])

        XCTAssertTrue(formatted.contains("Tags:"), "Should contain 'Tags:'")
        XCTAssertTrue(formatted.contains("#Geburtstag"), "Should format first tag with #")
        XCTAssertTrue(formatted.contains("#Geschenk"), "Should format second tag with #")
        XCTAssertTrue(formatted.contains(","), "Should separate with comma")
    }

    // MARK: - Gift Status Formatting Tests

    func testFormatGiftStatusIdea() {
        let formatted = AccessibilityHelper.formatGiftStatus(.idea)

        XCTAssertEqual(formatted, "Geschenkidee", "Idea status should be 'Geschenkidee'")
    }

    func testFormatGiftStatusPlanned() {
        let formatted = AccessibilityHelper.formatGiftStatus(.planned)

        XCTAssertEqual(formatted, "Geplant", "Planned status should be 'Geplant'")
    }

    func testFormatGiftStatusPurchased() {
        let formatted = AccessibilityHelper.formatGiftStatus(.purchased)

        XCTAssertEqual(formatted, "Gekauft", "Purchased status should be 'Gekauft'")
    }

    func testFormatGiftStatusGiven() {
        let formatted = AccessibilityHelper.formatGiftStatus(.given)

        XCTAssertEqual(formatted, "Verschenkt", "Given status should be 'Verschenkt'")
    }

    // MARK: - Gift Idea Label Tests

    func testGiftIdeaLabelWithTitleOnly() {
        let idea = GiftIdea(personId: UUID(), title: "Test Geschenk", budgetMin: 0, budgetMax: 0, status: .idea)
        let label = AccessibilityHelper.giftIdeaLabel(idea, includeStatus: true)

        XCTAssertTrue(label.contains("Test Geschenk"), "Should contain title")
        XCTAssertTrue(label.contains("Geschenkidee"), "Should contain status")
    }

    func testGiftIdeaLabelWithBudget() {
        let idea = GiftIdea(personId: UUID(), title: "Test", budgetMin: 25, budgetMax: 75, status: .idea)
        let label = AccessibilityHelper.giftIdeaLabel(idea, includeStatus: true)

        XCTAssertTrue(label.contains("Budget:"), "Should contain budget label")
        XCTAssertTrue(label.contains("Euro"), "Should contain currency")
    }

    func testGiftIdeaLabelWithTags() {
        let idea = GiftIdea(personId: UUID(), title: "Test", budgetMin: 0, budgetMax: 0, status: .idea)
        idea.tags = ["Tag1", "Tag2"]
        let label = AccessibilityHelper.giftIdeaLabel(idea, includeStatus: true)

        XCTAssertTrue(label.contains("Tags:"), "Should contain tags label")
        XCTAssertTrue(label.contains("#Tag1"), "Should format first tag")
        XCTAssertTrue(label.contains("#Tag2"), "Should format second tag")
    }

    func testGiftIdeaLabelWithNote() {
        let idea = GiftIdea(personId: UUID(), title: "Test", budgetMin: 0, budgetMax: 0, status: .idea)
        idea.note = "Notiz Text"
        let label = AccessibilityHelper.giftIdeaLabel(idea, includeStatus: true)

        XCTAssertTrue(label.contains("Notiz:"), "Should contain note label")
        XCTAssertTrue(label.contains("Notiz Text"), "Should contain note content")
    }

    func testGiftIdeaLabelWithoutStatus() {
        let idea = GiftIdea(personId: UUID(), title: "Test", budgetMin: 0, budgetMax: 0, status: .idea)
        let label = AccessibilityHelper.giftIdeaLabel(idea, includeStatus: false)

        XCTAssertTrue(label.contains("Test"), "Should contain title")
        XCTAssertFalse(label.contains("Status:"), "Should not contain status when disabled")
    }

    // MARK: - Person Label Tests

    func testPersonLabelBasic() {
        let person = PersonRef(
            contactIdentifier: "test",
            displayName: "Test Person",
            birthday: Date(),
            relation: "Freund"
        )
        let label = AccessibilityHelper.personLabel(person, daysUntil: 5)

        XCTAssertTrue(label.contains("Test Person"), "Should contain display name")
        XCTAssertTrue(label.contains("Beziehung:"), "Should contain relationship label")
        XCTAssertTrue(label.contains("Freund"), "Should contain relationship")
        XCTAssertTrue(label.contains("Nächster Geburtstag:"), "Should contain birthday label")
        XCTAssertTrue(label.contains("In 5 Tagen"), "Should contain days until")
    }

    func testPersonLabelWithGiftIdeas() {
        let person = PersonRef(
            contactIdentifier: "test",
            displayName: "Test Person",
            birthday: Date(),
            relation: "Freund"
        )
        person.giftIdeas = [
            GiftIdea(personId: UUID(), title: "Idea 1", budgetMin: 0, budgetMax: 0, status: .idea),
            GiftIdea(personId: UUID(), title: "Idea 2", budgetMin: 0, budgetMax: 0, status: .idea)
        ]
        let label = AccessibilityHelper.personLabel(person, daysUntil: nil)

        XCTAssertTrue(label.contains("2 Geschenkideen"), "Should contain gift count (plural)")
    }

    func testPersonLabelWithSingleGiftIdea() {
        let person = PersonRef(
            contactIdentifier: "test",
            displayName: "Test Person",
            birthday: Date(),
            relation: "Freund"
        )
        person.giftIdeas = [
            GiftIdea(personId: UUID(), title: "Idea 1", budgetMin: 0, budgetMax: 0, status: .idea)
        ]
        let label = AccessibilityHelper.personLabel(person, daysUntil: nil)

        XCTAssertTrue(label.contains("1 Geschenkidee"), "Should contain gift count (singular)")
    }

    func testPersonLabelWithoutBirthday() {
        let person = PersonRef(
            contactIdentifier: "test",
            displayName: "Test Person",
            birthday: Date(),
            relation: "Freund"
        )
        let label = AccessibilityHelper.personLabel(person, daysUntil: nil)

        XCTAssertTrue(label.contains("Test Person"), "Should contain display name")
        XCTAssertFalse(label.contains("Nächster Geburtstag:"), "Should not contain birthday when nil")
    }

    // MARK: - Gift History Label Tests

    func testGiftHistoryLabelBasic() {
        let history = GiftHistory(
            personId: UUID(),
            title: "Test Geschenk",
            category: "Bücher",
            year: 2025,
            budget: 30,
            note: "",
            link: ""
        )
        let label = AccessibilityHelper.giftHistoryLabel(history)

        XCTAssertTrue(label.contains("Test Geschenk"), "Should contain title")
        XCTAssertTrue(label.contains("Jahr:"), "Should contain year label")
        XCTAssertTrue(label.contains("2025"), "Should contain year")
        XCTAssertTrue(label.contains("Kategorie:"), "Should contain category label")
        XCTAssertTrue(label.contains("Bücher"), "Should contain category")
    }

    func testGiftHistoryLabelWithBudget() {
        let history = GiftHistory(
            personId: UUID(),
            title: "Test",
            category: "Test",
            year: 2025,
            budget: 50,
            note: "",
            link: ""
        )
        let label = AccessibilityHelper.giftHistoryLabel(history)

        XCTAssertTrue(label.contains("Budget:"), "Should contain budget label")
        XCTAssertTrue(label.contains("Euro"), "Should contain currency")
    }

    func testGiftHistoryLabelWithNote() {
        let history = GiftHistory(
            personId: UUID(),
            title: "Test",
            category: "Test",
            year: 2025,
            budget: 0,
            note: "Notiz",
            link: ""
        )
        let label = AccessibilityHelper.giftHistoryLabel(history)

        XCTAssertTrue(label.contains("Notiz:"), "Should contain note label")
        XCTAssertTrue(label.contains("Notiz"), "Should contain note content")
    }

    // MARK: - Edge Cases

    func testFormatBudgetNegativeValues() {
        let formatted = AccessibilityHelper.formatBudget(-10, 50)

        // Should still format, though negative budgets don't make sense
        XCTAssertFalse(formatted.isEmpty, "Should handle negative values")
    }

    func testFormatBudgetLargeValues() {
        let formatted = AccessibilityHelper.formatBudget(1000, 5000)

        XCTAssertTrue(formatted.contains("1000"), "Should contain min")
        XCTAssertTrue(formatted.contains("5000"), "Should contain max")
    }

    func testFormatDaysUntilZero() {
        let formatted = AccessibilityHelper.formatDaysUntil(0)

        XCTAssertEqual(formatted, "Heute", "Zero days should be 'Heute'")
    }

    func testFormatDaysUntilLargeNumber() {
        let formatted = AccessibilityHelper.formatDaysUntil(365)

        XCTAssertTrue(formatted.contains("365"), "Should contain number of days")
        XCTAssertTrue(formatted.contains("ab heute"), "Should contain 'ab heute' for large numbers")
    }

    func testGiftIdeaLabelEmptyTitle() {
        let idea = GiftIdea(personId: UUID(), title: "", budgetMin: 0, budgetMax: 0, status: .idea)
        let label = AccessibilityHelper.giftIdeaLabel(idea, includeStatus: true)

        XCTAssertTrue(label.contains("Geschenkidee"), "Should still work with empty title")
    }

    func testPersonLabelEmptyGiftIdeas() {
        let person = PersonRef(
            contactIdentifier: "test",
            displayName: "Test Person",
            birthday: Date(),
            relation: "Freund"
        )
        person.giftIdeas = []
        let label = AccessibilityHelper.personLabel(person, daysUntil: nil)

        XCTAssertFalse(label.contains("Geschenkidee"), "Should not mention gift count when empty")
    }

    // MARK: - Helper Methods

    private func createDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12 // Noon to avoid timezone issues

        return Calendar.current.date(from: components) ?? Date()
    }
}
