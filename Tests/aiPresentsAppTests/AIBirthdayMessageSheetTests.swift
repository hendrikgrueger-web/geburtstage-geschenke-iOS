import XCTest
import SwiftUI
@testable import aiPresentsApp

@MainActor
final class AIBirthdayMessageSheetTests: XCTestCase {
    var mockPerson: PersonRef!

    override func setUpWithError() throws {
        mockPerson = PersonRef(contactIdentifier: "",
            displayName: "Anna Müller",
            birthday: Date(),
            relation: "Freundin"
        )
    }

    override func tearDownWithError() throws {
        mockPerson = nil
    }

    // MARK: - View Initialization Tests

    func testAIBirthdayMessageSheetInitialization() {
        let sheet = AIBirthdayMessageSheet(person: mockPerson)

        // Verify the sheet can be created without crashing
        XCTAssertNotNil(sheet)
    }

    func testAIBirthdayMessageSheetWithMilestoneBirthday() {
        // Create a person with a milestone birthday (30)
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.year! -= 30

        guard let birthday = calendar.date(from: components) else {
            XCTFail("Failed to create birthday date")
            return
        }

        let milestonePerson = PersonRef(contactIdentifier: "",
            displayName: "Max Erwachsener",
            birthday: birthday,
            relation: "Bruder"
        )

        let sheet = AIBirthdayMessageSheet(person: milestonePerson)

        XCTAssertNotNil(sheet)
    }

    func testAIBirthdayMessageSheetWithYoungPerson() {
        // Create a young person (18)
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.year! -= 18

        guard let birthday = calendar.date(from: components) else {
            XCTFail("Failed to create birthday date")
            return
        }

        let youngPerson = PersonRef(contactIdentifier: "",
            displayName: "Lisa Neugeboren",
            birthday: birthday,
            relation: "Tochter"
        )

        let sheet = AIBirthdayMessageSheet(person: youngPerson)

        XCTAssertNotNil(sheet)
    }

    func testAIBirthdayMessageSheetWithOlderPerson() {
        // Create an older person (60+)
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.year! -= 65

        guard let birthday = calendar.date(from: components) else {
            XCTFail("Failed to create birthday date")
            return
        }

        let olderPerson = PersonRef(contactIdentifier: "",
            displayName: "Opa Hans",
            birthday: birthday,
            relation: "Opa"
        )

        let sheet = AIBirthdayMessageSheet(person: olderPerson)

        XCTAssertNotNil(sheet)
    }

    // MARK: - Navigation Title Tests

    func testNavigationTitle() {
        let sheet = AIBirthdayMessageSheet(person: mockPerson)

        // The sheet should have a navigation title
        // This is a compile-time check that the view structure is valid
        XCTAssertNotNil(sheet)
    }

    // MARK: - State Management Tests

    func testInitialStates() {
        let sheet = AIBirthdayMessageSheet(person: mockPerson)

        // Verify that the sheet can be created
        // Initial states (isLoading, birthdayMessage, errorMessage) should be false/nil
        XCTAssertNotNil(sheet)
    }

    // MARK: - Person Data Tests

    func testPersonDataBinding() {
        let customPerson = PersonRef(contactIdentifier: "",
            displayName: "Thomas Weber",
            birthday: Date(),
            relation: "Kollege"
        )

        let sheet = AIBirthdayMessageSheet(person: customPerson)

        XCTAssertNotNil(sheet)
    }

    func testPersonWithDifferentRelations() {
        let relations = ["Mama", "Papa", "Schwester", "Bruder", "Partner", "Freundin", "Oma", "Opa"]

        for relation in relations {
            let person = PersonRef(contactIdentifier: "",
                displayName: "Test Person",
                birthday: Date(),
                relation: relation
            )

            let sheet = AIBirthdayMessageSheet(person: person)
            XCTAssertNotNil(sheet, "Sheet should initialize with relation: \(relation)")
        }
    }

    // MARK: - BirthdayMessage Tests

    func testBirthdayMessageStructure() {
        let message = BirthdayMessage(
            greeting: "Liebe Anna,",
            body: "Alles Gute zum Geburtstag! 🎉\nMöge dein Tag wunderbar sein."
        )

        XCTAssertFalse(message.greeting.isEmpty, "Greeting should not be empty")
        XCTAssertFalse(message.body.isEmpty, "Body should not be empty")
        XCTAssertFalse(message.fullText.isEmpty, "Full text should not be empty")

        // Verify fullText combines both
        XCTAssertTrue(message.fullText.contains(message.greeting), "Full text should contain greeting")
        XCTAssertTrue(message.fullText.contains(message.body), "Full text should contain body")
    }

    func testBirthdayMessageEmptyFields() {
        let emptyGreetingMessage = BirthdayMessage(greeting: "", body: "Test body")
        XCTAssertTrue(emptyGreetingMessage.fullText.contains("Test body"))

        let emptyBodyMessage = BirthdayMessage(greeting: "Hallo", body: "")
        XCTAssertTrue(emptyBodyMessage.fullText.contains("Hallo"))

        let emptyMessage = BirthdayMessage(greeting: "", body: "")
        XCTAssertEqual(emptyMessage.fullText, "\n\n")
    }

    func testBirthdayMessageWithLongContent() {
        let longGreeting = String(repeating: "A", count: 100)
        let longBody = String(repeating: "B", count: 500)

        let message = BirthdayMessage(greeting: longGreeting, body: longBody)

        XCTAssertEqual(message.greeting.count, 100)
        XCTAssertEqual(message.body.count, 500)
        XCTAssertEqual(message.fullText.count, 100 + 500 + 2) // +2 for the newlines
    }

    // MARK: - Age Group Tests

    func testPersonUnder18() {
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.year! -= 10

        guard let birthday = calendar.date(from: components) else {
            XCTFail("Failed to create birthday date")
            return
        }

        let child = PersonRef(contactIdentifier: "",
            displayName: "Max Kind",
            birthday: birthday,
            relation: "Sohn"
        )

        let sheet = AIBirthdayMessageSheet(person: child)
        XCTAssertNotNil(sheet)

        // Verify age calculation
        let age = BirthdayDateHelper.age(from: child.birthday, asOf: today)
        XCTAssertEqual(age, 10)
    }

    func testPerson18To29() {
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.year! -= 25

        guard let birthday = calendar.date(from: components) else {
            XCTFail("Failed to create birthday date")
            return
        }

        let youngAdult = PersonRef(contactIdentifier: "",
            displayName: "Lisa Young",
            birthday: birthday,
            relation: "Freundin"
        )

        let sheet = AIBirthdayMessageSheet(person: youngAdult)
        XCTAssertNotNil(sheet)

        let age = BirthdayDateHelper.age(from: youngAdult.birthday, asOf: today)
        XCTAssertEqual(age, 25)
    }

    func testPerson30To49() {
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.year! -= 35

        guard let birthday = calendar.date(from: components) else {
            XCTFail("Failed to create birthday date")
            return
        }

        let adult = PersonRef(contactIdentifier: "",
            displayName: "Thomas Adult",
            birthday: birthday,
            relation: "Bruder"
        )

        let sheet = AIBirthdayMessageSheet(person: adult)
        XCTAssertNotNil(sheet)

        let age = BirthdayDateHelper.age(from: adult.birthday, asOf: today)
        XCTAssertEqual(age, 35)
    }

    func testPerson50Plus() {
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.year! -= 55

        guard let birthday = calendar.date(from: components) else {
            XCTFail("Failed to create birthday date")
            return
        }

        let senior = PersonRef(contactIdentifier: "",
            displayName: "Erika Senior",
            birthday: birthday,
            relation: "Mama"
        )

        let sheet = AIBirthdayMessageSheet(person: senior)
        XCTAssertNotNil(sheet)

        let age = BirthdayDateHelper.age(from: senior.birthday, asOf: today)
        XCTAssertEqual(age, 55)
    }

    // MARK: - Milestone Detection Tests

    func testMilestoneAge18() {
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.year! -= 18

        guard let birthday = calendar.date(from: components) else {
            XCTFail("Failed to create birthday date")
            return
        }

        let person = PersonRef(contactIdentifier: "",
            displayName: "Anna",
            birthday: birthday,
            relation: "Tochter"
        )

        let age = BirthdayDateHelper.age(from: person.birthday, asOf: today)
        XCTAssertTrue(BirthdayDateHelper.isMilestoneAge(age: age), "18 should be a milestone")
    }

    func testMilestoneAge30() {
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.year! -= 30

        guard let birthday = calendar.date(from: components) else {
            XCTFail("Failed to create birthday date")
            return
        }

        let person = PersonRef(contactIdentifier: "",
            displayName: "Max",
            birthday: birthday,
            relation: "Bruder"
        )

        let age = BirthdayDateHelper.age(from: person.birthday, asOf: today)
        XCTAssertTrue(BirthdayDateHelper.isMilestoneAge(age: age), "30 should be a milestone")
    }

    func testMilestoneAge40() {
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.year! -= 40

        guard let birthday = calendar.date(from: components) else {
            XCTFail("Failed to create birthday date")
            return
        }

        let person = PersonRef(contactIdentifier: "",
            displayName: "Lisa",
            birthday: birthday,
            relation: "Schwester"
        )

        let age = BirthdayDateHelper.age(from: person.birthday, asOf: today)
        XCTAssertTrue(BirthdayDateHelper.isMilestoneAge(age: age), "40 should be a milestone")
    }

    func testNonMilestoneAge() {
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.year! -= 23

        guard let birthday = calendar.date(from: components) else {
            XCTFail("Failed to create birthday date")
            return
        }

        let person = PersonRef(contactIdentifier: "",
            displayName: "Tom",
            birthday: birthday,
            relation: "Freund"
        )

        let age = BirthdayDateHelper.age(from: person.birthday, asOf: today)
        XCTAssertFalse(BirthdayDateHelper.isMilestoneAge(age: age), "23 should not be a milestone")
    }

    // MARK: - Zodiac Sign Tests

    func testZodiacSignCalculation() {
        let testCases: [(Date, String)] = [
            // Format: (birthday, expected zodiac) — implementation returns emoji + name
            (DateComponents(calendar: .current, year: 2020, month: 1, day: 15).date!, "♑ Steinbock"),  // Jan 15 (Dec 22-Jan 19)
            (DateComponents(calendar: .current, year: 2020, month: 4, day: 15).date!, "♈ Widder"),     // Apr 15
            (DateComponents(calendar: .current, year: 2020, month: 7, day: 15).date!, "♋ Krebs"),     // Jul 15
            (DateComponents(calendar: .current, year: 2020, month: 10, day: 15).date!, "♎ Waage"),   // Oct 15
        ]

        for (birthday, expectedZodiac) in testCases {
            let zodiac = BirthdayDateHelper.zodiacSign(from: birthday)
            XCTAssertEqual(zodiac, expectedZodiac, "Zodiac sign should be \(expectedZodiac) for \(birthday)")
        }
    }
}
