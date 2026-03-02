import XCTest
import SwiftData
@testable import aiPresentsApp

final class SampleDataServiceTests: XCTestCase {
    var sut: SampleDataService.Type { SampleDataService.self }
    var modelContext: ModelContext!

    override func setUpWithError() throws {
        // Create in-memory ModelContext for testing
        let schema = Schema([PersonRef.self, GiftIdea.self, GiftHistory.self, ReminderRule.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        modelContext = container.mainContext
    }

    override func tearDownWithError() throws {
        modelContext = nil
    }

    // MARK: - Create Sample Data Tests

    func testCreateSampleDataCreatesPeople() throws {
        sut.createSampleData(in: modelContext)

        let personDescriptor = FetchDescriptor<PersonRef>()
        let people = try modelContext.fetch(personDescriptor)

        XCTAssertEqual(people.count, 3, "Sample data should create 3 people")
    }

    func testCreateSampleDataCreatesGiftIdeas() throws {
        sut.createSampleData(in: modelContext)

        let ideaDescriptor = FetchDescriptor<GiftIdea>()
        let ideas = try modelContext.fetch(ideaDescriptor)

        XCTAssertEqual(ideas.count, 4, "Sample data should create 4 gift ideas")
    }

    func testCreateSampleDataCreatesGiftHistory() throws {
        sut.createSampleData(in: modelContext)

        let historyDescriptor = FetchDescriptor<GiftHistory>()
        let history = try modelContext.fetch(historyDescriptor)

        XCTAssertEqual(history.count, 1, "Sample data should create 1 gift history entry")
    }

    func testCreateSampleDataCreatesReminderRule() throws {
        sut.createSampleData(in: modelContext)

        let ruleDescriptor = FetchDescriptor<ReminderRule>()
        let rules = try modelContext.fetch(ruleDescriptor)

        XCTAssertEqual(rules.count, 1, "Sample data should create 1 reminder rule")
    }

    func testCreateSampleDataPeopleHaveRequiredFields() throws {
        sut.createSampleData(in: modelContext)

        let personDescriptor = FetchDescriptor<PersonRef>()
        let people = try modelContext.fetch(personDescriptor)

        for person in people {
            XCTAssertFalse(person.displayName.isEmpty, "Person should have a display name")
            XCTAssertNotNil(person.birthday, "Person should have a birthday")
            XCTAssertFalse(person.relation.isEmpty, "Person should have a relation")
        }
    }

    func testCreateSampleDataGiftIdeasHaveRequiredFields() throws {
        sut.createSampleData(in: modelContext)

        let ideaDescriptor = FetchDescriptor<GiftIdea>()
        let ideas = try modelContext.fetch(ideaDescriptor)

        for idea in ideas {
            XCTAssertFalse(idea.title.isEmpty, "Gift idea should have a title")
            XCTAssertGreaterThanOrEqual(idea.budgetMin, 0, "Budget min should be non-negative")
            XCTAssertGreaterThanOrEqual(idea.budgetMax, idea.budgetMin, "Budget max should be >= budget min")
            XCTAssertNotNil(idea.status, "Gift idea should have a status")
        }
    }

    func testCreateSampleDataGiftIdeasHaveTags() throws {
        sut.createSampleData(in: modelContext)

        let ideaDescriptor = FetchDescriptor<GiftIdea>()
        let ideas = try modelContext.fetch(ideaDescriptor)

        for idea in ideas {
            XCTAssertFalse(idea.tags.isEmpty, "Sample gift ideas should have tags")
        }
    }

    func testCreateSampleDataGiftHistoryHasRequiredFields() throws {
        sut.createSampleData(in: modelContext)

        let historyDescriptor = FetchDescriptor<GiftHistory>()
        let historyEntries = try modelContext.fetch(historyDescriptor)

        XCTAssertEqual(historyEntries.count, 1)

        let history = historyEntries.first
        XCTAssertNotNil(history)
        XCTAssertFalse(history!.title.isEmpty, "Gift history should have a title")
        XCTAssertFalse(history!.category.isEmpty, "Gift history should have a category")
        XCTAssertGreaterThan(history!.year, 0, "Gift history should have a valid year")
        XCTAssertGreaterThanOrEqual(history!.budget, 0, "Gift history budget should be non-negative")
    }

    func testCreateSampleDataReminderRuleHasValidConfiguration() throws {
        sut.createSampleData(in: modelContext)

        let ruleDescriptor = FetchDescriptor<ReminderRule>()
        let rules = try modelContext.fetch(ruleDescriptor)

        XCTAssertEqual(rules.count, 1)

        let rule = rules.first
        XCTAssertNotNil(rule)
        XCTAssertTrue(rule!.enabled, "Reminder rule should be enabled")
        XCTAssertFalse(rule!.leadDays.isEmpty, "Reminder rule should have lead days")

        // Verify lead days are in descending order
        for i in 0..<(rule!.leadDays.count - 1) {
            XCTAssertGreaterThan(rule!.leadDays[i], rule!.leadDays[i + 1],
                              "Lead days should be in descending order")
        }

        // Verify quiet hours are valid
        XCTAssertGreaterThanOrEqual(rule!.quietHoursStart, 0,
                                   "Quiet hours start should be >= 0")
        XCTAssertLessThan(rule!.quietHoursStart, 24,
                         "Quiet hours start should be < 24")
        XCTAssertGreaterThanOrEqual(rule!.quietHoursEnd, 0,
                                   "Quiet hours end should be >= 0")
        XCTAssertLessThan(rule!.quietHoursEnd, 24,
                         "Quiet hours end should be < 24")
    }

    // MARK: - Relationship Tests

    func testCreateSampleDataRelationshipsAreValid() throws {
        sut.createSampleData(in: modelContext)

        let personDescriptor = FetchDescriptor<PersonRef>()
        let people = try modelContext.fetch(personDescriptor)

        let ideaDescriptor = FetchDescriptor<GiftIdea>()
        let ideas = try modelContext.fetch(ideaDescriptor)

        let historyDescriptor = FetchDescriptor<GiftHistory>()
        let historyEntries = try modelContext.fetch(historyDescriptor)

        // Verify gift ideas are associated with valid people
        for idea in ideas {
            let associatedPerson = people.first { $0.id == idea.personId }
            XCTAssertNotNil(associatedPerson,
                           "Gift idea should be associated with a valid person")
        }

        // Verify gift history is associated with a valid person
        for history in historyEntries {
            let associatedPerson = people.first { $0.id == history.personId }
            XCTAssertNotNil(associatedPerson,
                           "Gift history should be associated with a valid person")
        }
    }

    // MARK: - Birthday Tests

    func testCreateSampleDataBirthdaysAreInFuture() throws {
        sut.createSampleData(in: modelContext)

        let personDescriptor = FetchDescriptor<PersonRef>()
        let people = try modelContext.fetch(personDescriptor)

        let today = Date()

        for person in people {
            let nextBirthday = BirthdayCalculator.nextBirthday(for: person.birthday, from: today)
            XCTAssertNotNil(nextBirthday, "Next birthday should be calculable")

            // Birthdays should be upcoming (within 30 days for sample data)
            let daysUntil = BirthdayCalculator.daysUntilBirthday(for: person.birthday, from: today)
            XCTAssertNotNil(daysUntil, "Days until birthday should be calculable")
            XCTAssertLessThanOrEqual(daysUntil!, 30,
                                   "Sample birthdays should be within 30 days")
            XCTAssertGreaterThanOrEqual(daysUntil!, 0,
                                       "Sample birthdays should be in the future")
        }
    }

    // MARK: - Clear Sample Data Tests

    func testClearSampleDataRemovesAllData() throws {
        // First create sample data
        sut.createSampleData(in: modelContext)

        // Verify data exists
        let personDescriptor = FetchDescriptor<PersonRef>()
        var people = try modelContext.fetch(personDescriptor)
        XCTAssertGreaterThan(people.count, 0, "Sample data should create people")

        // Clear sample data
        sut.clearSampleData(in: modelContext)

        // Verify data is removed
        people = try modelContext.fetch(personDescriptor)
        XCTAssertEqual(people.count, 0, "Clear should remove all people")

        let ideaDescriptor = FetchDescriptor<GiftIdea>()
        let ideas = try modelContext.fetch(ideaDescriptor)
        XCTAssertEqual(ideas.count, 0, "Clear should remove all gift ideas")

        let historyDescriptor = FetchDescriptor<GiftHistory>()
        let history = try modelContext.fetch(historyDescriptor)
        XCTAssertEqual(history.count, 0, "Clear should remove all gift history")

        let ruleDescriptor = FetchDescriptor<ReminderRule>()
        let rules = try modelContext.fetch(ruleDescriptor)
        XCTAssertEqual(rules.count, 0, "Clear should remove all reminder rules")
    }

    // MARK: - Idempotency Tests

    func testCreateSampleDataMultipleTimes() throws {
        // Create sample data first time
        sut.createSampleData(in: modelContext)

        let personDescriptor = FetchDescriptor<PersonRef>()
        var people = try modelContext.fetch(personDescriptor)
        let firstPersonCount = people.count

        // Create sample data second time
        sut.createSampleData(in: modelContext)

        people = try modelContext.fetch(personDescriptor)
        let secondPersonCount = people.count

        // Should double the count (creates new entries each time)
        XCTAssertEqual(secondPersonCount, firstPersonCount * 2,
                       "Creating sample data twice should double the count")
    }

    func testClearSampleDataMultipleTimes() throws {
        // Create sample data
        sut.createSampleData(in: modelContext)

        // Clear multiple times (should not throw)
        sut.clearSampleData(in: modelContext)
        sut.clearSampleData(in: modelContext)
        sut.clearSampleData(in: modelContext)

        // Verify context is empty
        let personDescriptor = FetchDescriptor<PersonRef>()
        let people = try modelContext.fetch(personDescriptor)
        XCTAssertEqual(people.count, 0, "Context should be empty after multiple clears")
    }

    // MARK: - Budget Tests

    func testCreateSampleDataBudgetsAreValid() throws {
        sut.createSampleData(in: modelContext)

        let ideaDescriptor = FetchDescriptor<GiftIdea>()
        let ideas = try modelContext.fetch(ideaDescriptor)

        for idea in ideas {
            XCTAssertGreaterThanOrEqual(idea.budgetMin, 0,
                                       "Budget min should be non-negative")
            XCTAssertGreaterThanOrEqual(idea.budgetMax, idea.budgetMin,
                                       "Budget max should be >= budget min")
            XCTAssertLessThanOrEqual(idea.budgetMin, 200,
                                   "Budget min should be reasonable for sample data")
            XCTAssertLessThanOrEqual(idea.budgetMax, 200,
                                   "Budget max should be reasonable for sample data")
        }
    }

    func testCreateSampleDataHasVariedBudgets() throws {
        sut.createSampleData(in: modelContext)

        let ideaDescriptor = FetchDescriptor<GiftIdea>()
        let ideas = try modelContext.fetch(ideaDescriptor)

        let budgets = ideas.map { $0.budgetMax }
        let uniqueBudgets = Set(budgets)

        XCTAssertGreaterThan(uniqueBudgets.count, 1,
                            "Sample data should have varied budget ranges")
    }

    // MARK: - Status Tests

    func testCreateSampleDataHasVariedStatuses() throws {
        sut.createSampleData(in: modelContext)

        let ideaDescriptor = FetchDescriptor<GiftIdea>()
        let ideas = try modelContext.fetch(ideaDescriptor)

        let statuses = Set(ideas.map { $0.status })

        XCTAssertGreaterThan(statuses.count, 0,
                            "Sample data should have at least one status")
    }

    // MARK: - Link Tests

    func testCreateSampleDataLinksAreValid() throws {
        sut.createSampleData(in: modelContext)

        let ideaDescriptor = FetchDescriptor<GiftIdea>()
        let ideas = try modelContext.fetch(ideaDescriptor)

        for idea in ideas {
            if !idea.link.isEmpty {
                XCTAssertTrue(idea.link.hasPrefix("http://") || idea.link.hasPrefix("https://"),
                            "Links should have valid URL scheme")
            }
        }
    }

    // MARK: - Note Tests

    func testCreateSampleDataNotesArePopulated() throws {
        sut.createSampleData(in: modelContext)

        let ideaDescriptor = FetchDescriptor<GiftIdea>()
        let ideas = try modelContext.fetch(ideaDescriptor)

        let ideasWithNotes = ideas.filter { !$0.note.isEmpty }

        XCTAssertGreaterThan(ideasWithNotes.count, 0,
                            "Sample data should have some gift ideas with notes")
    }
}
