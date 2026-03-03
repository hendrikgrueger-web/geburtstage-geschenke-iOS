import XCTest
@testable import aiPresentsApp

final class BirthdayCalculationTests: XCTestCase {

    func testNextBirthdaySameYear() {
        let calendar = Calendar.current
        let today = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1))!
        let birthday = calendar.date(from: DateComponents(year: 1990, month: 3, day: 15))!

        let next = calculateNextBirthday(birthday: birthday, from: today)

        XCTAssertEqual(calendar.component(.year, from: next), 2026)
        XCTAssertEqual(calendar.component(.month, from: next), 3)
        XCTAssertEqual(calendar.component(.day, from: next), 15)
    }

    func testNextBirthdayNextYear() {
        let calendar = Calendar.current
        let today = calendar.date(from: DateComponents(year: 2026, month: 3, day: 20))!
        let birthday = calendar.date(from: DateComponents(year: 1990, month: 3, day: 15))!

        let next = calculateNextBirthday(birthday: birthday, from: today)

        XCTAssertEqual(calendar.component(.year, from: next), 2027)
        XCTAssertEqual(calendar.component(.month, from: next), 3)
        XCTAssertEqual(calendar.component(.day, from: next), 15)
    }

    func testNextBirthdayToday() {
        let calendar = Calendar.current
        let today = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1))!
        let birthday = calendar.date(from: DateComponents(year: 1990, month: 3, day: 1))!

        let next = calculateNextBirthday(birthday: birthday, from: today)

        XCTAssertEqual(calendar.component(.year, from: next), 2026)
        XCTAssertEqual(calendar.component(.month, from: next), 3)
        XCTAssertEqual(calendar.component(.day, from: next), 1)
    }

    func testNextBirthdayDecemberToJanuary() {
        let calendar = Calendar.current
        let today = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        let birthday = calendar.date(from: DateComponents(year: 1990, month: 12, day: 25))!

        let next = calculateNextBirthday(birthday: birthday, from: today)

        XCTAssertEqual(calendar.component(.year, from: next), 2026)
        XCTAssertEqual(calendar.component(.month, from: next), 12)
        XCTAssertEqual(calendar.component(.day, from: next), 25)
    }

    func testDaysUntilBirthday() {
        let calendar = Calendar.current
        let today = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1))!
        let birthday = calendar.date(from: DateComponents(year: 1990, month: 3, day: 15))!

        let next = calculateNextBirthday(birthday: birthday, from: today)
        let days = calendar.dateComponents([.day], from: today, to: next).day

        XCTAssertEqual(days, 14)
    }

    func testDaysUntilBirthdayZero() {
        let calendar = Calendar.current
        let today = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1))!
        let birthday = calendar.date(from: DateComponents(year: 1990, month: 3, day: 1))!

        let next = calculateNextBirthday(birthday: birthday, from: today)
        let days = calendar.dateComponents([.day], from: today, to: next).day

        XCTAssertEqual(days, 0)
    }

    func testQuietHoursWithinRange() {
        // Test 23:00 is within 22:00-08:00
        let result = isWithinQuietHours(hour: 23, start: 22, end: 8)
        XCTAssertTrue(result)
    }

    func testQuietHoursOutsideRange() {
        // Test 12:00 is outside 22:00-08:00
        let result = isWithinQuietHours(hour: 12, start: 22, end: 8)
        XCTAssertFalse(result)
    }

    func testQuietHoursBoundaryStart() {
        // Test 22:00 is within 22:00-08:00 (inclusive)
        let result = isWithinQuietHours(hour: 22, start: 22, end: 8)
        XCTAssertTrue(result)
    }

    func testQuietHoursBoundaryEnd() {
        // Test 08:00 is outside 22:00-08:00 (exclusive)
        let result = isWithinQuietHours(hour: 8, start: 22, end: 8)
        XCTAssertFalse(result)
    }

    func testQuietHoursNormalRange() {
        // Test 01:00 is within 22:00-06:00 (wraps around midnight)
        let result = isWithinQuietHours(hour: 1, start: 22, end: 6)
        XCTAssertTrue(result)
    }

    func testQuietHoursNormalWithin() {
        // Test 23:00 is within 20:00-06:00 when start < end
        let result = isWithinQuietHours(hour: 23, start: 20, end: 6)
        XCTAssertTrue(result)
    }

    // MARK: - Helper functions (copies from ReminderManager)

    private func calculateNextBirthday(birthday: Date, from today: Date) -> Date {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: today)

        var components = calendar.dateComponents([.month, .day], from: birthday)
        components.year = currentYear

        guard var nextBirthday = calendar.date(from: components) else {
            return birthday
        }

        if nextBirthday < today {
            components.year = currentYear + 1
            nextBirthday = calendar.date(from: components) ?? nextBirthday
        }

        return nextBirthday
    }

    private func isWithinQuietHours(hour: Int, start: Int, end: Int) -> Bool {
        if start < end {
            return hour >= start && hour < end
        }
        return hour >= start || hour < end
    }
}
