import XCTest
import SwiftData
@testable import aiPresentsApp

@MainActor
final class AppViewModelTests: XCTestCase {
    var modelContext: ModelContext!
    var appViewModel: AppViewModel!

    override func setUp() async throws {
        let schema = Schema([PersonRef.self, GiftIdea.self, GiftHistory.self, ReminderRule.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        modelContext = container.mainContext
        appViewModel = AppViewModel(modelContext: modelContext)
    }

    override func tearDown() async throws {
        modelContext = nil
        appViewModel = nil
    }

    func testCheckImportStatusWithNoContacts() {
        appViewModel.checkImportStatus()
        XCTAssertFalse(appViewModel.hasImportedContacts)
    }

    func testCheckImportStatusWithContacts() {
        let calendar = Calendar.current
        let today = Date()

        let person = PersonRef(contactIdentifier: "",
            displayName: "Test Person",
            birthday: calendar.date(byAdding: .day, value: 10, to: today) ?? today,
            relation: "Friend"
        )

        modelContext.insert(person)
        appViewModel.checkImportStatus()
        XCTAssertTrue(appViewModel.hasImportedContacts)
    }

    func testGetUpcomingBirthdaysEmpty() {
        let birthdays = appViewModel.getUpcomingBirthdays()
        XCTAssertTrue(birthdays.isEmpty)
    }

    func testGetUpcomingBirthdaysWithPeople() {
        let calendar = Calendar.current
        let today = Date()

        // Person with birthday in 5 days
        let person1 = PersonRef(contactIdentifier: "",
            displayName: "Anna",
            birthday: calendar.date(byAdding: .day, value: 5, to: today) ?? today,
            relation: "Friend"
        )

        // Person with birthday in 15 days
        let person2 = PersonRef(contactIdentifier: "",
            displayName: "Thomas",
            birthday: calendar.date(byAdding: .day, value: 15, to: today) ?? today,
            relation: "Family"
        )

        // Person with birthday in 35 days (outside range)
        let person3 = PersonRef(contactIdentifier: "",
            displayName: "Lisa",
            birthday: calendar.date(byAdding: .day, value: 35, to: today) ?? today,
            relation: "Colleague"
        )

        modelContext.insert(person1)
        modelContext.insert(person2)
        modelContext.insert(person3)

        let birthdays = appViewModel.getUpcomingBirthdays()

        XCTAssertEqual(birthdays.count, 2)
        XCTAssertEqual(birthdays.first?.displayName, "Anna")
        XCTAssertEqual(birthdays.last?.displayName, "Thomas")
    }

    func testGetUpcomingBirthdaysLimit() {
        let calendar = Calendar.current
        let today = Date()

        // Create 15 people with upcoming birthdays
        for i in 1...15 {
            let person = PersonRef(contactIdentifier: "",
                displayName: "Person \(i)",
                birthday: calendar.date(byAdding: .day, value: i, to: today) ?? today,
                relation: "Test"
            )
            modelContext.insert(person)
        }

        let birthdays = appViewModel.getUpcomingBirthdays(limit: 5)
        XCTAssertEqual(birthdays.count, 5)
    }

    func testGetUpcomingBirthdaysSorted() {
        let calendar = Calendar.current
        let today = Date()

        let person1 = PersonRef(contactIdentifier: "",
            displayName: "Zoe",
            birthday: calendar.date(byAdding: .day, value: 10, to: today) ?? today,
            relation: "Friend"
        )

        let person2 = PersonRef(contactIdentifier: "",
            displayName: "Adam",
            birthday: calendar.date(byAdding: .day, value: 2, to: today) ?? today,
            relation: "Family"
        )

        let person3 = PersonRef(contactIdentifier: "",
            displayName: "Mia",
            birthday: calendar.date(byAdding: .day, value: 5, to: today) ?? today,
            relation: "Colleague"
        )

        modelContext.insert(person1)
        modelContext.insert(person2)
        modelContext.insert(person3)

        let birthdays = appViewModel.getUpcomingBirthdays()

        XCTAssertEqual(birthdays.count, 3)
        XCTAssertEqual(birthdays[0].displayName, "Adam") // 2 days
        XCTAssertEqual(birthdays[1].displayName, "Mia") // 5 days
        XCTAssertEqual(birthdays[2].displayName, "Zoe") // 10 days
    }

    func testGetUpcomingBirthdaysPastBirthday() {
        let calendar = Calendar.current
        let today = Date()

        // Person with birthday yesterday (should be next year)
        let person = PersonRef(contactIdentifier: "",
            displayName: "Past Birthday",
            birthday: calendar.date(byAdding: .day, value: -1, to: today) ?? today,
            relation: "Test"
        )

        modelContext.insert(person)

        let birthdays = appViewModel.getUpcomingBirthdays()
        XCTAssertTrue(birthdays.isEmpty)
    }

    func testGetUpcomingBirthdaysToday() {
        let calendar = Calendar.current
        let today = Date()

        let person = PersonRef(contactIdentifier: "",
            displayName: "Today Birthday",
            birthday: today,
            relation: "Test"
        )

        modelContext.insert(person)

        let birthdays = appViewModel.getUpcomingBirthdays()
        XCTAssertEqual(birthdays.count, 1)
        XCTAssertEqual(birthdays.first?.displayName, "Today Birthday")
    }
}
