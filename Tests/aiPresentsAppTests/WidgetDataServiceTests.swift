import XCTest
@testable import aiPresentsApp

@MainActor
final class WidgetDataServiceTests: XCTestCase {
    private let referenceDate = Calendar.current.date(
        from: DateComponents(year: 2026, month: 3, day: 24, hour: 12)
    )!

    override func setUp() {
        super.setUp()
        BirthdayCalculator.clearCache()
    }

    override func tearDown() {
        BirthdayCalculator.clearCache()
        super.tearDown()
    }

    func testMakeEntriesSortsByUpcomingBirthday() {
        let people = [
            makePerson(name: "In Five Days", birthday: birthday(daysFromReference: 5)),
            makePerson(name: "Today", birthday: birthday(daysFromReference: 0)),
            makePerson(name: "Tomorrow", birthday: birthday(daysFromReference: 1))
        ]

        let entries = WidgetDataService.makeEntries(people: people, ideas: [], today: referenceDate)

        XCTAssertEqual(entries.map(\.displayName), ["Today", "Tomorrow", "In Five Days"])
        // daysUntil wird dynamisch im Widget berechnet — prüfe stattdessen Sortierung via nextBirthdayDate
        XCTAssertEqual(entries.count, 3)
        XCTAssertTrue(entries[0].nextBirthdayDate <= entries[1].nextBirthdayDate)
        XCTAssertTrue(entries[1].nextBirthdayDate <= entries[2].nextBirthdayDate)
    }

    func testMakeEntriesLimitsToTenEntries() {
        let people = (0..<12).map { offset in
            makePerson(name: "Person \(offset)", birthday: birthday(daysFromReference: offset))
        }

        let entries = WidgetDataService.makeEntries(people: people, ideas: [], today: referenceDate)

        XCTAssertEqual(entries.count, 10)
        XCTAssertEqual(entries.first?.displayName, "Person 0")
        XCTAssertEqual(entries.last?.displayName, "Person 9")
    }

    func testMakeEntriesComputesGiftStatusPriority() {
        let skipPerson = makePerson(name: "Skip", birthday: birthday(daysFromReference: 0), skipGift: true)
        let purchasedPerson = makePerson(name: "Purchased", birthday: birthday(daysFromReference: 1))
        let plannedPerson = makePerson(name: "Planned", birthday: birthday(daysFromReference: 2))
        let ideasPerson = makePerson(name: "Ideas", birthday: birthday(daysFromReference: 3))
        let nonePerson = makePerson(name: "None", birthday: birthday(daysFromReference: 4))

        let ideas = [
            GiftIdea(personId: purchasedPerson.id, title: "Book", status: .purchased),
            GiftIdea(personId: plannedPerson.id, title: "Museum", status: .planned),
            GiftIdea(personId: ideasPerson.id, title: "Tea", status: .idea),
            GiftIdea(personId: ideasPerson.id, title: "Flowers", status: .idea)
        ]

        let entries = WidgetDataService.makeEntries(
            people: [skipPerson, purchasedPerson, plannedPerson, ideasPerson, nonePerson],
            ideas: ideas,
            today: referenceDate
        )

        let statuses = Dictionary(uniqueKeysWithValues: entries.map { ($0.displayName, $0.giftStatus) })

        XCTAssertEqual(statuses["Skip"], "skip")
        XCTAssertEqual(statuses["Purchased"], "purchased")
        XCTAssertEqual(statuses["Planned"], "planned")
        XCTAssertEqual(statuses["Ideas"], "ideas:2")
        XCTAssertEqual(statuses["None"], "none")
    }

    func testMakeEntriesSetsUnknownBirthYearAgeToZero() {
        let person = makePerson(name: "Unknown Age", birthday: birthday(daysFromReference: 0))
        person.birthYearKnown = false

        let entries = WidgetDataService.makeEntries(people: [person], ideas: [], today: referenceDate)

        XCTAssertEqual(entries.first?.nextAge, 0)
    }

    private func makePerson(
        name: String,
        birthday: Date,
        skipGift: Bool = false
    ) -> PersonRef {
        let person = PersonRef(
            contactIdentifier: UUID().uuidString,
            displayName: name,
            birthday: birthday,
            relation: "Family"
        )
        person.skipGift = skipGift
        return person
    }

    private func birthday(daysFromReference offset: Int, birthYear: Int = 1990) -> Date {
        let target = Calendar.current.date(byAdding: .day, value: offset, to: referenceDate)!
        let components = Calendar.current.dateComponents([.month, .day], from: target)
        return Calendar.current.date(
            from: DateComponents(year: birthYear, month: components.month, day: components.day, hour: 12)
        )!
    }
}
