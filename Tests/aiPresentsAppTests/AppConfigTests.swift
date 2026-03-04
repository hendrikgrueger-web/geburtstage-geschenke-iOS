import XCTest
@testable import aiPresentsApp

final class AppConfigTests: XCTestCase {

    // MARK: - Build Tests

    func testIsDebugBuild() {
        // Note: This test will pass only in DEBUG builds
        #if DEBUG
        XCTAssertTrue(AppConfig.isDebugBuild, "Should be debug build when compiled with DEBUG flag")
        #else
        XCTAssertFalse(AppConfig.isDebugBuild, "Should not be debug build in release")
        #endif
    }

    // MARK: - Version Tests

    func testAppVersionIsNotEmpty() {
        XCTAssertFalse(AppConfig.appVersion.isEmpty, "App version should not be empty")
    }

    func testBuildNumberIsNotEmpty() {
        XCTAssertFalse(AppConfig.buildNumber.isEmpty, "Build number should not be empty")
    }

    func testVersionStringIsFormatted() {
        let versionString = AppConfig.versionString

        XCTAssertTrue(versionString.contains("("), "Version string should contain opening parenthesis")
        XCTAssertTrue(versionString.contains(")"), "Version string should contain closing parenthesis")
    }

    // MARK: - OpenRouter Configuration Tests

    func testOpenRouterConfiguration() {
        // This is a configuration flag - should be false by default
        XCTAssertNotNil(AppConfig.isOpenRouterConfigured, "OpenRouter configuration should be defined")
    }

    // MARK: - Budget Constants Tests

    func testBudgetSliderMinimum() {
        XCTAssertEqual(AppConfig.Budget.sliderMinimum, 0, "Budget slider minimum should be 0")
    }

    func testBudgetSliderMaximum() {
        XCTAssertEqual(AppConfig.Budget.sliderMaximum, 500, "Budget slider maximum should be 500")
    }

    func testBudgetSliderStep() {
        XCTAssertEqual(AppConfig.Budget.sliderStep, 5, "Budget slider step should be 5")
    }

    // MARK: - Timeline Constants Tests

    func testTimelineDefaultUpcomingDays() {
        XCTAssertEqual(AppConfig.Timeline.defaultUpcomingDays, 30, "Default upcoming days should be 30")
    }

    func testTimelineTodayDays() {
        XCTAssertEqual(AppConfig.Timeline.todayDays, 0, "Today days should be 0")
    }

    func testTimelineWeekDays() {
        XCTAssertEqual(AppConfig.Timeline.weekDays, 7, "Week days should be 7")
    }

    func testTimelineMonthDays() {
        XCTAssertEqual(AppConfig.Timeline.monthDays, 30, "Month days should be 30")
    }

    // MARK: - Reminder Constants Tests

    func testReminderDefaultLeadDays() {
        XCTAssertEqual(AppConfig.Reminder.defaultLeadDays, [30, 14, 7, 2], "Default lead days should match expected values")
    }

    func testReminderDefaultLeadDaysContainsExpectedValues() {
        XCTAssertTrue(AppConfig.Reminder.defaultLeadDays.contains(30), "Should contain 30 days")
        XCTAssertTrue(AppConfig.Reminder.defaultLeadDays.contains(14), "Should contain 14 days")
        XCTAssertTrue(AppConfig.Reminder.defaultLeadDays.contains(7), "Should contain 7 days")
        XCTAssertTrue(AppConfig.Reminder.defaultLeadDays.contains(2), "Should contain 2 days")
    }

    func testReminderDefaultQuietHoursStart() {
        XCTAssertEqual(AppConfig.Reminder.defaultQuietHoursStart, 22, "Quiet hours start should be 22 (10 PM)")
    }

    func testReminderDefaultQuietHoursEnd() {
        XCTAssertEqual(AppConfig.Reminder.defaultQuietHoursEnd, 8, "Quiet hours end should be 8 (8 AM)")
    }

    // MARK: - Limits Constants Tests

    func testLimitsMaxTitleLength() {
        XCTAssertEqual(AppConfig.Limits.maxTitleLength, 100, "Max title length should be 100")
    }

    func testLimitsMaxNoteLength() {
        XCTAssertEqual(AppConfig.Limits.maxNoteLength, 500, "Max note length should be 500")
    }

    func testLimitsMaxTags() {
        XCTAssertEqual(AppConfig.Limits.maxTags, 10, "Max tags should be 10")
    }

    func testLimitsMaxTagLength() {
        XCTAssertEqual(AppConfig.Limits.maxTagLength, 30, "Max tag length should be 30")
    }

    func testLimitsMaxCategoryLength() {
        XCTAssertEqual(AppConfig.Limits.maxCategoryLength, 50, "Max category length should be 50")
    }

    // MARK: - Edge Cases and Validation

    func testTimelineDaysAreNonNegative() {
        XCTAssertGreaterThanOrEqual(AppConfig.Timeline.todayDays, 0, "Today days should be non-negative")
        XCTAssertGreaterThanOrEqual(AppConfig.Timeline.weekDays, 0, "Week days should be non-negative")
        XCTAssertGreaterThanOrEqual(AppConfig.Timeline.monthDays, 0, "Month days should be non-negative")
        XCTAssertGreaterThanOrEqual(AppConfig.Timeline.defaultUpcomingDays, 0, "Default upcoming days should be non-negative")
    }

    func testReminderLeadDaysAreValidDays() {
        for days in AppConfig.Reminder.defaultLeadDays {
            XCTAssertGreaterThan(days, 0, "Lead days should be positive: \(days)")
        }
    }

    func testQuietHoursAreValidHourRange() {
        XCTAssertGreaterThanOrEqual(AppConfig.Reminder.defaultQuietHoursStart, 0, "Quiet hours start should be valid hour")
        XCTAssertLessThanOrEqual(AppConfig.Reminder.defaultQuietHoursStart, 23, "Quiet hours start should be valid hour")

        XCTAssertGreaterThanOrEqual(AppConfig.Reminder.defaultQuietHoursEnd, 0, "Quiet hours end should be valid hour")
        XCTAssertLessThanOrEqual(AppConfig.Reminder.defaultQuietHoursEnd, 23, "Quiet hours end should be valid hour")
    }

    func testBudgetSliderRangeIsValid() {
        XCTAssertLessThan(AppConfig.Budget.sliderMinimum, AppConfig.Budget.sliderMaximum, "Slider minimum should be less than maximum")
        XCTAssertGreaterThan(AppConfig.Budget.sliderStep, 0, "Slider step should be positive")
    }

    func testLimitsArePositive() {
        XCTAssertGreaterThan(AppConfig.Limits.maxTitleLength, 0, "Max title length should be positive")
        XCTAssertGreaterThan(AppConfig.Limits.maxNoteLength, 0, "Max note length should be positive")
        XCTAssertGreaterThan(AppConfig.Limits.maxTags, 0, "Max tags should be positive")
        XCTAssertGreaterThan(AppConfig.Limits.maxTagLength, 0, "Max tag length should be positive")
        XCTAssertGreaterThan(AppConfig.Limits.maxCategoryLength, 0, "Max category length should be positive")
    }

    // MARK: - Constants Consistency Tests

    func testWeekDaysIsSeven() {
        XCTAssertEqual(AppConfig.Timeline.weekDays, 7, "A week should have exactly 7 days")
    }

    func testMonthDaysIsApproximatelyThirty() {
        XCTAssertEqual(AppConfig.Timeline.monthDays, 30, "Month days should be approximately 30")
    }

    func testDefaultUpcomingDaysMatchesMonthDays() {
        XCTAssertEqual(AppConfig.Timeline.defaultUpcomingDays, AppConfig.Timeline.monthDays, "Default upcoming should match month days")
    }

    // MARK: - Version Format Tests

    func testAppVersionFormat() {
        // Version should be in format X.Y.Z (semantic versioning)
        let version = AppConfig.appVersion
        let components = version.split(separator: ".")

        XCTAssertGreaterThanOrEqual(components.count, 2, "Version should have at least major.minor format")
        XCTAssertLessThanOrEqual(components.count, 3, "Version should have at most major.minor.patch format")
    }

    func testBuildNumberFormat() {
        // Build number should be a valid integer string
        let buildNumber = AppConfig.buildNumber

        XCTAssertTrue(Int(buildNumber) != nil || buildNumber.isEmpty, "Build number should be a valid integer or empty")
    }
}
