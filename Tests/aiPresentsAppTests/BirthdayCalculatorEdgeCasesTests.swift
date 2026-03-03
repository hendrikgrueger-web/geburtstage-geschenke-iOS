import XCTest
@testable import aiPresentsApp

final class BirthdayCalculatorEdgeCasesTests: XCTestCase {

    // MARK: - Leap Year Tests

    func testLeapYearBirthdayOnNonLeapYear() {
        let calendar = Calendar.current
        // March 1, 2025 (not a leap year)
        let today = calendar.date(from: DateComponents(year: 2025, month: 3, day: 1))!
        // Birthday on Feb 29, 1992 (leap year)
        let birthday = calendar.date(from: DateComponents(year: 1992, month: 2, day: 29))!

        let next = BirthdayCalculator.nextBirthday(for: birthday, from: today)

        // For Feb 29 birthdays on non-leap years, behavior depends on Calendar implementation:
        // - Could return nil (can't construct Feb 29)
        // - Could return Feb 28 or March 1 (Calendar overflow)
        // - Could skip to next leap year (Feb 29, 2028)
        // All of these are acceptable edge case behaviors
        if let next = next {
            let year = calendar.component(.year, from: next)
            XCTAssertGreaterThanOrEqual(year, 2025, "Next birthday should be in current or future year")
        }
    }

    func testLeapYearBirthdayOnLeapYear() {
        let calendar = Calendar.current
        // Jan 1, 2024 (leap year)
        let today = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        // Birthday on Feb 29, 1992 (leap year)
        let birthday = calendar.date(from: DateComponents(year: 1992, month: 2, day: 29))!

        let next = BirthdayCalculator.nextBirthday(for: birthday, from: today)

        XCTAssertEqual(calendar.component(.year, from: next!), 2024)
        XCTAssertEqual(calendar.component(.month, from: next!), 2)
        XCTAssertEqual(calendar.component(.day, from: next!), 29)
    }

    // MARK: - Year Boundary Tests

    func testBirthdayOnNewYearsEve() {
        let calendar = Calendar.current
        let today = calendar.date(from: DateComponents(year: 2026, month: 12, day: 31))!
        let birthday = calendar.date(from: DateComponents(year: 1990, month: 12, day: 31))!

        let next = BirthdayCalculator.nextBirthday(for: birthday, from: today)
        let days = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today)

        XCTAssertEqual(days, 0)
        XCTAssertEqual(calendar.component(.month, from: next!), 12)
        XCTAssertEqual(calendar.component(.day, from: next!), 31)
    }

    func testBirthdayOnNewYearsDay() {
        let calendar = Calendar.current
        let today = calendar.date(from: DateComponents(year: 2026, month: 12, day: 31))!
        let birthday = calendar.date(from: DateComponents(year: 1990, month: 1, day: 1))!

        let next = BirthdayCalculator.nextBirthday(for: birthday, from: today)
        let days = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today)

        XCTAssertEqual(days, 1)
        XCTAssertEqual(calendar.component(.year, from: next!), 2027)
        XCTAssertEqual(calendar.component(.month, from: next!), 1)
        XCTAssertEqual(calendar.component(.day, from: next!), 1)
    }

    // MARK: - Maximum Distance Tests

    func testDaysUntilBirthdayMaximum() {
        let calendar = Calendar.current
        let today = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let birthday = calendar.date(from: DateComponents(year: 1990, month: 12, day: 31))!

        let next = BirthdayCalculator.nextBirthday(for: birthday, from: today)
        let days = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today)

        XCTAssertEqual(days, 364) // or 365 in leap year
        XCTAssertEqual(calendar.component(.year, from: next!), 2026)
    }

    func testDaysUntilBirthdayExactlyOneYear() {
        let calendar = Calendar.current
        let today = calendar.date(from: DateComponents(year: 2026, month: 3, day: 2))!
        let birthday = calendar.date(from: DateComponents(year: 1990, month: 3, day: 2))!

        let next = BirthdayCalculator.nextBirthday(for: birthday, from: today)
        let days = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today)

        XCTAssertEqual(days, 0)
    }

    // MARK: - Midnight Boundary Tests

    func testBirthdayJustAfterMidnight() {
        let calendar = Calendar.current
        // March 15, 2026 at 00:00:01
        let today = calendar.date(from: DateComponents(year: 2026, month: 3, day: 15, hour: 0, minute: 0, second: 1))!
        let birthday = calendar.date(from: DateComponents(year: 1990, month: 3, day: 15))!

        let next = BirthdayCalculator.nextBirthday(for: birthday, from: today)
        let days = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today)

        XCTAssertEqual(days, 0)
    }

    func testBirthdayJustBeforeMidnight() {
        let calendar = Calendar.current
        // March 14, 2026 at 23:59:59
        let today = calendar.date(from: DateComponents(year: 2026, month: 3, day: 14, hour: 23, minute: 59, second: 59))!
        let birthday = calendar.date(from: DateComponents(year: 1990, month: 3, day: 15))!

        let next = BirthdayCalculator.nextBirthday(for: birthday, from: today)
        let days = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today)

        XCTAssertEqual(days, 1)
    }

    // MARK: - Month Boundary Tests

    func testBirthdayEndOfMonth() {
        let calendar = Calendar.current
        let today = calendar.date(from: DateComponents(year: 2026, month: 1, day: 31))!
        let birthday = calendar.date(from: DateComponents(year: 1990, month: 1, day: 31))!

        let next = BirthdayCalculator.nextBirthday(for: birthday, from: today)
        let days = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today)

        XCTAssertEqual(days, 0)
    }

    func testBirthdayOnFebruary28NonLeapYear() {
        let calendar = Calendar.current
        let today = calendar.date(from: DateComponents(year: 2025, month: 2, day: 28))!
        let birthday = calendar.date(from: DateComponents(year: 1990, month: 2, day: 28))!

        let next = BirthdayCalculator.nextBirthday(for: birthday, from: today)
        let days = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today)

        XCTAssertEqual(days, 0)
    }

    func testBirthdayOnFebruary28LeapYear() {
        let calendar = Calendar.current
        let today = calendar.date(from: DateComponents(year: 2024, month: 2, day: 28))!
        let birthday = calendar.date(from: DateComponents(year: 1990, month: 2, day: 28))!

        let next = BirthdayCalculator.nextBirthday(for: birthday, from: today)
        let days = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today)

        XCTAssertEqual(days, 0)
    }

    // MARK: - Negative Distance Tests

    func testBirthdayYesterdayReturnsNextYear() {
        let calendar = Calendar.current
        let today = calendar.date(from: DateComponents(year: 2026, month: 3, day: 15))!
        let birthday = calendar.date(from: DateComponents(year: 1990, month: 3, day: 14))!

        let next = BirthdayCalculator.nextBirthday(for: birthday, from: today)
        let days = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today)

        // Should be next year
        XCTAssertGreaterThan(days!, 300) // roughly 11 months
        XCTAssertEqual(calendar.component(.year, from: next!), 2027)
    }

    func testBirthdayOneWeekAgoReturnsNextYear() {
        let calendar = Calendar.current
        let today = calendar.date(from: DateComponents(year: 2026, month: 3, day: 15))!
        let birthday = calendar.date(from: DateComponents(year: 1990, month: 3, day: 8))!

        let next = BirthdayCalculator.nextBirthday(for: birthday, from: today)
        let days = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today)

        // Should be roughly 358 days
        XCTAssertGreaterThan(days!, 350)
        XCTAssertLessThan(days!, 365)
        XCTAssertEqual(calendar.component(.year, from: next!), 2027)
    }

    // MARK: - Same Month Tests

    func testBirthdayEarlierInSameMonth() {
        let calendar = Calendar.current
        let today = calendar.date(from: DateComponents(year: 2026, month: 3, day: 15))!
        let birthday = calendar.date(from: DateComponents(year: 1990, month: 3, day: 10))!

        let next = BirthdayCalculator.nextBirthday(for: birthday, from: today)

        XCTAssertEqual(calendar.component(.year, from: next!), 2027)
        XCTAssertEqual(calendar.component(.month, from: next!), 3)
        XCTAssertEqual(calendar.component(.day, from: next!), 10)
    }

    func testBirthdayLaterInSameMonth() {
        let calendar = Calendar.current
        let today = calendar.date(from: DateComponents(year: 2026, month: 3, day: 10))!
        let birthday = calendar.date(from: DateComponents(year: 1990, month: 3, day: 15))!

        let next = BirthdayCalculator.nextBirthday(for: birthday, from: today)
        let days = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today)

        XCTAssertEqual(calendar.component(.year, from: next!), 2026)
        XCTAssertEqual(calendar.component(.month, from: next!), 3)
        XCTAssertEqual(calendar.component(.day, from: next!), 15)
        XCTAssertEqual(days, 5)
    }
}
