import XCTest
@testable import aiPresentsApp

final class BirthdayDateHelperTests: XCTestCase {

    // MARK: - Age Calculation Tests

    func testAgeCalculation_BirthdayToday() {
        let today = Date()
        let age = BirthdayDateHelper.age(from: today, asOf: today)

        XCTAssertEqual(age, 0)
    }

    func testAgeCalculation_BirthdayLastYear() {
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.year! -= 1

        if let birthday = calendar.date(from: components) {
            let age = BirthdayDateHelper.age(from: birthday, asOf: today)
            XCTAssertEqual(age, 1)
        }
    }

    func testAgeCalculation_Birthday20YearsAgo() {
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.year! -= 20

        if let birthday = calendar.date(from: components) {
            let age = BirthdayDateHelper.age(from: birthday, asOf: today)
            XCTAssertEqual(age, 20)
        }
    }

    // MARK: - Next Birthday Tests

    func testNextBirthday_ThisYear() {
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.day! += 10  // 10 days from now

        if let birthday = calendar.date(from: components) {
            let next = BirthdayDateHelper.nextBirthday(from: birthday, after: today)

            XCTAssertNotNil(next)
            let daysUntil = BirthdayDateHelper.daysBetween(from: today, to: next!)
            XCTAssertEqual(daysUntil, 10)
        }
    }

    func testNextBirthday_NextYear() {
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.day! -= 10  // 10 days ago (already passed this year)

        if let birthday = calendar.date(from: components) {
            let next = BirthdayDateHelper.nextBirthday(from: birthday, after: today)

            XCTAssertNotNil(next)
            let daysUntil = BirthdayDateHelper.daysBetween(from: today, to: next!)

            // Should be about 355-356 days (next year's birthday)
            XCTAssertGreaterThan(daysUntil, 300)
            XCTAssertLessThan(daysUntil, 400)
        }
    }

    // MARK: - Days Until Birthday Tests

    func testDaysUntilBirthday_Today() {
        let today = Date()
        let daysUntil = BirthdayDateHelper.daysUntilBirthday(from: today, asOf: today)

        XCTAssertEqual(daysUntil, 0)
    }

    func testDaysUntilBirthday_Tomorrow() {
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.day! += 1

        if let birthday = calendar.date(from: components) {
            let daysUntil = BirthdayDateHelper.daysUntilBirthday(from: birthday, asOf: today)

            XCTAssertEqual(daysUntil, 1)
        }
    }

    func testDaysUntilBirthday_7Days() {
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.day! += 7

        if let birthday = calendar.date(from: components) {
            let daysUntil = BirthdayDateHelper.daysUntilBirthday(from: birthday, asOf: today)

            XCTAssertEqual(daysUntil, 7)
        }
    }

    // MARK: - Birthday Check Tests

    func testIsBirthdayToday_Today() {
        let today = Date()
        let isToday = BirthdayDateHelper.isBirthdayToday(from: today, asOf: today)

        XCTAssertTrue(isToday)
    }

    func testIsBirthdayToday_NotToday() {
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.day! += 7

        if let birthday = calendar.date(from: components) {
            let isToday = BirthdayDateHelper.isBirthdayToday(from: birthday, asOf: today)

            XCTAssertFalse(isToday)
        }
    }

    func testIsBirthdayTomorrow_Tomorrow() {
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.day! += 1

        if let birthday = calendar.date(from: components) {
            let isTomorrow = BirthdayDateHelper.isBirthdayTomorrow(from: birthday, asOf: today)

            XCTAssertTrue(isTomorrow)
        }
    }

    func testIsBirthdayWithinDays_WithinRange() {
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.day! += 5

        if let birthday = calendar.date(from: components) {
            let withinRange = BirthdayDateHelper.isBirthdayWithinDays(7, from: birthday, asOf: today)

            XCTAssertTrue(withinRange)
        }
    }

    func testIsBirthdayWithinDays_OutsideRange() {
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.day! += 14

        if let birthday = calendar.date(from: components) {
            let withinRange = BirthdayDateHelper.isBirthdayWithinDays(7, from: birthday, asOf: today)

            XCTAssertFalse(withinRange)
        }
    }

    // MARK: - Milestone Tests

    func testIsMilestoneAge_18() {
        XCTAssertTrue(BirthdayDateHelper.isMilestoneAge(age: 18))
    }

    func testIsMilestoneAge_21() {
        XCTAssertTrue(BirthdayDateHelper.isMilestoneAge(age: 21))
    }

    func testIsMilestoneAge_30() {
        XCTAssertTrue(BirthdayDateHelper.isMilestoneAge(age: 30))
    }

    func testIsMilestoneAge_50() {
        XCTAssertTrue(BirthdayDateHelper.isMilestoneAge(age: 50))
    }

    func testIsMilestoneAge_NotMilestone() {
        XCTAssertFalse(BirthdayDateHelper.isMilestoneAge(age: 25))
    }

    func testIsMilestoneAge_NotMilestone2() {
        XCTAssertFalse(BirthdayDateHelper.isMilestoneAge(age: 35))
    }

    func testMilestoneName_18() {
        let name = BirthdayDateHelper.milestoneName(for: 18)

        XCTAssertNotNil(name)
        XCTAssertTrue(name!.contains("Volljährigkeit"))
    }

    func testMilestoneName_21() {
        let name = BirthdayDateHelper.milestoneName(for: 21)

        XCTAssertNotNil(name)
        XCTAssertTrue(name!.contains("Große Mehrheit"))
    }

    func testMilestoneName_NotMilestone() {
        let name = BirthdayDateHelper.milestoneName(for: 25)

        XCTAssertNil(name)
    }

    // MARK: - Birthday Period Tests

    func testBirthdayPeriod_Today() {
        let today = Date()
        let period = BirthdayDateHelper.period(for: today, asOf: today)

        XCTAssertEqual(period, .today)
    }

    func testBirthdayPeriod_Tomorrow() {
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.day! += 1

        if let birthday = calendar.date(from: components) {
            let period = BirthdayDateHelper.period(for: birthday, asOf: today)

            XCTAssertEqual(period, .tomorrow)
        }
    }

    func testBirthdayPeriod_ThisWeek() {
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.day! += 5

        if let birthday = calendar.date(from: components) {
            let period = BirthdayDateHelper.period(for: birthday, asOf: today)

            XCTAssertEqual(period, .thisWeek)
        }
    }

    func testBirthdayPeriod_ThisMonth() {
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.day! += 20

        if let birthday = calendar.date(from: components) {
            let period = BirthdayDateHelper.period(for: birthday, asOf: today)

            XCTAssertEqual(period, .thisMonth)
        }
    }

    func testBirthdayPeriod_Later() {
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.day! += 60

        if let birthday = calendar.date(from: components) {
            let period = BirthdayDateHelper.period(for: birthday, asOf: today)

            XCTAssertEqual(period, .later)
        }
    }

    // MARK: - Date Range Tests

    func testUpcomingRange_30Days() {
        let range = BirthdayDateHelper.upcomingRange
        let daysDifference = Calendar.current.dateComponents([.day], from: range.lowerBound, to: range.upperBound).day

        XCTAssertEqual(daysDifference, 30)
    }

    func testSoonRange_7Days() {
        let range = BirthdayDateHelper.soonRange
        let daysDifference = Calendar.current.dateComponents([.day], from: range.lowerBound, to: range.upperBound).day

        XCTAssertEqual(daysDifference, 7)
    }

    // MARK: - Formatting Tests

    func testRelativeDateDescription_Today() {
        let today = Date()
        let description = BirthdayDateHelper.relativeDateDescription(from: today, asOf: today)

        XCTAssertTrue(description.contains("Heute"))
    }

    func testRelativeDateDescription_Tomorrow() {
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.day! += 1

        if let birthday = calendar.date(from: components) {
            let description = BirthdayDateHelper.relativeDateDescription(from: birthday, asOf: today)

            XCTAssertTrue(description.contains("Morgen"))
        }
    }

    func testRelativeDateDescription_5Days() {
        let calendar = Calendar.current
        let today = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.day! += 5

        if let birthday = calendar.date(from: components) {
            let description = BirthdayDateHelper.relativeDateDescription(from: birthday, asOf: today)

            XCTAssertTrue(description.contains("5 Tagen"))
        }
    }
}
