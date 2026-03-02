import XCTest
@testable import aiPresentsApp

final class BirthdayCalculatorTests: XCTestCase {
    let calendar = Calendar.current

    func testNextBirthdayThisYear() {
        // Test birthday that hasn't occurred yet this year
        let today = createDate(month: 3, day: 2)
        let birthday = createDate(month: 6, day: 15) // June 15

        let nextBirthday = BirthdayCalculator.nextBirthday(for: birthday, from: today)

        XCTAssertNotNil(nextBirthday)
        XCTAssertEqual(calendar.component(.month, from: nextBirthday!), 6)
        XCTAssertEqual(calendar.component(.day, from: nextBirthday!), 15)
        XCTAssertEqual(calendar.component(.year, from: nextBirthday!), calendar.component(.year, from: today))
    }

    func testNextBirthdayNextYear() {
        // Test birthday that already occurred this year
        let today = createDate(month: 6, day: 16)
        let birthday = createDate(month: 6, day: 15) // June 15

        let nextBirthday = BirthdayCalculator.nextBirthday(for: birthday, from: today)

        XCTAssertNotNil(nextBirthday)
        XCTAssertEqual(calendar.component(.month, from: nextBirthday!), 6)
        XCTAssertEqual(calendar.component(.day, from: nextBirthday!), 15)
        XCTAssertEqual(calendar.component(.year, from: nextBirthday!), calendar.component(.year, from: today) + 1)
    }

    func testNextBirthdayToday() {
        // Test birthday that is today
        let today = createDate(month: 6, day: 15)
        let birthday = createDate(month: 6, day: 15)

        let nextBirthday = BirthdayCalculator.nextBirthday(for: birthday, from: today)

        XCTAssertNotNil(nextBirthday)
        XCTAssertEqual(calendar.component(.month, from: nextBirthday!), 6)
        XCTAssertEqual(calendar.component(.day, from: nextBirthday!), 15)
        XCTAssertEqual(calendar.component(.year, from: nextBirthday!), calendar.component(.year, from: today))
    }

    func testDaysUntilBirthdayFuture() {
        let today = createDate(month: 3, day: 2)
        let birthday = createDate(month: 6, day: 15)

        let daysUntil = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today)

        XCTAssertNotNil(daysUntil)
        XCTAssertEqual(daysUntil!, 105) // Approximate days from March 2 to June 15
    }

    func testDaysUntilBirthdayPast() {
        let today = createDate(month: 6, day: 16)
        let birthday = createDate(month: 6, day: 15)

        let daysUntil = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today)

        XCTAssertNotNil(daysUntil)
        // Should be days until next year's birthday
        XCTAssertGreaterThan(daysUntil!, 300)
    }

    func testDaysUntilBirthdayToday() {
        let today = createDate(month: 6, day: 15)
        let birthday = createDate(month: 6, day: 15)

        let daysUntil = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today)

        XCTAssertNotNil(daysUntil)
        XCTAssertEqual(daysUntil!, 0)
    }

    func testIsBirthdayTodayTrue() {
        let today = createDate(month: 6, day: 15)
        let birthday = createDate(month: 6, day: 15)

        XCTAssertTrue(BirthdayCalculator.isBirthdayToday(for: birthday, from: today))
    }

    func testIsBirthdayTodayFalse() {
        let today = createDate(month: 6, day: 16)
        let birthday = createDate(month: 6, day: 15)

        XCTAssertFalse(BirthdayCalculator.isBirthdayToday(for: birthday, from: today))
    }

    func testIsBirthdayWithinDays() {
        let today = createDate(month: 6, day: 10)
        let birthday = createDate(month: 6, day: 15)

        XCTAssertTrue(BirthdayCalculator.isBirthdayWithinDays(for: birthday, days: 10, from: today))
        XCTAssertFalse(BirthdayCalculator.isBirthdayWithinDays(for: birthday, days: 4, from: today))
    }

    func testAgeCalculation() {
        let today = createDate(month: 6, day: 16, year: 2026)
        let birthday = createDate(month: 6, day: 15, year: 1990)

        let age = BirthdayCalculator.age(for: birthday, on: today)

        XCTAssertNotNil(age)
        XCTAssertEqual(age!, 36) // 2026 - 1990 = 36
    }

    func testAgeBeforeBirthday() {
        let today = createDate(month: 6, day: 10, year: 2026)
        let birthday = createDate(month: 6, day: 15, year: 1990)

        let age = BirthdayCalculator.age(for: birthday, on: today)

        XCTAssertNotNil(age)
        XCTAssertEqual(age!, 35) // Haven't had birthday yet in 2026
    }

    // MARK: - Caching Tests

    func testCacheClearWorks() {
        let today = createDate(month: 6, day: 15)
        let birthday = createDate(month: 6, day: 15)

        // First call populates cache
        _ = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today)

        // Clear cache
        BirthdayCalculator.clearCache()

        // Second call should still work after cache clear
        let daysAfterClear = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today)
        XCTAssertNotNil(daysAfterClear)
        XCTAssertEqual(daysAfterClear, 0)
    }

    func testCacheReturnsSameResult() {
        let today = createDate(month: 3, day: 2)
        let birthday = createDate(month: 6, day: 15)

        // First call
        let days1 = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today)

        // Second call (should hit cache)
        let days2 = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today)

        // Both should return the same value
        XCTAssertEqual(days1, days2)
        XCTAssertNotNil(days1)
        XCTAssertNotNil(days2)
    }

    func testCacheDifferentDatesDoNotInterfere() {
        let today1 = createDate(month: 3, day: 2)
        let today2 = createDate(month: 3, day: 3)
        let birthday = createDate(month: 6, day: 15)

        // Calculate from two different reference dates
        let days1 = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today1)
        let days2 = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today2)

        // Results should be different (one day apart)
        XCTAssertNotNil(days1)
        XCTAssertNotNil(days2)
        XCTAssertEqual(days2, days1! - 1)
    }

    func testCacheDifferentBirthdaysDoNotInterfere() {
        let today = createDate(month: 3, day: 2)
        let birthday1 = createDate(month: 6, day: 15)
        let birthday2 = createDate(month: 6, day: 16)

        // Calculate for two different birthdays
        let days1 = BirthdayCalculator.daysUntilBirthday(for: birthday1, from: today)
        let days2 = BirthdayCalculator.daysUntilBirthday(for: birthday2, from: today)

        // Results should be different (one day apart)
        XCTAssertNotNil(days1)
        XCTAssertNotNil(days2)
        XCTAssertEqual(days2, days1! + 1)
    }

    // Helper to create a date in the current year
    private func createDate(month: Int, day: Int, year: Int? = nil) -> Date {
        let calendar = Calendar.current
        let currentYear = year ?? calendar.component(.year, from: Date())

        var components = DateComponents()
        components.year = currentYear
        components.month = month
        components.day = day
        components.hour = 12 // Noon to avoid timezone issues

        return calendar.date(from: components) ?? Date()
    }
}
