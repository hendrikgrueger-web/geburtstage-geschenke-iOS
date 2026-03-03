import XCTest
@testable import aiPresentsApp

final class ModelValidationTests: XCTestCase {

    func testGiftIdeaCreation() {
        let idea = GiftIdea(
            personId: UUID(),
            title: "Test Gift",
            note: "Test Note",
            budgetMin: 10,
            budgetMax: 50,
            link: "https://example.com",
            status: .idea,
            tags: ["books", "tech"]
        )

        XCTAssertEqual(idea.title, "Test Gift")
        XCTAssertEqual(idea.note, "Test Note")
        XCTAssertEqual(idea.budgetMin, 10)
        XCTAssertEqual(idea.budgetMax, 50)
        XCTAssertEqual(idea.link, "https://example.com")
        XCTAssertEqual(idea.status, .idea)
        XCTAssertEqual(idea.tags, ["books", "tech"])
        XCTAssertNotNil(idea.id)
        XCTAssertNotNil(idea.createdAt)
    }

    func testGiftIdeaDefaultValues() {
        let idea = GiftIdea(
            personId: UUID(),
            title: "Test Gift"
        )

        XCTAssertEqual(idea.note, "")
        XCTAssertEqual(idea.budgetMin, 0)
        XCTAssertEqual(idea.budgetMax, 0)
        XCTAssertEqual(idea.link, "")
        XCTAssertEqual(idea.status, .idea)
        XCTAssertEqual(idea.tags, [])
        XCTAssertNotNil(idea.createdAt)
    }

    func testGiftStatusRawValues() {
        XCTAssertEqual(GiftStatus.idea.rawValue, "idea")
        XCTAssertEqual(GiftStatus.planned.rawValue, "planned")
        XCTAssertEqual(GiftStatus.purchased.rawValue, "purchased")
        XCTAssertEqual(GiftStatus.given.rawValue, "given")
    }

    func testPersonRefCreation() {
        let person = PersonRef(
            contactIdentifier: "123",
            displayName: "John Doe",
            birthday: Date(),
            relation: "Friend"
        )

        XCTAssertEqual(person.contactIdentifier, "123")
        XCTAssertEqual(person.displayName, "John Doe")
        XCTAssertEqual(person.relation, "Friend")
        XCTAssertNotNil(person.id)
        XCTAssertNotNil(person.updatedAt)
    }

    func testPersonRefDefaultRelation() {
        let person = PersonRef(
            contactIdentifier: "123",
            displayName: "John Doe",
            birthday: Date()
        )

        XCTAssertEqual(person.relation, "Sonstige")
    }

    func testReminderRuleCreation() {
        let rule = ReminderRule(
            leadDays: [30, 14, 7, 2],
            quietHoursStart: 22,
            quietHoursEnd: 8,
            enabled: true
        )

        XCTAssertEqual(rule.leadDays, [30, 14, 7, 2])
        XCTAssertEqual(rule.quietHoursStart, 22)
        XCTAssertEqual(rule.quietHoursEnd, 8)
        XCTAssertTrue(rule.enabled)
        XCTAssertNotNil(rule.id)
    }

    func testReminderRuleDefaultValues() {
        let rule = ReminderRule()

        XCTAssertEqual(rule.leadDays, [30, 14, 7, 2])
        XCTAssertEqual(rule.quietHoursStart, 22)
        XCTAssertEqual(rule.quietHoursEnd, 8)
        XCTAssertTrue(rule.enabled)
    }

    func testReminderRuleEmptyLeadDays() {
        let rule = ReminderRule(leadDays: [], quietHoursStart: 22, quietHoursEnd: 8, enabled: true)
        XCTAssertTrue(rule.leadDays.isEmpty)
    }

    func testGiftHistoryCreation() {
        let history = GiftHistory(
            personId: UUID(),
            title: "Test Gift",
            category: "Books",
            year: 2025,
            budget: 100,
            note: "Great gift!",
            link: "https://example.com"
        )

        XCTAssertEqual(history.title, "Test Gift")
        XCTAssertEqual(history.year, 2025)
        XCTAssertEqual(history.budget, 100)
        XCTAssertEqual(history.category, "Books")
        XCTAssertEqual(history.link, "https://example.com")
        XCTAssertEqual(history.note, "Great gift!")
        XCTAssertNotNil(history.id)
    }
}
