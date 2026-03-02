import XCTest
@testable import aiPresentsApp

final class AccessibilityConfigurationTests: XCTestCase {

    // MARK: - Format Number Tests

    func testFormatNumber() {
        let result = AccessibilityConfiguration.formatNumber(5, unit: "Euro")
        XCTAssertEqual(result, "5 Euro")
    }

    func testFormatNumberWithoutUnit() {
        let result = AccessibilityConfiguration.formatNumber(10)
        XCTAssertEqual(result, "10")
    }

    func testFormatNumberZero() {
        let result = AccessibilityConfiguration.formatNumber(0, unit: "Items")
        XCTAssertEqual(result, "0 Items")
    }

    // MARK: - Format Date Tests

    func testFormatDate() {
        let date = Date(timeIntervalSince1970: 0) // 1970-01-01
        let result = AccessibilityConfiguration.formatDate(date, style: .medium)
        XCTAssertFalse(result.isEmpty, "Formatted date should not be empty")
    }

    func testFormatDateShort() {
        let date = Date()
        let result = AccessibilityConfiguration.formatDate(date, style: .short)
        XCTAssertFalse(result.isEmpty, "Short formatted date should not be empty")
    }

    // MARK: - Format Duration Tests

    func testFormatDurationSeconds() {
        let result = AccessibilityConfiguration.formatDuration(30)
        XCTAssertEqual(result, "30 Sekunden")
    }

    func testFormatDurationOneSecond() {
        let result = AccessibilityConfiguration.formatDuration(1)
        XCTAssertEqual(result, "1 Sekunden")
    }

    func testFormatDurationMinutes() {
        let result = AccessibilityConfiguration.formatDuration(120)
        XCTAssertEqual(result, "2 Minuten")
    }

    func testFormatDurationOneMinute() {
        let result = AccessibilityConfiguration.formatDuration(60)
        XCTAssertEqual(result, "1 Minute")
    }

    func testFormatDurationHours() {
        let result = AccessibilityConfiguration.formatDuration(7200)
        XCTAssertEqual(result, "2 Stunden")
    }

    func testFormatDurationOneHour() {
        let result = AccessibilityConfiguration.formatDuration(3600)
        XCTAssertEqual(result, "1 Stunde")
    }

    func testFormatDurationHoursAndMinutes() {
        let result = AccessibilityConfiguration.formatDuration(5400)
        XCTAssertEqual(result, "1 Stunde 30 Minuten")
    }

    // MARK: - Button Traits Tests

    func testButtonTraitsEnabled() {
        let traits = AccessibilityConfiguration.buttonTraits(isEnabled: true)
        XCTAssertTrue(traits.contains(.isButton))
        XCTAssertFalse(traits.contains(.isNotEnabled))
    }

    func testButtonTraitsDisabled() {
        let traits = AccessibilityConfiguration.buttonTraits(isEnabled: false)
        XCTAssertTrue(traits.contains(.isButton))
        XCTAssertTrue(traits.contains(.isNotEnabled))
    }

    // MARK: - Selectable Traits Tests

    func testSelectableTraitsSelected() {
        let traits = AccessibilityConfiguration.selectableTraits(isSelected: true)
        XCTAssertTrue(traits.contains(.isButton))
        XCTAssertTrue(traits.contains(.isSelected))
    }

    func testSelectableTraitsNotSelected() {
        let traits = AccessibilityConfiguration.selectableTraits(isSelected: false)
        XCTAssertTrue(traits.contains(.isButton))
        XCTAssertFalse(traits.contains(.isSelected))
    }

    // MARK: - Navigation Hint Tests

    func testNavigationHint() {
        let hint = AccessibilityConfiguration.navigationHint(destination: "Einstellungen")
        XCTAssertEqual(hint, "Navigiert zu Einstellungen")
    }

    // MARK: - Action Hint Tests

    func testActionHint() {
        let hint = AccessibilityConfiguration.actionHint("Speichern")
        XCTAssertEqual(hint, "Doppeltippen für Speichern")
    }

    // MARK: - Relative Date Description Tests

    func testRelativeDateDescriptionToday() {
        let today = Date()
        let result = AccessibilityConfiguration.relativeDateDescription(from: today, reference: today)
        XCTAssertEqual(result, "Heute")
    }

    func testRelativeDateDescriptionTomorrow() {
        let reference = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: reference)!
        let result = AccessibilityConfiguration.relativeDateDescription(from: tomorrow, reference: reference)
        XCTAssertEqual(result, "Morgen")
    }

    func testRelativeDateDescriptionYesterday() {
        let reference = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: reference)!
        let result = AccessibilityConfiguration.relativeDateDescription(from: yesterday, reference: reference)
        XCTAssertEqual(result, "Gestern")
    }

    func testRelativeDateDescriptionFuture() {
        let reference = Date()
        let future = Calendar.current.date(byAdding: .day, value: 5, to: reference)!
        let result = AccessibilityConfiguration.relativeDateDescription(from: future, reference: reference)
        XCTAssertEqual(result, "In 5 Tagen")
    }

    func testRelativeDateDescriptionPast() {
        let reference = Date()
        let past = Calendar.current.date(byAdding: .day, value: -10, to: reference)!
        let result = AccessibilityConfiguration.relativeDateDescription(from: past, reference: reference)
        XCTAssertEqual(result, "vor 10 Tagen")
    }
}
