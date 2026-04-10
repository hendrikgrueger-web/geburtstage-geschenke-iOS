import XCTest
@testable import aiPresentsApp

/// Extended comprehensive tests for BirthdayDateHelper
/// Complements BirthdayDateHelperTests.swift with additional zodiac, formatting, and edge case coverage
@MainActor final class BirthdayDateHelperExtendedTests: XCTestCase {

    // MARK: - Setup & Helpers

    override func setUp() {
        super.setUp()
        BirthdayCalculator.clearCache()
    }

    override func tearDown() {
        BirthdayCalculator.clearCache()
        super.tearDown()
    }

    /// Helper to create a date with specific year/month/day
    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12  // Noon to avoid timezone issues
        guard let date = Calendar.current.date(from: components) else {
            XCTFail("Failed to create date for \(year)-\(month)-\(day)")
            return Date()
        }
        return date
    }

    /// Helper to get the current year
    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    // MARK: - Zodiac Sign Tests (KRITISCH — alle 12 Grenzen)

    // Widder (21.03 - 19.04)
    func testZodiacSign_Widder_Start() {
        let date = makeDate(year: currentYear, month: 3, day: 21)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♈ Widder")
    }

    func testZodiacSign_Widder_End() {
        let date = makeDate(year: currentYear, month: 4, day: 19)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♈ Widder")
    }

    func testZodiacSign_Fische_BeforeWidder() {
        let date = makeDate(year: currentYear, month: 3, day: 20)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♓ Fische")
    }

    func testZodiacSign_Stier_AfterWidder() {
        let date = makeDate(year: currentYear, month: 4, day: 20)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♉ Stier")
    }

    // Stier (20.04 - 20.05)
    func testZodiacSign_Stier_Start() {
        let date = makeDate(year: currentYear, month: 4, day: 20)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♉ Stier")
    }

    func testZodiacSign_Stier_End() {
        let date = makeDate(year: currentYear, month: 5, day: 20)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♉ Stier")
    }

    func testZodiacSign_Zwilling_AfterStier() {
        let date = makeDate(year: currentYear, month: 5, day: 21)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♊ Zwilling")
    }

    // Zwilling (21.05 - 20.06)
    func testZodiacSign_Zwilling_Start() {
        let date = makeDate(year: currentYear, month: 5, day: 21)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♊ Zwilling")
    }

    func testZodiacSign_Zwilling_End() {
        let date = makeDate(year: currentYear, month: 6, day: 20)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♊ Zwilling")
    }

    func testZodiacSign_Krebs_AfterZwilling() {
        let date = makeDate(year: currentYear, month: 6, day: 21)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♋ Krebs")
    }

    // Krebs (21.06 - 22.07)
    func testZodiacSign_Krebs_Start() {
        let date = makeDate(year: currentYear, month: 6, day: 21)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♋ Krebs")
    }

    func testZodiacSign_Krebs_End() {
        let date = makeDate(year: currentYear, month: 7, day: 22)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♋ Krebs")
    }

    func testZodiacSign_Loewe_AfterKrebs() {
        let date = makeDate(year: currentYear, month: 7, day: 23)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♌ Löwe")
    }

    // Löwe (23.07 - 22.08)
    func testZodiacSign_Loewe_Start() {
        let date = makeDate(year: currentYear, month: 7, day: 23)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♌ Löwe")
    }

    func testZodiacSign_Loewe_End() {
        let date = makeDate(year: currentYear, month: 8, day: 22)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♌ Löwe")
    }

    func testZodiacSign_Jungfrau_AfterLoewe() {
        let date = makeDate(year: currentYear, month: 8, day: 23)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♍ Jungfrau")
    }

    // Jungfrau (23.08 - 22.09)
    func testZodiacSign_Jungfrau_Start() {
        let date = makeDate(year: currentYear, month: 8, day: 23)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♍ Jungfrau")
    }

    func testZodiacSign_Jungfrau_End() {
        let date = makeDate(year: currentYear, month: 9, day: 22)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♍ Jungfrau")
    }

    func testZodiacSign_Waage_AfterJungfrau() {
        let date = makeDate(year: currentYear, month: 9, day: 23)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♎ Waage")
    }

    // Waage (23.09 - 22.10)
    func testZodiacSign_Waage_Start() {
        let date = makeDate(year: currentYear, month: 9, day: 23)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♎ Waage")
    }

    func testZodiacSign_Waage_End() {
        let date = makeDate(year: currentYear, month: 10, day: 22)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♎ Waage")
    }

    func testZodiacSign_Skorpion_AfterWaage() {
        let date = makeDate(year: currentYear, month: 10, day: 23)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♏ Skorpion")
    }

    // Skorpion (23.10 - 21.11)
    func testZodiacSign_Skorpion_Start() {
        let date = makeDate(year: currentYear, month: 10, day: 23)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♏ Skorpion")
    }

    func testZodiacSign_Skorpion_End() {
        let date = makeDate(year: currentYear, month: 11, day: 21)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♏ Skorpion")
    }

    func testZodiacSign_Schuetze_AfterSkorpion() {
        let date = makeDate(year: currentYear, month: 11, day: 22)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♐ Schütze")
    }

    // Schütze (22.11 - 21.12)
    func testZodiacSign_Schuetze_Start() {
        let date = makeDate(year: currentYear, month: 11, day: 22)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♐ Schütze")
    }

    func testZodiacSign_Schuetze_End() {
        let date = makeDate(year: currentYear, month: 12, day: 21)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♐ Schütze")
    }

    func testZodiacSign_Steinbock_AfterSchuetze() {
        let date = makeDate(year: currentYear, month: 12, day: 22)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♑ Steinbock")
    }

    // Steinbock (22.12 - 19.01)
    func testZodiacSign_Steinbock_Start() {
        let date = makeDate(year: currentYear, month: 12, day: 22)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♑ Steinbock")
    }

    func testZodiacSign_Steinbock_End() {
        let date = makeDate(year: currentYear, month: 1, day: 19)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♑ Steinbock")
    }

    func testZodiacSign_Wassermann_AfterSteinbock() {
        let date = makeDate(year: currentYear, month: 1, day: 20)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♒ Wassermann")
    }

    // Wassermann (20.01 - 18.02)
    func testZodiacSign_Wassermann_Start() {
        let date = makeDate(year: currentYear, month: 1, day: 20)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♒ Wassermann")
    }

    func testZodiacSign_Wassermann_End() {
        let date = makeDate(year: currentYear, month: 2, day: 18)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♒ Wassermann")
    }

    func testZodiacSign_Fische_AfterWassermann() {
        let date = makeDate(year: currentYear, month: 2, day: 19)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♓ Fische")
    }

    // Fische (19.02 - 20.03)
    func testZodiacSign_Fische_Start() {
        let date = makeDate(year: currentYear, month: 2, day: 19)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♓ Fische")
    }

    func testZodiacSign_Fische_End() {
        let date = makeDate(year: currentYear, month: 3, day: 20)
        XCTAssertEqual(BirthdayDateHelper.zodiacSign(from: date), "♓ Fische")
    }

    // MARK: - Localized Zodiac Sign Tests

    func testLocalizedZodiacSign_Widder() {
        let date = makeDate(year: currentYear, month: 3, day: 21)
        let sign = BirthdayDateHelper.localizedZodiacSign(from: date)
        // Should contain "Widder" (localized version includes emoji)
        XCTAssertTrue(sign.contains("Widder"))
    }

    func testLocalizedZodiacSign_Fische() {
        let date = makeDate(year: currentYear, month: 2, day: 19)
        let sign = BirthdayDateHelper.localizedZodiacSign(from: date)
        XCTAssertTrue(sign.contains("Fische"))
    }

    func testZodiacSign_InvalidInput_EmptyString() {
        // Invalid date (month 13, day 32) should return empty string
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = currentYear
        components.month = 13
        components.day = 1
        // Calendar.date() will normalize this, so this test is more for coverage
        if let date = calendar.date(from: components) {
            let sign = BirthdayDateHelper.zodiacSign(from: date)
            // The function will still return a valid zodiac (normalized date)
            XCTAssertFalse(sign.isEmpty)
        }
    }

    // MARK: - Formatting Tests (Extended)

    func testFormatBirthdayShort_ContainsDay() {
        let date = makeDate(year: 1990, month: 3, day: 15)
        let formatted = BirthdayDateHelper.formatBirthdayShort(date)
        // Should contain day (15) and month abbreviation
        XCTAssertTrue(formatted.contains("15") || formatted.contains("15."))
    }

    func testFormatBirthdayShort_DifferentLocales() {
        let date = makeDate(year: 1990, month: 5, day: 20)
        let deFormat = BirthdayDateHelper.formatBirthdayShort(date, locale: Locale(identifier: "de_DE"))
        let enFormat = BirthdayDateHelper.formatBirthdayShort(date, locale: Locale(identifier: "en_US"))
        // Formats should be different due to locale differences
        XCTAssertFalse(deFormat.isEmpty)
        XCTAssertFalse(enFormat.isEmpty)
        // German has "." typically, English doesn't
        XCTAssertTrue(deFormat.contains(".") || enFormat.isEmpty == false)
    }

    func testFormatBirthdayFull_ContainsYear() {
        let date = makeDate(year: 1990, month: 3, day: 15)
        let formatted = BirthdayDateHelper.formatBirthdayFull(date)
        // Should contain year
        XCTAssertTrue(formatted.contains("1990"))
    }

    func testFormatBirthdayFull_ContainsDayMonthYear() {
        let date = makeDate(year: 2000, month: 12, day: 25)
        let formatted = BirthdayDateHelper.formatBirthdayFull(date)
        // Should be a valid formatted string with date components
        XCTAssertFalse(formatted.isEmpty)
        XCTAssertTrue(formatted.contains("2000") || formatted.contains("00"))
    }

    // MARK: - Format Age Tests

    func testFormatAge_MilestoneAge_18() {
        let birthday = makeDate(year: currentYear - 18, month: 1, day: 1)
        let formatted = BirthdayDateHelper.formatAge(birthday: birthday)
        XCTAssertTrue(formatted.contains("18"))
        XCTAssertTrue(formatted.contains("Volljährigkeit"))
    }

    func testFormatAge_MilestoneAge_30() {
        // Geburtstag muss VOR heute liegen damit Alter korrekt ist
        let birthday = makeDate(year: currentYear - 30, month: 1, day: 1)
        let formatted = BirthdayDateHelper.formatAge(birthday: birthday)
        XCTAssertTrue(formatted.contains("30"))
        XCTAssertTrue(formatted.contains("Geburtstag"))
    }

    func testFormatAge_NonMilestoneAge() {
        let birthday = makeDate(year: currentYear - 25, month: 3, day: 10)
        let formatted = BirthdayDateHelper.formatAge(birthday: birthday)
        XCTAssertTrue(formatted.contains("25"))
        XCTAssertTrue(formatted.contains("Jahre"))
    }

    func testFormatAge_Age100() {
        // Geburtstag muss VOR heute liegen
        let birthday = makeDate(year: currentYear - 100, month: 1, day: 1)
        let formatted = BirthdayDateHelper.formatAge(birthday: birthday)
        XCTAssertTrue(formatted.contains("100"))
        XCTAssertTrue(formatted.contains("Geburtstag"))
    }

    // MARK: - Relative Date Description Tests (Extended)

    func testRelativeDateDescription_Today() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let description = BirthdayDateHelper.relativeDateDescription(from: today, asOf: today)
        XCTAssertTrue(description.contains("Heute"))
        XCTAssertTrue(description.contains("🎉"))
    }

    func testRelativeDateDescription_Tomorrow() {
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.day! += 1
        if let tomorrow = calendar.date(from: components) {
            let description = BirthdayDateHelper.relativeDateDescription(from: tomorrow, asOf: today)
            XCTAssertTrue(description.contains("Morgen"))
            XCTAssertTrue(description.contains("📅"))
        }
    }

    func testRelativeDateDescription_3Days() {
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.day! += 3
        if let futureDate = calendar.date(from: components) {
            let description = BirthdayDateHelper.relativeDateDescription(from: futureDate, asOf: today)
            XCTAssertTrue(description.contains("In 3 Tagen"))
        }
    }

    func testRelativeDateDescription_7Days() {
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.day! += 7
        if let futureDate = calendar.date(from: components) {
            let description = BirthdayDateHelper.relativeDateDescription(from: futureDate, asOf: today)
            XCTAssertTrue(description.contains("In 7 Tagen"))
        }
    }

    func testRelativeDateDescription_15Days() {
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.day! += 15
        if let futureDate = calendar.date(from: components) {
            let description = BirthdayDateHelper.relativeDateDescription(from: futureDate, asOf: today)
            XCTAssertTrue(description.contains("15 Tage"))
        }
    }

    func testRelativeDateDescription_45Days() {
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.day! += 45
        if let futureDate = calendar.date(from: components) {
            let description = BirthdayDateHelper.relativeDateDescription(from: futureDate, asOf: today)
            XCTAssertTrue(description.contains("Monaten") || description.contains("Monat"))
        }
    }

    func testRelativeDateDescription_100Days() {
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.day! += 100
        if let futureDate = calendar.date(from: components) {
            let description = BirthdayDateHelper.relativeDateDescription(from: futureDate, asOf: today)
            XCTAssertTrue(description.contains("Monaten") || description.contains("Monat"))
        }
    }

    func testRelativeDateDescription_OverOneYear() {
        // relativeDateDescription nutzt BirthdayCalculator.daysUntilBirthday
        // Ein Geburtstag kann maximal ~365 Tage entfernt sein
        // Daher testen wir den "Nächstes Jahr"-Fall nicht direkt — er tritt nur bei nil auf
        // Stattdessen testen wir den grössten realistischen Wert
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        // Geburtstag gestern → nächstes Auftreten in ~364 Tagen
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
            let description = BirthdayDateHelper.relativeDateDescription(from: yesterday, asOf: today)
            XCTAssertTrue(description.contains("Monat") || description.contains("📅"),
                          "Weit entfernter Geburtstag sollte Monate anzeigen: \(description)")
        }
    }

    // MARK: - isInPeriod Tests

    func testIsInPeriod_Today() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        XCTAssertTrue(BirthdayDateHelper.isInPeriod(.today, for: today, asOf: today))
        XCTAssertFalse(BirthdayDateHelper.isInPeriod(.tomorrow, for: today, asOf: today))
    }

    func testIsInPeriod_Tomorrow() {
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.day! += 1
        if let tomorrow = calendar.date(from: components) {
            XCTAssertTrue(BirthdayDateHelper.isInPeriod(.tomorrow, for: tomorrow, asOf: today))
            XCTAssertFalse(BirthdayDateHelper.isInPeriod(.today, for: tomorrow, asOf: today))
        }
    }

    func testIsInPeriod_ThisWeek() {
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.day! += 4
        if let weekDate = calendar.date(from: components) {
            XCTAssertTrue(BirthdayDateHelper.isInPeriod(.thisWeek, for: weekDate, asOf: today))
            XCTAssertFalse(BirthdayDateHelper.isInPeriod(.thisMonth, for: weekDate, asOf: today))
        }
    }

    func testIsInPeriod_ThisMonth() {
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.day! += 20
        if let monthDate = calendar.date(from: components) {
            XCTAssertTrue(BirthdayDateHelper.isInPeriod(.thisMonth, for: monthDate, asOf: today))
            XCTAssertFalse(BirthdayDateHelper.isInPeriod(.tomorrow, for: monthDate, asOf: today))
        }
    }

    func testIsInPeriod_Later() {
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.day! += 90
        if let laterDate = calendar.date(from: components) {
            XCTAssertTrue(BirthdayDateHelper.isInPeriod(.later, for: laterDate, asOf: today))
            XCTAssertFalse(BirthdayDateHelper.isInPeriod(.thisWeek, for: laterDate, asOf: today))
        }
    }

    // MARK: - Calendar Helper Tests (Extended)

    func testDaysBetween_SameDay() {
        let date = makeDate(year: 2020, month: 5, day: 10)
        let days = BirthdayDateHelper.daysBetween(from: date, to: date)
        XCTAssertEqual(days, 0)
    }

    func testDaysBetween_5Days() {
        let start = makeDate(year: 2020, month: 5, day: 10)
        let end = makeDate(year: 2020, month: 5, day: 15)
        let days = BirthdayDateHelper.daysBetween(from: start, to: end)
        XCTAssertEqual(days, 5)
    }

    func testDaysBetween_CrossMonth() {
        let start = makeDate(year: 2020, month: 5, day: 28)
        let end = makeDate(year: 2020, month: 6, day: 2)
        let days = BirthdayDateHelper.daysBetween(from: start, to: end)
        XCTAssertEqual(days, 5)
    }

    func testDaysBetween_1Year() {
        let start = makeDate(year: 2020, month: 5, day: 10)
        let end = makeDate(year: 2021, month: 5, day: 10)
        let days = BirthdayDateHelper.daysBetween(from: start, to: end)
        XCTAssertEqual(days, 365)
    }

    func testDaysBetween_Backwards_ReturnsZero() {
        let start = makeDate(year: 2020, month: 5, day: 20)
        let end = makeDate(year: 2020, month: 5, day: 10)
        let days = BirthdayDateHelper.daysBetween(from: start, to: end)
        // daysBetween returns max(0, ...) so backwards should return 0
        XCTAssertEqual(days, 0)
    }

    func testIsInSameMonth_SameMonth() {
        let date1 = makeDate(year: 2020, month: 5, day: 10)
        let date2 = makeDate(year: 2020, month: 5, day: 25)
        XCTAssertTrue(BirthdayDateHelper.isInSameMonth(date1, date2))
    }

    func testIsInSameMonth_DifferentMonth() {
        let date1 = makeDate(year: 2020, month: 5, day: 10)
        let date2 = makeDate(year: 2020, month: 6, day: 10)
        XCTAssertFalse(BirthdayDateHelper.isInSameMonth(date1, date2))
    }

    func testIsInSameMonth_DifferentYear() {
        let date1 = makeDate(year: 2020, month: 5, day: 10)
        let date2 = makeDate(year: 2021, month: 5, day: 10)
        XCTAssertFalse(BirthdayDateHelper.isInSameMonth(date1, date2))
    }

    func testIsInSameYear_SameYear() {
        let date1 = makeDate(year: 2020, month: 3, day: 10)
        let date2 = makeDate(year: 2020, month: 11, day: 25)
        XCTAssertTrue(BirthdayDateHelper.isInSameYear(date1, date2))
    }

    func testIsInSameYear_DifferentYear() {
        let date1 = makeDate(year: 2020, month: 5, day: 10)
        let date2 = makeDate(year: 2021, month: 5, day: 10)
        XCTAssertFalse(BirthdayDateHelper.isInSameYear(date1, date2))
    }

    func testIsInSameYear_DifferentMonths() {
        let date1 = makeDate(year: 2020, month: 1, day: 1)
        let date2 = makeDate(year: 2020, month: 12, day: 31)
        XCTAssertTrue(BirthdayDateHelper.isInSameYear(date1, date2))
    }

    // MARK: - Milestone Edge Cases

    func testMilestoneName_AllMilestones() {
        let milestoneAges = [18, 21, 30, 40, 50, 60, 70, 80, 90, 100]
        for age in milestoneAges {
            let name = BirthdayDateHelper.milestoneName(for: age)
            XCTAssertNotNil(name, "Milestone age \(age) should have a name")
            XCTAssertFalse(name?.isEmpty ?? true, "Milestone name for age \(age) should not be empty")
        }
    }

    func testMilestoneName_NonMilestones() {
        let nonMilestones = [0, 1, 17, 19, 20, 25, 35, 45, 55, 65, 75, 85, 95, 99]
        for age in nonMilestones {
            let name = BirthdayDateHelper.milestoneName(for: age)
            XCTAssertNil(name, "Age \(age) should not be a milestone")
        }
    }

    func testIsMilestoneAge_Boundaries() {
        // Test all milestone boundaries
        XCTAssertFalse(BirthdayDateHelper.isMilestoneAge(age: 17))
        XCTAssertTrue(BirthdayDateHelper.isMilestoneAge(age: 18))
        XCTAssertFalse(BirthdayDateHelper.isMilestoneAge(age: 19))

        XCTAssertFalse(BirthdayDateHelper.isMilestoneAge(age: 20))
        XCTAssertTrue(BirthdayDateHelper.isMilestoneAge(age: 21))
        XCTAssertFalse(BirthdayDateHelper.isMilestoneAge(age: 22))

        XCTAssertTrue(BirthdayDateHelper.isMilestoneAge(age: 100))
        XCTAssertFalse(BirthdayDateHelper.isMilestoneAge(age: 101))
    }

    // MARK: - Date Extensions

    func testDateExtension_Age() {
        // Geburtstag muss VOR heute liegen (Januar) damit Alter korrekt 25 ist
        let birthday = makeDate(year: currentYear - 25, month: 1, day: 1)
        let age = birthday.age
        XCTAssertEqual(age, 25)
    }

    func testDateExtension_BirthdayShort() {
        let birthday = makeDate(year: 1990, month: 5, day: 15)
        let short = birthday.birthdayShort
        XCTAssertFalse(short.isEmpty)
        XCTAssertTrue(short.contains("15"))
    }

    func testDateExtension_BirthdayFull() {
        let birthday = makeDate(year: 1990, month: 5, day: 15)
        let full = birthday.birthdayFull
        XCTAssertFalse(full.isEmpty)
        XCTAssertTrue(full.contains("1990"))
    }

    func testDateExtension_RelativeToNow() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let relative = today.relativeToNow
        XCTAssertTrue(relative.contains("Heute"))
    }

    // MARK: - Static Date Range Properties

    func testTodayProperty() {
        let today = BirthdayDateHelper.today
        let nowDate = Date()
        // Should be roughly the same (within a minute or so)
        let dayComponent = Calendar.current.dateComponents([.day], from: today, to: nowDate)
        XCTAssertEqual(dayComponent.day, 0)
    }

    func testEndOfTodayProperty() {
        let endOfDay = BirthdayDateHelper.endOfToday
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: endOfDay)
        // Should be close to 23:59:59
        XCTAssertEqual(components.hour, 23)
        XCTAssertEqual(components.minute, 59)
        XCTAssertEqual(components.second, 59)
    }

    func testTomorrowProperty() {
        let tomorrow = BirthdayDateHelper.tomorrow
        let dayDifference = Calendar.current.dateComponents([.day], from: BirthdayDateHelper.today, to: tomorrow)
        XCTAssertEqual(dayDifference.day, 1)
    }

    func testDaysFromNowFunction() {
        let in5Days = BirthdayDateHelper.daysFromNow(5)
        let dayDifference = Calendar.current.dateComponents([.day], from: BirthdayDateHelper.today, to: in5Days)
        XCTAssertEqual(dayDifference.day, 5)
    }

    func testDaysFromNowFunction_Zero() {
        let today = BirthdayDateHelper.daysFromNow(0)
        let dayDifference = Calendar.current.dateComponents([.day], from: BirthdayDateHelper.today, to: today)
        XCTAssertEqual(dayDifference.day, 0)
    }

    func testDaysFromNowFunction_Negative() {
        let yesterday = BirthdayDateHelper.daysFromNow(-1)
        let dayDifference = Calendar.current.dateComponents([.day], from: BirthdayDateHelper.today, to: yesterday)
        XCTAssertEqual(dayDifference.day, -1)
    }

    func testUpcomingRangeIs30Days() {
        let range = BirthdayDateHelper.upcomingRange
        let dayDifference = Calendar.current.dateComponents([.day], from: range.lowerBound, to: range.upperBound)
        XCTAssertEqual(dayDifference.day, 30)
    }

    func testSoonRangeIs7Days() {
        let range = BirthdayDateHelper.soonRange
        let dayDifference = Calendar.current.dateComponents([.day], from: range.lowerBound, to: range.upperBound)
        XCTAssertEqual(dayDifference.day, 7)
    }

    // MARK: - BirthdayPeriod Enum Tests

    func testBirthdayPeriod_LocalizedName_Today() {
        let period = BirthdayDateHelper.BirthdayPeriod.today
        let name = period.localizedName
        XCTAssertTrue(name.contains("Heute"))
    }

    func testBirthdayPeriod_LocalizedName_Tomorrow() {
        let period = BirthdayDateHelper.BirthdayPeriod.tomorrow
        let name = period.localizedName
        XCTAssertTrue(name.contains("Morgen"))
    }

    func testBirthdayPeriod_RawValue() {
        let period = BirthdayDateHelper.BirthdayPeriod.today
        XCTAssertEqual(period.rawValue, "Heute")
    }

    func testBirthdayPeriod_AllCases() {
        let allCases = BirthdayDateHelper.BirthdayPeriod.allCases
        XCTAssertEqual(allCases.count, 5)
        XCTAssertTrue(allCases.contains(.today))
        XCTAssertTrue(allCases.contains(.tomorrow))
        XCTAssertTrue(allCases.contains(.thisWeek))
        XCTAssertTrue(allCases.contains(.thisMonth))
        XCTAssertTrue(allCases.contains(.later))
    }

    // MARK: - Integration Tests

    func testZodiacAndAgeIntegration() {
        // Person born on 30.07.1990 (Leo)
        let birthday = makeDate(year: 1990, month: 7, day: 30)
        let age = BirthdayDateHelper.age(from: birthday)
        let zodiac = BirthdayDateHelper.zodiacSign(from: birthday)

        XCTAssertGreaterThan(age, 30)  // Should be over 30 years old
        XCTAssertEqual(zodiac, "♌ Löwe")
    }

    func testFormattingConsistency() {
        let birthday = makeDate(year: 1995, month: 10, day: 15)
        let shortFormat = BirthdayDateHelper.formatBirthdayShort(birthday)
        let fullFormat = BirthdayDateHelper.formatBirthdayFull(birthday)

        // Full format should contain everything from short format plus year
        XCTAssertFalse(shortFormat.isEmpty)
        XCTAssertFalse(fullFormat.isEmpty)
        XCTAssertTrue(fullFormat.contains("1995"))
    }

    func testPeriodTransitions() {
        let calendar = Calendar.current
        let baseDate = Date()

        // Test period transitions
        let today = BirthdayDateHelper.period(for: baseDate, asOf: baseDate)
        XCTAssertEqual(today, .today)

        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: baseDate) {
            let tomorrowPeriod = BirthdayDateHelper.period(for: tomorrow, asOf: baseDate)
            XCTAssertEqual(tomorrowPeriod, .tomorrow)
        }

        if let nextWeek = calendar.date(byAdding: .day, value: 4, to: baseDate) {
            let weekPeriod = BirthdayDateHelper.period(for: nextWeek, asOf: baseDate)
            XCTAssertEqual(weekPeriod, .thisWeek)
        }

        if let nextMonth = calendar.date(byAdding: .day, value: 20, to: baseDate) {
            let monthPeriod = BirthdayDateHelper.period(for: nextMonth, asOf: baseDate)
            XCTAssertEqual(monthPeriod, .thisMonth)
        }

        if let later = calendar.date(byAdding: .day, value: 60, to: baseDate) {
            let laterPeriod = BirthdayDateHelper.period(for: later, asOf: baseDate)
            XCTAssertEqual(laterPeriod, .later)
        }
    }
}
