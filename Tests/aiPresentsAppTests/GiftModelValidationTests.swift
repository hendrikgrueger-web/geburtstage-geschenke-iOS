import XCTest
import SwiftData
@testable import aiPresentsApp

@MainActor
final class GiftModelValidationTests: XCTestCase {
    var modelContext: ModelContext!
    var person: PersonRef!

    override func setUp() async throws {
        let schema = Schema([PersonRef.self, GiftIdea.self, GiftHistory.self, ReminderRule.self, SuggestionFeedback.self])
        let config = ModelConfiguration("test", isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [config])
        modelContext = container.mainContext

        person = PersonRef(
            contactIdentifier: "test-123",
            displayName: "Test Person",
            birthday: Date(),
            relation: "Friend"
        )
        modelContext.insert(person)
    }

    // MARK: - GiftIdea Tests

    func testGiftIdeaCreation() {
        let idea = GiftIdea(
            personId: person.id,
            title: "Buch",
            note: "Thriller",
            budgetMin: 10,
            budgetMax: 20,
            link: "https://example.com",
            status: .idea,
            tags: ["Geburtstag", "Bücher"]
        )

        modelContext.insert(idea)

        XCTAssertNotNil(idea.id)
        XCTAssertEqual(idea.personId, person.id)
        XCTAssertEqual(idea.title, "Buch")
        XCTAssertEqual(idea.note, "Thriller")
        XCTAssertEqual(idea.budgetMin, 10)
        XCTAssertEqual(idea.budgetMax, 20)
        XCTAssertEqual(idea.link, "https://example.com")
        XCTAssertEqual(idea.status, .idea)
        XCTAssertEqual(idea.tags.count, 2)
    }

    func testGiftIdeaMinimalCreation() {
        let idea = GiftIdea(
            personId: person.id,
            title: "Geschenk",
            note: "",
            budgetMin: 0,
            budgetMax: 0,
            link: "",
            status: .idea,
            tags: []
        )

        modelContext.insert(idea)

        XCTAssertEqual(idea.title, "Geschenk")
        XCTAssertTrue(idea.note.isEmpty)
        XCTAssertEqual(idea.budgetMin, 0)
        XCTAssertEqual(idea.budgetMax, 0)
        XCTAssertTrue(idea.link.isEmpty)
        XCTAssertTrue(idea.tags.isEmpty)
    }

    func testGiftIdeaStatusChange() {
        let idea = GiftIdea(
            personId: person.id,
            title: "Geschenk",
            note: "",
            budgetMin: 0,
            budgetMax: 0,
            link: "",
            status: .idea,
            tags: []
        )

        modelContext.insert(idea)

        idea.status = .planned
        XCTAssertEqual(idea.status, .planned)

        idea.status = .purchased
        XCTAssertEqual(idea.status, .purchased)

        idea.status = .given
        XCTAssertEqual(idea.status, .given)
    }

    func testGiftIdeaAllStatuses() {
        let statuses: [GiftStatus] = [.idea, .planned, .purchased, .given]

        for status in statuses {
            let idea = GiftIdea(
                personId: person.id,
                title: "Geschenk \(status)",
                note: "",
                budgetMin: 0,
                budgetMax: 0,
                link: "",
                status: status,
                tags: []
            )
            modelContext.insert(idea)
        }

        let descriptor = FetchDescriptor<GiftIdea>()
        let ideas = try? modelContext.fetch(descriptor)

        XCTAssertEqual(ideas?.count, 4)
    }

    func testGiftIdeaTagsModification() {
        let idea = GiftIdea(
            personId: person.id,
            title: "Geschenk",
            note: "",
            budgetMin: 0,
            budgetMax: 0,
            link: "",
            status: .idea,
            tags: ["tag1"]
        )

        modelContext.insert(idea)

        idea.tags.append("tag2")
        XCTAssertEqual(idea.tags.count, 2)

        idea.tags.remove(at: 0)
        XCTAssertEqual(idea.tags.count, 1)
        XCTAssertEqual(idea.tags.first, "tag2")
    }

    func testGiftIdeaBudgetUpdate() {
        let idea = GiftIdea(
            personId: person.id,
            title: "Geschenk",
            note: "",
            budgetMin: 10,
            budgetMax: 20,
            link: "",
            status: .idea,
            tags: []
        )

        modelContext.insert(idea)

        idea.budgetMin = 15
        idea.budgetMax = 25

        XCTAssertEqual(idea.budgetMin, 15)
        XCTAssertEqual(idea.budgetMax, 25)
    }

    func testGiftIdeaLinkUpdate() {
        let idea = GiftIdea(
            personId: person.id,
            title: "Geschenk",
            note: "",
            budgetMin: 0,
            budgetMax: 0,
            link: "https://old-url.com",
            status: .idea,
            tags: []
        )

        modelContext.insert(idea)

        idea.link = "https://new-url.com"

        XCTAssertEqual(idea.link, "https://new-url.com")
    }

    func testMultipleGiftIdeasForSamePerson() {
        let idea1 = GiftIdea(
            personId: person.id,
            title: "Geschenk 1",
            note: "",
            budgetMin: 0,
            budgetMax: 0,
            link: "",
            status: .idea,
            tags: []
        )

        let idea2 = GiftIdea(
            personId: person.id,
            title: "Geschenk 2",
            note: "",
            budgetMin: 0,
            budgetMax: 0,
            link: "",
            status: .planned,
            tags: []
        )

        modelContext.insert(idea1)
        modelContext.insert(idea2)

        let personId = person.id
        let descriptor = FetchDescriptor<GiftIdea>(
            predicate: #Predicate { $0.personId == personId }
        )
        let ideas = try? modelContext.fetch(descriptor)

        XCTAssertEqual(ideas?.count, 2)
    }

    // MARK: - GiftHistory Tests

    func testGiftHistoryCreation() {
        let history = GiftHistory(
            personId: person.id,
            title: "Uhr",
            category: "Elektronik",
            year: 2023,
            budget: 150,
            note: "Geburtstagsgeschenk",
            link: "https://example.com"
        )

        modelContext.insert(history)

        XCTAssertNotNil(history.id)
        XCTAssertEqual(history.personId, person.id)
        XCTAssertEqual(history.title, "Uhr")
        XCTAssertEqual(history.year, 2023)
        XCTAssertEqual(history.category, "Elektronik")
        XCTAssertEqual(history.budget, 150)
        XCTAssertEqual(history.link, "https://example.com")
        XCTAssertEqual(history.note, "Geburtstagsgeschenk")
    }

    func testGiftHistoryMinimalCreation() {
        let history = GiftHistory(
            personId: person.id,
            title: "Geschenk",
            category: "",
            year: 2023,
            budget: 0,
            note: "",
            link: ""
        )

        modelContext.insert(history)

        XCTAssertEqual(history.title, "Geschenk")
        XCTAssertTrue(history.category.isEmpty)
        XCTAssertEqual(history.budget, 0)
        XCTAssertTrue(history.link.isEmpty)
        XCTAssertTrue(history.note.isEmpty)
    }

    func testGiftHistoryYearUpdate() {
        let history = GiftHistory(
            personId: person.id,
            title: "Geschenk",
            category: "",
            year: 2023,
            budget: 0,
            note: "",
            link: ""
        )

        modelContext.insert(history)

        history.year = 2024

        XCTAssertEqual(history.year, 2024)
    }

    func testGiftHistoryCategoryUpdate() {
        let history = GiftHistory(
            personId: person.id,
            title: "Geschenk",
            category: "Bücher",
            year: 2023,
            budget: 0,
            note: "",
            link: ""
        )

        modelContext.insert(history)

        history.category = "Elektronik"

        XCTAssertEqual(history.category, "Elektronik")
    }

    func testGiftHistoryBudgetUpdate() {
        let history = GiftHistory(
            personId: person.id,
            title: "Geschenk",
            category: "",
            year: 2023,
            budget: 50,
            note: "",
            link: ""
        )

        modelContext.insert(history)

        history.budget = 75.5

        XCTAssertEqual(history.budget, 75.5)
    }

    func testMultipleGiftHistoryForSamePerson() {
        let history1 = GiftHistory(
            personId: person.id,
            title: "Geschenk 2023",
            category: "Bücher",
            year: 2023,
            budget: 20,
            note: "",
            link: ""
        )

        let history2 = GiftHistory(
            personId: person.id,
            title: "Geschenk 2024",
            category: "Elektronik",
            year: 2024,
            budget: 100,
            note: "",
            link: ""
        )

        modelContext.insert(history1)
        modelContext.insert(history2)

        let personId = person.id
        let descriptor = FetchDescriptor<GiftHistory>(
            predicate: #Predicate { $0.personId == personId }
        )
        let historyList = try? modelContext.fetch(descriptor)

        XCTAssertEqual(historyList?.count, 2)
    }

    func testGiftHistorySortedByYear() {
        let history1 = GiftHistory(
            personId: person.id,
            title: "Geschenk 2023",
            category: "",
            year: 2023,
            budget: 0,
            note: "",
            link: ""
        )

        let history2 = GiftHistory(
            personId: person.id,
            title: "Geschenk 2021",
            category: "",
            year: 2021,
            budget: 0,
            note: "",
            link: ""
        )

        let history3 = GiftHistory(
            personId: person.id,
            title: "Geschenk 2024",
            category: "",
            year: 2024,
            budget: 0,
            note: "",
            link: ""
        )

        modelContext.insert(history1)
        modelContext.insert(history2)
        modelContext.insert(history3)

        let personId = person.id
        let descriptor = FetchDescriptor<GiftHistory>(
            predicate: #Predicate { $0.personId == personId },
            sortBy: [SortDescriptor(\.year, order: .reverse)]
        )
        let historyList = try? modelContext.fetch(descriptor)

        XCTAssertEqual(historyList?.count, 3)
        XCTAssertEqual(historyList?[0].year, 2024)
        XCTAssertEqual(historyList?[1].year, 2023)
        XCTAssertEqual(historyList?[2].year, 2021)
    }

    // MARK: - PersonRef Relationship Tests

    func testPersonRefHasGiftIdeas() {
        let idea = GiftIdea(
            personId: person.id,
            title: "Geschenk",
            note: "",
            budgetMin: 0,
            budgetMax: 0,
            link: "",
            status: .idea,
            tags: []
        )

        modelContext.insert(idea)

        // Refresh person to get relationship
        modelContext.insert(idea)

        let personId = person.id
        let descriptor = FetchDescriptor<PersonRef>(predicate: #Predicate { $0.id == personId })
        let fetchedPerson = try? modelContext.fetch(descriptor).first

        XCTAssertNotNil(fetchedPerson)
        XCTAssertEqual(fetchedPerson?.giftIdeas?.count, 1)
    }

    func testPersonRefHasGiftHistory() {
        let history = GiftHistory(
            personId: person.id,
            title: "Geschenk",
            category: "",
            year: 2023,
            budget: 0,
            note: "",
            link: ""
        )

        modelContext.insert(history)

        let personId = person.id
        let descriptor = FetchDescriptor<PersonRef>(predicate: #Predicate { $0.id == personId })
        let fetchedPerson = try? modelContext.fetch(descriptor).first

        XCTAssertNotNil(fetchedPerson)
        XCTAssertEqual(fetchedPerson?.giftHistory?.count, 1)
    }

    func testDeletePersonDeletesRelatedGiftIdeas() {
        let idea = GiftIdea(
            personId: person.id,
            title: "Geschenk",
            note: "",
            budgetMin: 0,
            budgetMax: 0,
            link: "",
            status: .idea,
            tags: []
        )

        modelContext.insert(idea)

        let beforeDeleteDescriptor = FetchDescriptor<GiftIdea>()
        let beforeDeleteCount = try? modelContext.fetchCount(beforeDeleteDescriptor)

        XCTAssertEqual(beforeDeleteCount, 1)

        modelContext.delete(person)

        let afterDeleteDescriptor = FetchDescriptor<GiftIdea>()
        let afterDeleteCount = try? modelContext.fetchCount(afterDeleteDescriptor)

        XCTAssertEqual(afterDeleteCount, 0)
    }

    func testDeletePersonDeletesRelatedGiftHistory() {
        let history = GiftHistory(
            personId: person.id,
            title: "Geschenk",
            category: "",
            year: 2023,
            budget: 0,
            note: "",
            link: ""
        )

        modelContext.insert(history)

        let beforeDeleteDescriptor = FetchDescriptor<GiftHistory>()
        let beforeDeleteCount = try? modelContext.fetchCount(beforeDeleteDescriptor)

        XCTAssertEqual(beforeDeleteCount, 1)

        modelContext.delete(person)

        let afterDeleteDescriptor = FetchDescriptor<GiftHistory>()
        let afterDeleteCount = try? modelContext.fetchCount(afterDeleteDescriptor)

        XCTAssertEqual(afterDeleteCount, 0)
    }
}
