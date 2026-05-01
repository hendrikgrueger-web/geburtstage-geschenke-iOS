import XCTest
@testable import aiPresentsApp

/// Extreme Test-Coverage fuer die neuen TimelineView-Counters in v1.0.7:
/// - birthdaysToday / birthdaysThisWeek / birthdaysThisMonth (jetzt 0..30 statt 0..7)
/// - soonestBirthdayPerson (fuer Reassurance-Zeile)
///
/// Wir testen die unterliegende `BirthdayCalculator`-Logik mit denselben
/// Tag-Buckets, die in der View verwendet werden — damit die Stats-Row genau
/// das anzeigt, was die Liste auch durchscrollen wuerde.
final class TimelineCountersTests: XCTestCase {

    private let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return c
    }()

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d))!
    }

    // MARK: - „Heute"-Bucket (days == 0)

    func testToday_birthdayOnReferenceDate_isToday() {
        let today = date(2026, 5, 1)
        let birthday = date(1990, 5, 1)
        let days = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today)
        XCTAssertEqual(days, 0, "Geburtstag heute = days 0 = Zaehler `birthdaysToday` zaehlt mit")
    }

    func testToday_yesterdayBirthday_notToday() {
        let today = date(2026, 5, 2)
        let birthday = date(1990, 5, 1)
        let days = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today)
        // Geburtstag war gestern — naechster ist in einem Jahr minus 1 Tag
        XCTAssertNotEqual(days, 0)
        XCTAssertGreaterThan(days ?? 0, 300)
    }

    // MARK: - „Diese Woche"-Bucket (0..7)

    func testThisWeek_birthdayInExactly7Days_counts() {
        let today = date(2026, 5, 1)
        let birthday = date(1990, 5, 8)
        let days = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today)
        XCTAssertEqual(days, 7)
        XCTAssertTrue((0...7).contains(days ?? -1), "Tag 7 ist exakt der Cutoff — muss in Diese Woche enthalten sein")
    }

    func testThisWeek_birthdayInExactly8Days_doesNotCount() {
        let today = date(2026, 5, 1)
        let birthday = date(1990, 5, 9)
        let days = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today)
        XCTAssertEqual(days, 8)
        XCTAssertFalse((0...7).contains(days ?? -1), "Tag 8 darf nicht in Diese Woche zaehlen")
    }

    // MARK: - „Diesen Monat"-Bucket (0..30)

    func testThisMonth_birthdayInExactly30Days_counts() {
        let today = date(2026, 5, 1)
        let birthday = date(1990, 5, 31)
        let days = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today)
        XCTAssertEqual(days, 30)
        XCTAssertTrue((0...30).contains(days ?? -1), "Tag 30 ist Cutoff — muss in Diesen Monat enthalten sein")
    }

    func testThisMonth_birthdayInExactly31Days_doesNotCount() {
        let today = date(2026, 5, 1)
        let birthday = date(1990, 6, 1)
        let days = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today)
        XCTAssertEqual(days, 31)
        XCTAssertFalse((0...30).contains(days ?? -1))
    }

    // MARK: - Bucket-Hierarchie (Heute ⊆ Diese Woche ⊆ Diesen Monat)

    func testBuckets_todayCountedInAllThreeBuckets() {
        let today = date(2026, 5, 1)
        let birthday = date(1990, 5, 1)
        let days = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today) ?? -1
        XCTAssertTrue(days == 0, "Heute")
        XCTAssertTrue((0...7).contains(days), "Heute muss auch in `Diese Woche` zaehlen")
        XCTAssertTrue((0...30).contains(days), "Heute muss auch in `Diesen Monat` zaehlen")
    }

    func testBuckets_dayInWeekCountedInWeekAndMonth() {
        let today = date(2026, 5, 1)
        let birthday = date(1990, 5, 5)
        let days = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today) ?? -1
        XCTAssertEqual(days, 4)
        XCTAssertFalse(days == 0)
        XCTAssertTrue((0...7).contains(days))
        XCTAssertTrue((0...30).contains(days))
    }

    func testBuckets_dayInMonthCountedOnlyInMonth() {
        let today = date(2026, 5, 1)
        let birthday = date(1990, 5, 25)
        let days = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today) ?? -1
        XCTAssertEqual(days, 24)
        XCTAssertFalse(days == 0)
        XCTAssertFalse((0...7).contains(days))
        XCTAssertTrue((0...30).contains(days))
    }

    // MARK: - Edge: Schalttag

    func testLeapYear_february29_currentYearNonLeap() {
        let today = date(2027, 2, 28) // 2027 = kein Schaltjahr
        let birthday = date(2000, 2, 29)
        let days = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today)
        XCTAssertNotNil(days, "Schalttag-Geburtstag muss in Nicht-Schalttag-Jahr ein gueltiges naechstes Datum bekommen")
    }

    // MARK: - Edge: Jahreswechsel

    func testYearTransition_birthdayInJanuary_fromDecember() {
        let today = date(2026, 12, 30)
        let birthday = date(1990, 1, 5)
        let days = BirthdayCalculator.daysUntilBirthday(for: birthday, from: today) ?? -1
        XCTAssertEqual(days, 6, "5. Jan ist 6 Tage nach 30. Dez — muss in Diese Woche zaehlen")
        XCTAssertTrue((0...7).contains(days))
    }

    // MARK: - Reassurance-Zeile-Logik

    /// Reassurance erscheint nur wenn alle 3 Counter 0 sind UND Personen existieren.
    /// Das uebersetzen wir hier in „kein Geburtstag in 0..30 Tagen".
    func testReassurance_onlyShownWhenNoBirthdayInNext30Days() {
        let today = date(2026, 5, 1)

        // 35 Tage entfernt: nicht in „Diesen Monat"
        let person1Birthday = date(1990, 6, 5)
        let days1 = BirthdayCalculator.daysUntilBirthday(for: person1Birthday, from: today) ?? -1
        XCTAssertFalse((0...30).contains(days1))

        // 90 Tage entfernt: ebenfalls nicht
        let person2Birthday = date(1990, 7, 30)
        let days2 = BirthdayCalculator.daysUntilBirthday(for: person2Birthday, from: today) ?? -1
        XCTAssertFalse((0...30).contains(days2))

        // Soonest waere Person 1 mit days1 < days2
        XCTAssertLessThan(days1, days2)
    }

    func testReassurance_notShownWhenSomeoneInThisMonth() {
        let today = date(2026, 5, 1)
        let person1Birthday = date(1990, 5, 20) // 19 Tage = in „Diesen Monat"
        let days1 = BirthdayCalculator.daysUntilBirthday(for: person1Birthday, from: today) ?? -1
        XCTAssertTrue((0...30).contains(days1))
        // -> Reassurance wird ausgeblendet, denn `birthdaysThisMonth > 0`
    }

    // MARK: - „birthdaysToday" mit mehreren Personen

    func testMultiplePeopleSameBirthday_today_counts() {
        let today = date(2026, 5, 1)
        let bday = date(1985, 5, 1)
        let days = BirthdayCalculator.daysUntilBirthday(for: bday, from: today) ?? -1
        XCTAssertEqual(days, 0)
        // Wenn n Personen heute Geburtstag haben, muss jede einzeln zaehlen.
        // Die View nutzt `people.filter { ... }.count` — die Logik ist linear,
        // also hier nur Smoke-Test.
    }

    // MARK: - Performance bei vielen Personen

    func testCounters_with500People_underReasonableTime() {
        let today = date(2026, 5, 1)
        let bdays = (0..<500).map { i -> Date in
            // verteilt ueber das ganze Jahr
            let dayOfYear = (i % 365) + 1
            return cal.date(byAdding: .day, value: dayOfYear, to: date(1990, 1, 1))!
        }

        measure {
            var todayCount = 0
            var weekCount = 0
            var monthCount = 0
            for b in bdays {
                if let d = BirthdayCalculator.daysUntilBirthday(for: b, from: today) {
                    if d == 0 { todayCount += 1 }
                    if (0...7).contains(d) { weekCount += 1 }
                    if (0...30).contains(d) { monthCount += 1 }
                }
            }
            XCTAssertGreaterThanOrEqual(monthCount, weekCount)
            XCTAssertGreaterThanOrEqual(weekCount, todayCount)
        }
    }
}
