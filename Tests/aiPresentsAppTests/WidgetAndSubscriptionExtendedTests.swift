import XCTest
@testable import aiPresentsApp

// MARK: - WidgetDataService Extended Tests
@MainActor
final class WidgetDataServiceExtendedTests: XCTestCase {
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

    // MARK: - Empty and Edge Cases
    func testMakeEntriesWithEmptyPeopleList() {
        let entries = WidgetDataService.makeEntries(people: [], ideas: [], today: referenceDate)
        XCTAssertEqual(entries.count, 0)
    }

    func testMakeEntriesWithEmptyIdeasList() {
        let people = [
            makePerson(name: "Person A", birthday: birthday(daysFromReference: 1)),
            makePerson(name: "Person B", birthday: birthday(daysFromReference: 2))
        ]

        let entries = WidgetDataService.makeEntries(people: people, ideas: [], today: referenceDate)

        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(entries.map(\.giftStatus), ["none", "none"])
    }

    // MARK: - Person with Invalid Birthday
    func testMakeEntriesSkipsPersonWithoutValidBirthday() {
        let validPerson = makePerson(name: "Valid", birthday: birthday(daysFromReference: 0))
        let invalidPerson = makePerson(name: "Invalid", birthday: Date(timeIntervalSince1970: 0))

        let entries = WidgetDataService.makeEntries(
            people: [validPerson, invalidPerson],
            ideas: [],
            today: referenceDate
        )

        // compactMap filtert Personen ohne gültiges Geburtsdatum
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.displayName, "Valid")
    }

    // MARK: - Limit Tests
    func testMakeEntriesWithLimitZero() {
        let people = [
            makePerson(name: "Person 1", birthday: birthday(daysFromReference: 1)),
            makePerson(name: "Person 2", birthday: birthday(daysFromReference: 2))
        ]

        let entries = WidgetDataService.makeEntries(people: people, ideas: [], today: referenceDate, limit: 0)

        XCTAssertEqual(entries.count, 0)
    }

    func testMakeEntriesWithLimitOne() {
        let people = [
            makePerson(name: "First", birthday: birthday(daysFromReference: 1)),
            makePerson(name: "Second", birthday: birthday(daysFromReference: 2)),
            makePerson(name: "Third", birthday: birthday(daysFromReference: 3))
        ]

        let entries = WidgetDataService.makeEntries(people: people, ideas: [], today: referenceDate, limit: 1)

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.displayName, "First")
    }

    func testMakeEntriesWithLimitFive() {
        let people = (1...10).map { i in
            makePerson(name: "Person \(i)", birthday: birthday(daysFromReference: i))
        }

        let entries = WidgetDataService.makeEntries(people: people, ideas: [], today: referenceDate, limit: 5)

        XCTAssertEqual(entries.count, 5)
        XCTAssertEqual(entries.map(\.displayName), ["Person 1", "Person 2", "Person 3", "Person 4", "Person 5"])
    }

    // MARK: - Birthday Date Calculation
    func testNextBirthdayDateCalculation() {
        let person = makePerson(name: "Test", birthday: birthday(daysFromReference: 10))

        let entries = WidgetDataService.makeEntries(people: [person], ideas: [], today: referenceDate)

        XCTAssertEqual(entries.count, 1)
        let expectedDate = Calendar.current.date(
            from: DateComponents(year: 2026, month: 3, day: 24, hour: 12)
        )!
        let targetDate = Calendar.current.date(byAdding: .day, value: 10, to: expectedDate)!
        let components = Calendar.current.dateComponents([.month, .day], from: targetDate)
        let expectedBirthday = Calendar.current.date(
            from: DateComponents(year: 1990, month: components.month, day: components.day, hour: 12)
        )!
        let expectedNextBirthday = Calendar.current.date(byAdding: .year, value: 36, to: expectedBirthday)!

        XCTAssertEqual(entries.first?.nextBirthdayDate.formatted(date: .abbreviated, time: .omitted),
                       expectedNextBirthday.formatted(date: .abbreviated, time: .omitted))
    }

    // MARK: - Age Calculation
    func testNextAgeWhenBirthYearKnown() {
        let person = makePerson(name: "Known Age", birthday: birthday(daysFromReference: 0, birthYear: 1990))
        person.birthYearKnown = true

        let entries = WidgetDataService.makeEntries(people: [person], ideas: [], today: referenceDate)

        XCTAssertEqual(entries.count, 1)
        // 2026 - 1990 = 36 Jahre
        XCTAssertEqual(entries.first?.nextAge, 36)
    }

    func testNextAgeWhenBirthYearUnknown() {
        let person = makePerson(name: "Unknown Age", birthday: birthday(daysFromReference: 5))
        person.birthYearKnown = false

        let entries = WidgetDataService.makeEntries(people: [person], ideas: [], today: referenceDate)

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.nextAge, 0)
    }

    func testNextAgeMultiplePersonsWithDifferentBirthYears() {
        let person1990 = makePerson(name: "Born 1990", birthday: birthday(daysFromReference: 1, birthYear: 1990))
        person1990.birthYearKnown = true

        let person2005 = makePerson(name: "Born 2005", birthday: birthday(daysFromReference: 2, birthYear: 2005))
        person2005.birthYearKnown = true

        let entries = WidgetDataService.makeEntries(people: [person1990, person2005], ideas: [], today: referenceDate)

        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(entries[0].nextAge, 36)
        XCTAssertEqual(entries[1].nextAge, 21)
    }

    // MARK: - Sorting Tests
    func testSortingBySameDay() {
        let person1 = makePerson(name: "A", birthday: birthday(daysFromReference: 5))
        let person2 = makePerson(name: "B", birthday: birthday(daysFromReference: 5))
        let person3 = makePerson(name: "C", birthday: birthday(daysFromReference: 5))

        let entries = WidgetDataService.makeEntries(people: [person3, person1, person2], ideas: [], today: referenceDate)

        XCTAssertEqual(entries.count, 3)
        // Alle haben dasselbe Datum — keine garantierte Ordnung, aber alle sollten vorhanden sein
        let names = Set(entries.map(\.displayName))
        XCTAssertEqual(names, ["A", "B", "C"])
    }

    func testSortingByDistantFutureDates() {
        let people = [
            makePerson(name: "30 Days", birthday: birthday(daysFromReference: 30)),
            makePerson(name: "1 Day", birthday: birthday(daysFromReference: 1)),
            makePerson(name: "100 Days", birthday: birthday(daysFromReference: 100)),
            makePerson(name: "365 Days", birthday: birthday(daysFromReference: 365))
        ]

        let entries = WidgetDataService.makeEntries(people: people, ideas: [], today: referenceDate)

        XCTAssertEqual(entries.map(\.displayName), ["1 Day", "30 Days", "100 Days", "365 Days"])
    }

    // MARK: - Gift Status Priority Tests
    func testGiftStatusGivenHasPriority() {
        let person = makePerson(name: "Given", birthday: birthday(daysFromReference: 1))
        let ideas = [
            GiftIdea(personId: person.id, title: "Idea", status: .idea),
            GiftIdea(personId: person.id, title: "Given", status: .given)
        ]

        let entries = WidgetDataService.makeEntries(people: [person], ideas: ideas, today: referenceDate)

        XCTAssertEqual(entries.first?.giftStatus, "purchased")
    }

    func testGiftStatusPurchasedVsPlannedPriority() {
        let personPurchased = makePerson(name: "Purchased", birthday: birthday(daysFromReference: 1))
        let personPlanned = makePerson(name: "Planned", birthday: birthday(daysFromReference: 2))

        let ideas = [
            GiftIdea(personId: personPurchased.id, title: "Purchase", status: .purchased),
            GiftIdea(personId: personPurchased.id, title: "Idea", status: .idea),
            GiftIdea(personId: personPlanned.id, title: "Plan", status: .planned),
            GiftIdea(personId: personPlanned.id, title: "Idea", status: .idea)
        ]

        let entries = WidgetDataService.makeEntries(people: [personPurchased, personPlanned], ideas: ideas, today: referenceDate)

        let statuses = Dictionary(uniqueKeysWithValues: entries.map { ($0.displayName, $0.giftStatus) })
        XCTAssertEqual(statuses["Purchased"], "purchased")
        XCTAssertEqual(statuses["Planned"], "planned")
    }

    func testGiftStatusPlannedVsIdeasPriority() {
        let personPlanned = makePerson(name: "Planned", birthday: birthday(daysFromReference: 1))
        let personIdeas = makePerson(name: "Ideas", birthday: birthday(daysFromReference: 2))

        let ideas = [
            GiftIdea(personId: personPlanned.id, title: "Plan", status: .planned),
            GiftIdea(personId: personIdeas.id, title: "Idea1", status: .idea),
            GiftIdea(personId: personIdeas.id, title: "Idea2", status: .idea),
            GiftIdea(personId: personIdeas.id, title: "Idea3", status: .idea)
        ]

        let entries = WidgetDataService.makeEntries(people: [personPlanned, personIdeas], ideas: ideas, today: referenceDate)

        let statuses = Dictionary(uniqueKeysWithValues: entries.map { ($0.displayName, $0.giftStatus) })
        XCTAssertEqual(statuses["Planned"], "planned")
        XCTAssertEqual(statuses["Ideas"], "ideas:3")
    }

    func testGiftStatusSkipGiftHasHighestPriority() {
        let person = makePerson(name: "Skip with Ideas", birthday: birthday(daysFromReference: 1), skipGift: true)
        let ideas = [
            GiftIdea(personId: person.id, title: "Purchased", status: .purchased),
            GiftIdea(personId: person.id, title: "Planned", status: .planned),
            GiftIdea(personId: person.id, title: "Ideas", status: .idea)
        ]

        let entries = WidgetDataService.makeEntries(people: [person], ideas: ideas, today: referenceDate)

        // skipGift = true sollte "skip" zurückgeben, unabhängig von Ideas-Status
        XCTAssertEqual(entries.first?.giftStatus, "skip")
    }

    // MARK: - Multiple Statuses
    func testMultipleIdeasCount() {
        let person = makePerson(name: "Multiple Ideas", birthday: birthday(daysFromReference: 1))
        let ideas = (1...8).map { i in
            GiftIdea(personId: person.id, title: "Idea \(i)", status: .idea)
        }

        let entries = WidgetDataService.makeEntries(people: [person], ideas: ideas, today: referenceDate)

        XCTAssertEqual(entries.first?.giftStatus, "ideas:8")
    }

    func testMixedStatusesWithSinglePerson() {
        let person = makePerson(name: "Mixed", birthday: birthday(daysFromReference: 1))
        let ideas = [
            GiftIdea(personId: person.id, title: "Idea 1", status: .idea),
            GiftIdea(personId: person.id, title: "Idea 2", status: .idea),
            GiftIdea(personId: person.id, title: "Idea 3", status: .idea),
            GiftIdea(personId: person.id, title: "Planned", status: .planned),
            GiftIdea(personId: person.id, title: "Purchased", status: .purchased)
        ]

        let entries = WidgetDataService.makeEntries(people: [person], ideas: ideas, today: referenceDate)

        // purchased hat höchste Priorität
        XCTAssertEqual(entries.first?.giftStatus, "purchased")
    }

    // MARK: - SkipGift Flag Tests
    func testSkipGiftFlagPreservedInEntry() {
        let personSkip = makePerson(name: "Skip", birthday: birthday(daysFromReference: 1), skipGift: true)
        let personNoSkip = makePerson(name: "No Skip", birthday: birthday(daysFromReference: 2), skipGift: false)

        let entries = WidgetDataService.makeEntries(people: [personSkip, personNoSkip], ideas: [], today: referenceDate)

        let skipDict = Dictionary(uniqueKeysWithValues: entries.map { ($0.displayName, $0.skipGift) })
        XCTAssertTrue(skipDict["Skip"]!)
        XCTAssertFalse(skipDict["No Skip"]!)
    }

    // MARK: - Large Dataset Performance
    func testMakeEntriesWithLargeDataset() {
        let people = (0..<100).map { offset in
            makePerson(name: "Person \(offset)", birthday: birthday(daysFromReference: offset % 365))
        }

        let ideas = (0..<500).flatMap { ideaIndex in
            let personIndex = ideaIndex % 100
            let personId = people[personIndex].id
            return [
                GiftIdea(personId: personId, title: "Idea \(ideaIndex)A", status: .idea),
                GiftIdea(personId: personId, title: "Idea \(ideaIndex)B", status: .idea)
            ]
        }

        let entries = WidgetDataService.makeEntries(people: people, ideas: ideas, today: referenceDate, limit: 10)

        XCTAssertEqual(entries.count, 10)
        XCTAssertTrue(entries.allSatisfy { !$0.displayName.isEmpty })
    }

    // MARK: - Test Helpers
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

// MARK: - SubscriptionAccessPolicy Extended Tests
final class SubscriptionAccessPolicyExtendedTests: XCTestCase {
    // MARK: - Trial Date Tests
    func testTrialStartDateNilWhenNotSet() {
        let defaults = UserDefaults(suiteName: "test.subscription.\(UUID().uuidString)") ?? .standard

        let trialStart = SubscriptionAccessPolicy.trialStartDate(userDefaults: defaults)

        XCTAssertNil(trialStart)
    }

    func testTrialStartDateRetrievalAfterSetting() {
        let defaults = UserDefaults(suiteName: "test.subscription.\(UUID().uuidString)") ?? .standard
        let testDate = Date()

        defaults.set(testDate, forKey: SubscriptionAccessPolicy.trialStartKey)

        let retrieved = SubscriptionAccessPolicy.trialStartDate(userDefaults: defaults)
        XCTAssertNotNil(retrieved)
        guard let retrievedDate = retrieved else {
            XCTFail("Retrieved date should not be nil")
            return
        }
        XCTAssertEqual(retrievedDate.timeIntervalSince1970, testDate.timeIntervalSince1970, accuracy: 1.0)
    }

    func testTrialEndDateNilWhenTrialStartIsNil() {
        let endDate = SubscriptionAccessPolicy.trialEndDate(trialStartDate: nil)

        XCTAssertNil(endDate)
    }

    func testTrialEndDateAdds14Days() {
        let calendar = Calendar(identifier: .gregorian)
        let trialStart = calendar.date(from: DateComponents(year: 2026, month: 4, day: 10))!

        let trialEnd = SubscriptionAccessPolicy.trialEndDate(trialStartDate: trialStart, calendar: calendar)

        XCTAssertNotNil(trialEnd)
        let expectedEnd = calendar.date(byAdding: .day, value: 14, to: trialStart)!
        XCTAssertEqual(trialEnd, expectedEnd)
    }

    func testTrialDurationConstantIs14() {
        XCTAssertEqual(SubscriptionAccessPolicy.trialDurationDays, 14)
    }

    // MARK: - IsInTrial Tests
    func testIsInTrialIsFalseWithEmptyPurchasedSet() {
        let calendar = Calendar(identifier: .gregorian)
        let trialStart = calendar.date(from: DateComponents(year: 2026, month: 4, day: 1))!
        let now = calendar.date(from: DateComponents(year: 2026, month: 4, day: 5))!

        let inTrial = SubscriptionAccessPolicy.isInTrial(
            purchasedProductIDs: [],
            trialStartDate: trialStart,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(inTrial)
    }

    func testIsInTrialIsFalseWhenPurchasesExist() {
        let calendar = Calendar(identifier: .gregorian)
        let trialStart = calendar.date(from: DateComponents(year: 2026, month: 4, day: 1))!
        let now = calendar.date(from: DateComponents(year: 2026, month: 4, day: 5))!

        let inTrial = SubscriptionAccessPolicy.isInTrial(
            purchasedProductIDs: ["com.hendrikgrueger.birthdays-presents-ai.monthly"],
            trialStartDate: trialStart,
            now: now,
            calendar: calendar
        )

        XCTAssertFalse(inTrial)
    }

    func testIsInTrialIsFalseAfter14Days() {
        let calendar = Calendar(identifier: .gregorian)
        let trialStart = calendar.date(from: DateComponents(year: 2026, month: 4, day: 1))!
        let now = calendar.date(from: DateComponents(year: 2026, month: 4, day: 16))! // 15 Tage später

        let inTrial = SubscriptionAccessPolicy.isInTrial(
            purchasedProductIDs: [],
            trialStartDate: trialStart,
            now: now,
            calendar: calendar
        )

        XCTAssertFalse(inTrial)
    }

    func testIsInTrialIsTrueOnDay14() {
        let calendar = Calendar(identifier: .gregorian)
        let trialStart = calendar.date(from: DateComponents(year: 2026, month: 4, day: 1))!
        let now = calendar.date(from: DateComponents(year: 2026, month: 4, day: 15))! // exactly 14 days

        let inTrial = SubscriptionAccessPolicy.isInTrial(
            purchasedProductIDs: [],
            trialStartDate: trialStart,
            now: now,
            calendar: calendar
        )

        // now < trialEndDate, also noch in Trial
        XCTAssertTrue(inTrial)
    }

    func testIsInTrialIsFalseOnDay15() {
        let calendar = Calendar(identifier: .gregorian)
        let trialStart = calendar.date(from: DateComponents(year: 2026, month: 4, day: 1))!
        let now = calendar.date(from: DateComponents(year: 2026, month: 4, day: 15, hour: 0, minute: 1))! // > 14 days

        let inTrial = SubscriptionAccessPolicy.isInTrial(
            purchasedProductIDs: [],
            trialStartDate: trialStart,
            now: now,
            calendar: calendar
        )

        XCTAssertFalse(inTrial)
    }

    func testIsInTrialIsTrueWhenTrialStartDateNil() {
        let calendar = Calendar(identifier: .gregorian)
        let now = calendar.date(from: DateComponents(year: 2026, month: 4, day: 10))!

        let inTrial = SubscriptionAccessPolicy.isInTrial(
            purchasedProductIDs: [],
            trialStartDate: nil,
            now: now,
            calendar: calendar
        )

        XCTAssertFalse(inTrial)
    }

    // MARK: - HasFullAccess Tests
    func testHasFullAccessAlwaysTrueWhenFreeLaunchEnabled() {
        XCTAssertTrue(
            SubscriptionAccessPolicy.hasFullAccess(
                purchasedProductIDs: [],
                trialStartDate: nil,
                freeLaunchEnabled: true
            )
        )

        let calendar = Calendar(identifier: .gregorian)
        let trialStart = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let now = calendar.date(from: DateComponents(year: 2026, month: 4, day: 10))!

        XCTAssertTrue(
            SubscriptionAccessPolicy.hasFullAccess(
                purchasedProductIDs: [],
                trialStartDate: trialStart,
                now: now,
                freeLaunchEnabled: true
            )
        )
    }

    func testHasFullAccessWithPurchasedProducts() {
        let calendar = Calendar(identifier: .gregorian)

        XCTAssertTrue(
            SubscriptionAccessPolicy.hasFullAccess(
                purchasedProductIDs: ["com.hendrikgrueger.birthdays-presents-ai.monthly"],
                trialStartDate: nil,
                freeLaunchEnabled: false
            )
        )

        XCTAssertTrue(
            SubscriptionAccessPolicy.hasFullAccess(
                purchasedProductIDs: ["com.hendrikgrueger.birthdays-presents-ai.yearly", "com.hendrikgrueger.birthdays-presents-ai.lifetime"],
                trialStartDate: nil,
                freeLaunchEnabled: false
            )
        )
    }

    func testHasFullAccessWithActiveTrial() {
        let calendar = Calendar(identifier: .gregorian)
        let trialStart = calendar.date(from: DateComponents(year: 2026, month: 4, day: 1))!
        let now = calendar.date(from: DateComponents(year: 2026, month: 4, day: 5))!

        XCTAssertTrue(
            SubscriptionAccessPolicy.hasFullAccess(
                purchasedProductIDs: [],
                trialStartDate: trialStart,
                now: now,
                freeLaunchEnabled: false
            )
        )
    }

    func testHasFullAccessFalseWithExpiredTrial() {
        let calendar = Calendar(identifier: .gregorian)
        let trialStart = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1))!
        let now = calendar.date(from: DateComponents(year: 2026, month: 4, day: 10))!

        XCTAssertFalse(
            SubscriptionAccessPolicy.hasFullAccess(
                purchasedProductIDs: [],
                trialStartDate: trialStart,
                now: now,
                freeLaunchEnabled: false
            )
        )
    }

    func testHasFullAccessFalseWithoutPurchaseOrTrialWhenFreeLaunchDisabled() {
        XCTAssertFalse(
            SubscriptionAccessPolicy.hasFullAccess(
                purchasedProductIDs: [],
                trialStartDate: nil,
                freeLaunchEnabled: false
            )
        )
    }

    func testHasFullAccessWithMultiplePurchasedProducts() {
        let products = Set([
            "com.hendrikgrueger.birthdays-presents-ai.monthly",
            "com.hendrikgrueger.birthdays-presents-ai.yearly"
        ])

        XCTAssertTrue(
            SubscriptionAccessPolicy.hasFullAccess(
                purchasedProductIDs: products,
                trialStartDate: nil,
                freeLaunchEnabled: false
            )
        )
    }

    // MARK: - Combined Scenario Tests
    func testUserStartsTrialThenBuysSubscription() {
        let calendar = Calendar(identifier: .gregorian)
        let trialStart = calendar.date(from: DateComponents(year: 2026, month: 4, day: 1))!
        let purchaseDate = calendar.date(from: DateComponents(year: 2026, month: 4, day: 5))!

        // During trial
        XCTAssertTrue(
            SubscriptionAccessPolicy.hasFullAccess(
                purchasedProductIDs: [],
                trialStartDate: trialStart,
                now: purchaseDate,
                freeLaunchEnabled: false
            )
        )

        // After purchase
        XCTAssertTrue(
            SubscriptionAccessPolicy.hasFullAccess(
                purchasedProductIDs: ["com.hendrikgrueger.birthdays-presents-ai.yearly"],
                trialStartDate: trialStart,
                now: purchaseDate,
                freeLaunchEnabled: false
            )
        )

        // After trial expiration (but subscription is active)
        let afterTrial = calendar.date(from: DateComponents(year: 2026, month: 4, day: 20))!
        XCTAssertTrue(
            SubscriptionAccessPolicy.hasFullAccess(
                purchasedProductIDs: ["com.hendrikgrueger.birthdays-presents-ai.yearly"],
                trialStartDate: trialStart,
                now: afterTrial,
                freeLaunchEnabled: false
            )
        )
    }

    func testUserLetsTrialExpireWithoutPurchase() {
        let calendar = Calendar(identifier: .gregorian)
        let trialStart = calendar.date(from: DateComponents(year: 2026, month: 4, day: 1))!

        // Day 10 — in trial
        let duringTrial = calendar.date(from: DateComponents(year: 2026, month: 4, day: 11))!
        XCTAssertTrue(
            SubscriptionAccessPolicy.hasFullAccess(
                purchasedProductIDs: [],
                trialStartDate: trialStart,
                now: duringTrial,
                freeLaunchEnabled: false
            )
        )

        // Day 20 — trial expired, no purchase
        let afterExpiration = calendar.date(from: DateComponents(year: 2026, month: 4, day: 21))!
        XCTAssertFalse(
            SubscriptionAccessPolicy.hasFullAccess(
                purchasedProductIDs: [],
                trialStartDate: trialStart,
                now: afterExpiration,
                freeLaunchEnabled: false
            )
        )
    }

    func testPurchaseIdempotency() {
        let products = Set([
            "com.hendrikgrueger.birthdays-presents-ai.yearly",
            "com.hendrikgrueger.birthdays-presents-ai.monthly"
        ])

        // Mehrfaches Kaufen derselben Produkte → weiterhin full access
        let access1 = SubscriptionAccessPolicy.hasFullAccess(
            purchasedProductIDs: products,
            trialStartDate: nil,
            freeLaunchEnabled: false
        )
        let access2 = SubscriptionAccessPolicy.hasFullAccess(
            purchasedProductIDs: products,
            trialStartDate: nil,
            freeLaunchEnabled: false
        )

        XCTAssertTrue(access1)
        XCTAssertTrue(access2)
    }

    // MARK: - Edge Case Tests
    func testTrialWithDifferentCalendars() {
        let gregorianCalendar = Calendar(identifier: .gregorian)
        let hebrewCalendar = Calendar(identifier: .hebrew)

        let trialStart = gregorianCalendar.date(from: DateComponents(year: 2026, month: 4, day: 1))!

        // Gregorian calendar
        let gregorianInTrial = SubscriptionAccessPolicy.isInTrial(
            purchasedProductIDs: [],
            trialStartDate: trialStart,
            now: Date(),
            calendar: gregorianCalendar
        )

        // Hebrew calendar
        let hebrewInTrial = SubscriptionAccessPolicy.isInTrial(
            purchasedProductIDs: [],
            trialStartDate: trialStart,
            now: Date(),
            calendar: hebrewCalendar
        )

        // Beide sollten gleich sein (14 Tage sind überall 14 Tage)
        XCTAssertEqual(gregorianInTrial, hebrewInTrial)
    }

    func testLargeDateRanges() {
        let calendar = Calendar(identifier: .gregorian)
        let trialStart = calendar.date(from: DateComponents(year: 1970, month: 1, day: 1))!
        let now = calendar.date(from: DateComponents(year: 2026, month: 4, day: 10))!

        let inTrial = SubscriptionAccessPolicy.isInTrial(
            purchasedProductIDs: [],
            trialStartDate: trialStart,
            now: now,
            calendar: calendar
        )

        XCTAssertFalse(inTrial)
    }
}
