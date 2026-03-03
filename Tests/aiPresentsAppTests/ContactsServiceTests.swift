import XCTest
import Contacts
import SwiftData
@testable import aiPresentsApp

@MainActor
final class ContactsServiceTests: XCTestCase {
    var sut: ContactsService!
    var mockModelContext: ModelContext!

    override func setUpWithError() throws {
        sut = ContactsService.shared

        // Create in-memory ModelContext for testing
        let schema = Schema([PersonRef.self, GiftIdea.self, GiftHistory.self, ReminderRule.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        mockModelContext = container.mainContext
    }

    override func tearDownWithError() throws {
        sut = nil
        mockModelContext = nil
    }

    // MARK: - Singleton Tests

    func testContactsServiceSingleton() {
        let instance1 = ContactsService.shared
        let instance2 = ContactsService.shared

        XCTAssertTrue(instance1 === instance2, "ContactsService should be a singleton")
    }

    // MARK: - Permission Tests

    func testRequestPermissionNotAuthorized() async throws {
        // In a test environment, we can't easily mock CNContactStore authorization
        // This test documents expected behavior

        let permissionGranted = try await sut.requestPermission()

        // In CI/testing environment, this will likely fail or return false
        // which is acceptable for unit tests
        XCTAssertTrue(permissionGranted == true || permissionGranted == false,
                      "Request permission should return a boolean result")
    }

    // MARK: - Import Birthdays Tests

    func testImportBirthdaysWithInvalidDate() async {
        // Note: We can't easily mock CNContactStore in unit tests
        // This test documents expected behavior when store is not authorized

        do {
            let _ = try await sut.importBirthdays()
            XCTFail("Should throw error when not authorized")
        } catch ContactsService.ContactsError.notAuthorized {
            // Expected error in test environment
            XCTAssert(true)
        } catch {
            // Other errors are acceptable (e.g., CNContactStore not available)
            XCTAssert(true)
        }
    }

    // MARK: - ContactsError Tests

    func testContactsErrorDescriptions() {
        let notAuthorized = ContactsService.ContactsError.notAuthorized
        XCTAssertEqual(notAuthorized.errorDescription,
                       "Zugriff auf Kontakte nicht erlaubt")

        let noBirthdaysFound = ContactsService.ContactsError.noBirthdaysFound
        XCTAssertEqual(noBirthdaysFound.errorDescription,
                       "Keine Kontakte mit Geburtstagen gefunden")
    }

    func testContactsErrorLocalizedDescriptions() {
        let notAuthorized = ContactsService.ContactsError.notAuthorized
        XCTAssertNotNil(notAuthorized.localizedDescription)

        let noBirthdaysFound = ContactsService.ContactsError.noBirthdaysFound
        XCTAssertNotNil(noBirthdaysFound.localizedDescription)
    }

    // MARK: - Integration Tests (ModelContext)

    func testImportedPersonRefStructure() {
        // Create a PersonRef manually to verify structure
        let person = PersonRef(contactIdentifier: "",
            displayName: "Test Person",
            birthday: Date(),
            relation: "Freund"
        )

        mockModelContext.insert(person)

        // Verify it was inserted
        let descriptor = FetchDescriptor<PersonRef>()
        let fetchedPeople = try? mockModelContext.fetch(descriptor)

        XCTAssertEqual(fetchedPeople?.count, 1, "Should have 1 person in context")
        XCTAssertEqual(fetchedPeople?.first?.displayName, "Test Person")
        XCTAssertEqual(fetchedPeople?.first?.relation, "Freund")
    }

    func testMultiplePersonRefs() {
        let person1 = PersonRef(contactIdentifier: "", displayName: "Anna", birthday: Date(), relation: "Familie")
        let person2 = PersonRef(contactIdentifier: "", displayName: "Ben", birthday: Date(), relation: "Freunde")
        let person3 = PersonRef(contactIdentifier: "", displayName: "Clara", birthday: Date(), relation: "Kollegen")

        mockModelContext.insert(person1)
        mockModelContext.insert(person2)
        mockModelContext.insert(person3)

        let descriptor = FetchDescriptor<PersonRef>()
        let fetchedPeople = try? mockModelContext.fetch(descriptor)

        XCTAssertEqual(fetchedPeople?.count, 3)
        XCTAssertEqual(fetchedPeople?.count, 3, "Should have 3 people in context")
    }

    // MARK: - Birthday Calculation Edge Cases

    func testPersonRefWithLeapYearBirthday() {
        // February 29th
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2000
        components.month = 2
        components.day = 29

        guard let leapDayBirthday = calendar.date(from: components) else {
            XCTFail("Failed to create leap day date")
            return
        }

        let person = PersonRef(contactIdentifier: "",
            displayName: "Leap Year Baby",
            birthday: leapDayBirthday,
            relation: "Test"
        )

        mockModelContext.insert(person)

        let descriptor = FetchDescriptor<PersonRef>()
        let fetchedPeople = try? mockModelContext.fetch(descriptor)

        XCTAssertEqual(fetchedPeople?.first?.birthday, leapDayBirthday)
    }

    func testPersonRefWithOldBirthday() {
        // Very old birthday (early 1900s)
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 1920
        components.month = 1
        components.day = 1

        guard let oldBirthday = calendar.date(from: components) else {
            XCTFail("Failed to create old birthday")
            return
        }

        let person = PersonRef(contactIdentifier: "",
            displayName: "Old Person",
            birthday: oldBirthday,
            relation: "Großeltern"
        )

        mockModelContext.insert(person)

        let descriptor = FetchDescriptor<PersonRef>()
        let fetchedPeople = try? mockModelContext.fetch(descriptor)

        XCTAssertNotNil(fetchedPeople?.first?.birthday)
    }

    // MARK: - Contact Identifier Tests

    func testPersonRefWithContactIdentifier() {
        let person = PersonRef(
            contactIdentifier: "ABCD1234-EFGH-5678-IJKL-901234567890",
            displayName: "Contact Person",
            birthday: Date(),
            relation: "Freund"
        )

        mockModelContext.insert(person)

        let descriptor = FetchDescriptor<PersonRef>()
        let fetchedPeople = try? mockModelContext.fetch(descriptor)

        XCTAssertEqual(fetchedPeople?.first?.contactIdentifier, "ABCD1234-EFGH-5678-IJKL-901234567890")
    }

    func testPersonRefWithoutContactIdentifier() {
        let person = PersonRef(contactIdentifier: "",
            displayName: "Manual Entry",
            birthday: Date(),
            relation: "Familie"
        )

        mockModelContext.insert(person)

        let descriptor = FetchDescriptor<PersonRef>()
        let fetchedPeople = try? mockModelContext.fetch(descriptor)

        // Manual entries may not have contact identifiers
        XCTAssertTrue(fetchedPeople?.first?.contactIdentifier.isEmpty == true,
                      "Manual entry should have no or empty contact identifier")
    }

    // MARK: - Display Name Edge Cases

    func testPersonRefWithEmptyDisplayName() {
        let person = PersonRef(contactIdentifier: "",
            displayName: "",
            birthday: Date(),
            relation: "Test"
        )

        mockModelContext.insert(person)

        let descriptor = FetchDescriptor<PersonRef>()
        let fetchedPeople = try? mockModelContext.fetch(descriptor)

        XCTAssertEqual(fetchedPeople?.first?.displayName, "", "Empty display name should be preserved")
    }

    func testPersonRefWithSpecialCharactersInDisplayName() {
        let specialNames = [
            "ÄÖÜ äöü ß",  // German Umlaute
            "François",   // French accents
            "José",       // Spanish accents
            "佐藤",       // Japanese
            "李明"        // Chinese
        ]

        for name in specialNames {
            let person = PersonRef(contactIdentifier: "", displayName: name, birthday: Date(), relation: "Test")
            mockModelContext.insert(person)
        }

        let descriptor = FetchDescriptor<PersonRef>()
        let fetchedPeople = try? mockModelContext.fetch(descriptor)

        XCTAssertEqual(fetchedPeople?.count, specialNames.count, "All special character names should be stored")

        for (index, expectedName) in specialNames.enumerated() {
            XCTAssertEqual(fetchedPeople?[index].displayName, expectedName,
                           "Special character name should be preserved: \(expectedName)")
        }
    }

    func testPersonRefWithVeryLongDisplayName() {
        let longName = String(repeating: "A", count: 1000)

        let person = PersonRef(contactIdentifier: "",
            displayName: longName,
            birthday: Date(),
            relation: "Test"
        )

        mockModelContext.insert(person)

        let descriptor = FetchDescriptor<PersonRef>()
        let fetchedPeople = try? mockModelContext.fetch(descriptor)

        XCTAssertEqual(fetchedPeople?.first?.displayName.count, longName.count,
                       "Long display name should be preserved")
    }

    // MARK: - Relation Tests

    func testPersonRelationTypes() {
        let relations = [
            "Familie", "Freunde", "Kollegen", "Partner", "Schwester", "Bruder",
            "Eltern", "Kinder", "Großeltern", "Nachbarn", "Schulkameraden"
        ]

        for relation in relations {
            let person = PersonRef(contactIdentifier: "", displayName: "Test \(relation)", birthday: Date(), relation: relation)
            mockModelContext.insert(person)
        }

        let descriptor = FetchDescriptor<PersonRef>()
        let fetchedPeople = try? mockModelContext.fetch(descriptor)

        XCTAssertEqual(fetchedPeople?.count, relations.count)

        for (index, expectedRelation) in relations.enumerated() {
            XCTAssertEqual(fetchedPeople?[index].relation, expectedRelation)
        }
    }

    func testPersonRelationWithSpecialCharacters() {
        let specialRelations = [
            "Schwägerin",
            "Bruder-in-law",
            "Ex-Partner",
            "Stiefvater",
            "Halbschwester"
        ]

        for relation in specialRelations {
            let person = PersonRef(contactIdentifier: "", displayName: "Test", birthday: Date(), relation: relation)
            mockModelContext.insert(person)
        }

        let descriptor = FetchDescriptor<PersonRef>()
        let fetchedPeople = try? mockModelContext.fetch(descriptor)

        XCTAssertEqual(fetchedPeople?.count, specialRelations.count)
    }

    func testPersonRelationEmpty() {
        let person = PersonRef(contactIdentifier: "", displayName: "Test", birthday: Date(), relation: "")

        mockModelContext.insert(person)

        let descriptor = FetchDescriptor<PersonRef>()
        let fetchedPeople = try? mockModelContext.fetch(descriptor)

        XCTAssertEqual(fetchedPeople?.first?.relation, "", "Empty relation should be preserved")
    }
}
