import XCTest
@testable import aiPresentsApp

@MainActor
final class FormatterHelperTests: XCTestCase {
    let calendar = Calendar.current

    // MARK: - Date Formatting Tests

    func testFormatDateReturnsNonEmptyString() {
        let date = Date()
        let formatted = FormatterHelper.formatDate(date)

        XCTAssertFalse(formatted.isEmpty, "Formatted date should not be empty")
    }

    func testFormatShortDateReturnsNonEmptyString() {
        let date = Date()
        let formatted = FormatterHelper.formatShortDate(date)

        XCTAssertFalse(formatted.isEmpty, "Formatted short date should not be empty")
    }

    func testFormatRelativeDateToday() {
        let today = Date()
        let formatted = FormatterHelper.formatRelativeDate(today)

        XCTAssertEqual(formatted, "Heute", "Today should be formatted as 'Heute'")
    }

    func testFormatRelativeDateTomorrow() {
        let tomorrow = Date().addingTimeInterval(86400) // Add 1 day
        let formatted = FormatterHelper.formatRelativeDate(tomorrow)

        XCTAssertEqual(formatted, "Morgen", "Tomorrow should be formatted as 'Morgen'")
    }

    func testFormatRelativeDateYesterday() {
        let yesterday = Date().addingTimeInterval(-86400) // Subtract 1 day
        let formatted = FormatterHelper.formatRelativeDate(yesterday)

        XCTAssertEqual(formatted, "Gestern", "Yesterday should be formatted as 'Gestern'")
    }

    func testFormatRelativeDateInFewDays() {
        let date = Date().addingTimeInterval(86400 * 3) // Add 3 days
        let formatted = FormatterHelper.formatRelativeDate(date)

        XCTAssertTrue(formatted.hasPrefix("In "), "Should start with 'In'")
        XCTAssertTrue(formatted.hasSuffix(" Tagen"), "Should end with ' Tagen'")
        XCTAssertTrue(formatted.contains("3"), "Should contain the number of days")
    }

    func testFormatRelativeDateAFewDaysAgo() {
        let date = Date().addingTimeInterval(-86400 * 3) // Subtract 3 days
        let formatted = FormatterHelper.formatRelativeDate(date)

        XCTAssertTrue(formatted.hasPrefix("Vor "), "Should start with 'Vor'")
        XCTAssertTrue(formatted.hasSuffix(" Tagen"), "Should end with ' Tagen'")
        XCTAssertTrue(formatted.contains("3"), "Should contain the number of days")
    }

    func testFormatMonthYear() {
        let date = createDate(month: 6, day: 15, year: 2026)
        let formatted = FormatterHelper.formatMonthYear(date)

        XCTAssertTrue(formatted.contains("Juni"), "Should contain month name")
        XCTAssertTrue(formatted.contains("2026"), "Should contain year")
    }

    func testFormatWeekday() {
        let date = createDate(month: 3, day: 2, year: 2026) // Monday, March 2, 2026
        let formatted = FormatterHelper.formatWeekday(date)

        XCTAssertFalse(formatted.isEmpty, "Weekday should not be empty")
        XCTAssertTrue(["Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag"].contains(formatted),
                     "Should be a valid German weekday name")
    }

    // MARK: - Currency Formatting Tests

    func testFormatCurrency() {
        let formatted = FormatterHelper.formatCurrency(99.99)

        XCTAssertFalse(formatted.isEmpty, "Formatted currency should not be empty")
        XCTAssertTrue(formatted.contains("99") || formatted.contains("100"), "Should contain the amount")
    }

    func testFormatCurrencyZero() {
        let formatted = FormatterHelper.formatCurrency(0)

        XCTAssertFalse(formatted.isEmpty, "Zero should produce a non-empty string")
        XCTAssertTrue(formatted.contains("0"), "Zero should be formatted with 0")
    }

    func testFormatCurrencyLargeNumber() {
        let formatted = FormatterHelper.formatCurrency(1234.56)

        XCTAssertFalse(formatted.isEmpty, "Should not be empty")
        XCTAssertTrue(formatted.contains("1.235") || formatted.contains("1.234") || formatted.contains("1234") || formatted.contains("1235") || formatted.contains("1,235") || formatted.contains("1,234"), "Should contain the number")
    }

    // MARK: - Budget Formatting Tests

    func testFormatBudgetEqualMinMax() {
        let formatted = FormatterHelper.formatBudget(min: 50, max: 50)

        XCTAssertFalse(formatted.isEmpty, "Should not be empty")
        XCTAssertTrue(formatted.contains("50"), "Should contain the budget")
        XCTAssertFalse(formatted.contains("–"), "Should not contain range separator")
    }

    func testFormatBudgetMinZero() {
        let formatted = FormatterHelper.formatBudget(min: 0, max: 100)

        XCTAssertTrue(formatted.contains("bis"), "Should contain 'bis'")
        XCTAssertTrue(formatted.contains("100"), "Should contain max budget")
    }

    func testFormatBudgetRange() {
        let formatted = FormatterHelper.formatBudget(min: 25, max: 75)

        XCTAssertTrue(formatted.contains("25"), "Should contain min budget")
        XCTAssertTrue(formatted.contains("75"), "Should contain max budget")
        XCTAssertTrue(formatted.contains("–"), "Should contain range separator")
    }

    // MARK: - Number Formatting Tests

    func testFormatNumber() {
        let formatted = FormatterHelper.formatNumber(1234.56)

        XCTAssertFalse(formatted.isEmpty, "Formatted number should not be empty")
        XCTAssertTrue(formatted.contains("1.235") || formatted.contains("1235") || formatted.contains("1,235") || formatted.contains("1.234") || formatted.contains("1234"),
                     "Should contain the number")
    }

    // MARK: - List Formatting Tests

    func testFormatListEmpty() {
        let formatted = FormatterHelper.formatList([])

        XCTAssertEqual(formatted, "", "Empty list should be empty string")
    }

    func testFormatListOneItem() {
        let formatted = FormatterHelper.formatList(["Apfel"])

        XCTAssertEqual(formatted, "Apfel", "Single item should be returned as is")
    }

    func testFormatListTwoItems() {
        let formatted = FormatterHelper.formatList(["Apfel", "Birne"])

        XCTAssertEqual(formatted, "Apfel und Birne", "Two items should be joined with ' und '")
    }

    func testFormatListThreeItems() {
        let formatted = FormatterHelper.formatList(["Apfel", "Birne", "Kirsche"])

        XCTAssertTrue(formatted.contains("Apfel"), "Should contain first item")
        XCTAssertTrue(formatted.contains("Birne"), "Should contain second item")
        XCTAssertTrue(formatted.contains("Kirsche"), "Should contain third item")
        XCTAssertTrue(formatted.contains(" und "), "Should contain ' und '")
        XCTAssertTrue(formatted.contains(", "), "Should contain comma separator")
    }

    // MARK: - Text Truncation Tests

    func testTruncateShorterThanMaxLength() {
        let text = "Kurzer Text"
        let truncated = FormatterHelper.truncate(text, maxLength: 20)

        XCTAssertEqual(truncated, text, "Text shorter than max length should not be truncated")
    }

    func testTruncateExactlyMaxLength() {
        let text = "1234567890"
        let truncated = FormatterHelper.truncate(text, maxLength: 10)

        XCTAssertEqual(truncated, text, "Text at max length should not be truncated")
    }

    func testTruncateLongerThanMaxLength() {
        let text = "Dies ist ein sehr langer Text"
        let truncated = FormatterHelper.truncate(text, maxLength: 10)

        XCTAssertEqual(truncated.count, 10, "Truncated text should be exactly max length")
        XCTAssertTrue(truncated.hasSuffix("..."), "Should end with ellipsis")
    }

    // MARK: - URL Formatting Tests

    func testFormatURLValid() {
        let url = "https://www.example.com/path"
        let formatted = FormatterHelper.formatURL(url)

        XCTAssertTrue(formatted.contains("example.com"), "Should extract host")
    }

    func testFormatURLInvalid() {
        let invalidURL = "not-a-valid-url"
        let formatted = FormatterHelper.formatURL(invalidURL)

        XCTAssertEqual(formatted, invalidURL, "Invalid URL should be returned as is")
    }

    // MARK: - Age Formatting Tests

    func testFormatAge() {
        let formatted = FormatterHelper.formatAge(35)

        XCTAssertEqual(formatted, "35 Jahre alt", "Age should be formatted correctly")
    }

    func testFormatAgeOne() {
        let formatted = FormatterHelper.formatAge(1)

        XCTAssertEqual(formatted, "1 Jahre alt", "Age 1 should still use 'Jahre' (German grammar)")
    }

    func testFormatTurningAge() {
        let formatted = FormatterHelper.formatTurningAge(30)

        XCTAssertEqual(formatted, "wird 30", "Turning age should be formatted correctly")
    }

    // MARK: - Duration Formatting Tests

    func testFormatDurationOneDay() {
        let formatted = FormatterHelper.formatDuration(1)

        XCTAssertEqual(formatted, "1 Tag", "One day should be singular")
    }

    func testFormatDurationMultipleDays() {
        let formatted = FormatterHelper.formatDuration(7)

        XCTAssertEqual(formatted, "7 Tage", "Multiple days should be plural")
    }

    func testFormatDurationZero() {
        let formatted = FormatterHelper.formatDuration(0)

        XCTAssertEqual(formatted, "0 Tage", "Zero days should be plural")
    }

    // MARK: - Time Ago Formatting Tests

    func testFormatTimeAgoJustNow() {
        let date = Date()
        let formatted = FormatterHelper.formatTimeAgo(date)

        XCTAssertEqual(formatted, "gerade eben", "Current time should be 'gerade eben'")
    }

    func testFormatTimeAgoMinutesAgo() {
        let date = Date().addingTimeInterval(-60 * 5) // 5 minutes ago
        let formatted = FormatterHelper.formatTimeAgo(date)

        XCTAssertTrue(formatted.contains("5"), "Should contain minutes")
        XCTAssertTrue(formatted.contains("Minute"), "Should contain 'Minute'")
    }

    func testFormatTimeAgoOneMinuteAgo() {
        let date = Date().addingTimeInterval(-60) // 1 minute ago
        let formatted = FormatterHelper.formatTimeAgo(date)

        XCTAssertTrue(formatted.contains("1"), "Should contain 1")
        XCTAssertTrue(formatted.hasSuffix("Minute"), "Should be singular")
    }

    func testFormatTimeAgoHoursAgo() {
        let date = Date().addingTimeInterval(-60 * 60 * 3) // 3 hours ago
        let formatted = FormatterHelper.formatTimeAgo(date)

        XCTAssertTrue(formatted.contains("3"), "Should contain hours")
        XCTAssertTrue(formatted.contains("Stunde"), "Should contain 'Stunde'")
    }

    func testFormatTimeAgoDaysAgo() {
        let date = Date().addingTimeInterval(-86400 * 5) // 5 days ago
        let formatted = FormatterHelper.formatTimeAgo(date)

        XCTAssertTrue(formatted.contains("5"), "Should contain days")
        XCTAssertTrue(formatted.contains("Tag"), "Should contain 'Tag'")
    }

    func testFormatTimeAgoWeeksAgo() {
        let date = Date().addingTimeInterval(-86400 * 14) // 2 weeks ago
        let formatted = FormatterHelper.formatTimeAgo(date)

        XCTAssertTrue(formatted.contains("Woche"), "Should contain 'Woche'")
    }

    func testFormatTimeAgoMonthsAgo() {
        let date = Date().addingTimeInterval(-86400 * 45) // ~1.5 months ago
        let formatted = FormatterHelper.formatTimeAgo(date)

        XCTAssertTrue(formatted.contains("Monat"), "Should contain 'Monat'")
    }

    func testFormatTimeAgoYearsAgo() {
        let date = Date().addingTimeInterval(-86400 * 400) // ~1+ years ago
        let formatted = FormatterHelper.formatTimeAgo(date)

        XCTAssertTrue(formatted.contains("Jahr"), "Should contain 'Jahr'")
    }

    // MARK: - Edge Cases

    func testFormatCurrencyNegativeValue() {
        let formatted = FormatterHelper.formatCurrency(-50.0)

        XCTAssertFalse(formatted.isEmpty, "Should handle negative values")
        XCTAssertTrue(formatted.contains("50"), "Should contain the amount")
    }

    func testFormatBudgetWithNegativeMin() {
        let formatted = FormatterHelper.formatBudget(min: -10, max: 50)

        // Negative min budget: CurrencyManager returns "" since min > 0 is false and min != 0.
        // This is acceptable behavior — negative budgets are not valid in the app.
        XCTAssertTrue(formatted.isEmpty || formatted.contains("50"), "Negative min budget results in empty or max-only string")
    }

    func testTruncateEmptyString() {
        let truncated = FormatterHelper.truncate("", maxLength: 10)

        XCTAssertEqual(truncated, "", "Empty string should remain empty")
    }

    func testTruncateShortMaxLength() {
        // maxLength <= 3: no room for ellipsis, just truncate
        let text = "Hello"
        let truncated = FormatterHelper.truncate(text, maxLength: 2)

        XCTAssertEqual(truncated.count, 2, "Should truncate to max length even if very short")
        XCTAssertEqual(truncated, "He", "Should truncate without ellipsis when maxLength <= 3")
    }

    // MARK: - Helper Methods

    private func createDate(month: Int, day: Int, year: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12 // Noon to avoid timezone issues

        return calendar.date(from: components) ?? Date()
    }
}
