import XCTest
@testable import aiPresentsApp

/// Thread Safety Tests for BirthdayCalculator cache
final class BirthdayCalculatorThreadSafetyTests: XCTestCase {

    func testConcurrentCacheAccess() async {
        let birthday = createDate(month: 6, day: 15)
        let today = createDate(month: 3, day: 2)

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    _ = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today)
                    _ = BirthdayCalculator.nextBirthday(for: birthday, from: today)
                }
            }
        }

        let daysUntil = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today)
        XCTAssertNotNil(daysUntil)
    }

    func testConcurrentCacheClearAndAccess() async {
        let birthday = createDate(month: 6, day: 15)
        let today = createDate(month: 3, day: 2)

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<50 {
                if i % 10 == 0 {
                    group.addTask { BirthdayCalculator.clearCache() }
                } else {
                    group.addTask {
                        _ = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today)
                    }
                }
            }
        }

        let daysUntil = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today)
        XCTAssertNotNil(daysUntil)
    }

    private func createDate(month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = 2026
        components.month = month
        components.day = day
        components.hour = 12
        return Calendar.current.date(from: components) ?? Date()
    }
}
