import XCTest
@testable import aiPresentsApp

final class ValidationHelperTests: XCTestCase {

    // MARK: - String Validation Tests

    func testValidateNotEmptyWithValidString() {
        let result = ValidationHelper.validateNotEmpty("Test", fieldName: "Titel")

        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    func testValidateNotEmptyWithEmptyString() {
        let result = ValidationHelper.validateNotEmpty("", fieldName: "Titel")

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Titel darf nicht leer sein")
        XCTAssertEqual(result.errorKey, "empty")
    }

    func testValidateNotEmptyWithWhitespaceString() {
        let result = ValidationHelper.validateNotEmpty("   ", fieldName: "Titel")

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorKey, "empty")
    }

    func testValidateMinLengthWithValidString() {
        let result = ValidationHelper.validateMinLength("Test", minLength: 3, fieldName: "Titel")

        XCTAssertTrue(result.isValid)
    }

    func testValidateMinLengthWithInvalidString() {
        let result = ValidationHelper.validateMinLength("Te", minLength: 3, fieldName: "Titel")

        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
        XCTAssertEqual(result.errorKey, "minLength")
    }

    func testValidateMaxLengthWithValidString() {
        let result = ValidationHelper.validateMaxLength("Test", maxLength: 10, fieldName: "Titel")

        XCTAssertTrue(result.isValid)
    }

    func testValidateMaxLengthWithInvalidString() {
        let result = ValidationHelper.validateMaxLength("This is a very long string", maxLength: 10, fieldName: "Titel")

        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
        XCTAssertEqual(result.errorKey, "maxLength")
    }

    func testValidateURLWithValidURL() {
        let result = ValidationHelper.validateURL("https://example.com")

        XCTAssertTrue(result.isValid)
    }

    func testValidateURLWithEmptyString() {
        let result = ValidationHelper.validateURL("")

        XCTAssertTrue(result.isValid, "Empty URL should be valid (optional field)")
    }

    func testValidateURLWithInvalidURL() {
        // Use a string with spaces that can't form a valid URL
        let result = ValidationHelper.validateURL("not a valid url with spaces")

        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
        XCTAssertEqual(result.errorKey, "invalidURL")
    }

    func testValidateURLWithHTTPURL() {
        let result = ValidationHelper.validateURL("http://example.com")

        XCTAssertTrue(result.isValid)
    }

    func testValidateEmailWithValidEmail() {
        let result = ValidationHelper.validateEmail("test@example.com")

        XCTAssertTrue(result.isValid)
    }

    func testValidateEmailWithEmptyString() {
        let result = ValidationHelper.validateEmail("")

        XCTAssertTrue(result.isValid, "Empty email should be valid (optional field)")
    }

    func testValidateEmailWithInvalidEmail() {
        let result = ValidationHelper.validateEmail("not-an-email")

        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
        XCTAssertEqual(result.errorKey, "invalidEmail")
    }

    func testValidateEmailWithInvalidFormat() {
        let result = ValidationHelper.validateEmail("test@")

        XCTAssertFalse(result.isValid)
    }

    // MARK: - Number Validation Tests

    func testValidateMinValueWithValidValue() {
        let result = ValidationHelper.validateMinValue(10, minValue: 5, fieldName: "Wert")

        XCTAssertTrue(result.isValid)
    }

    func testValidateMinValueWithInvalidValue() {
        let result = ValidationHelper.validateMinValue(3, minValue: 5, fieldName: "Wert")

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorKey, "minValue")
    }

    func testValidateMinValueWithEqualValue() {
        let result = ValidationHelper.validateMinValue(5, minValue: 5, fieldName: "Wert")

        XCTAssertTrue(result.isValid, "Equal to min value should be valid")
    }

    func testValidateMaxValueWithValidValue() {
        let result = ValidationHelper.validateMaxValue(10, maxValue: 15, fieldName: "Wert")

        XCTAssertTrue(result.isValid)
    }

    func testValidateMaxValueWithInvalidValue() {
        let result = ValidationHelper.validateMaxValue(20, maxValue: 15, fieldName: "Wert")

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorKey, "maxValue")
    }

    func testValidateMaxValueWithEqualValue() {
        let result = ValidationHelper.validateMaxValue(15, maxValue: 15, fieldName: "Wert")

        XCTAssertTrue(result.isValid, "Equal to max value should be valid")
    }

    func testValidateBudgetRangeWithValidRange() {
        let result = ValidationHelper.validateBudgetRange(min: 25, max: 50)

        XCTAssertTrue(result.isValid)
    }

    func testValidateBudgetRangeWithEqualValues() {
        let result = ValidationHelper.validateBudgetRange(min: 50, max: 50)

        XCTAssertTrue(result.isValid, "Equal min/max should be valid")
    }

    func testValidateBudgetRangeWithInvalidRange() {
        let result = ValidationHelper.validateBudgetRange(min: 75, max: 50)

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorKey, "budgetRange")
    }

    func testValidateBudgetRangeWithZeroMin() {
        let result = ValidationHelper.validateBudgetRange(min: 0, max: 50)

        XCTAssertTrue(result.isValid, "Zero min should be valid")
    }

    // MARK: - Array Validation Tests

    func testValidateMaxArrayLengthWithValidArray() {
        let result = ValidationHelper.validateMaxArrayLength([1, 2, 3], maxLength: 10, fieldName: "Items")

        XCTAssertTrue(result.isValid)
    }

    func testValidateMaxArrayLengthWithInvalidArray() {
        let result = ValidationHelper.validateMaxArrayLength([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], maxLength: 10, fieldName: "Items")

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorKey, "maxArrayLength")
    }

    func testValidateTagsWithValidTags() {
        let result = ValidationHelper.validateTags(["tag1", "tag2", "tag3"])

        XCTAssertTrue(result.isValid)
    }

    func testValidateTagsWithTooManyTags() {
        let tags = Array(1...11).map { "tag\($0)" }
        let result = ValidationHelper.validateTags(tags)

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorKey, "maxTags")
    }

    func testValidateTagsWithTagTooLong() {
        let tags = ["normal", "a" + String(repeating: "a", count: 30)] // 31 characters
        let result = ValidationHelper.validateTags(tags)

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorKey, "tagTooLong")
    }

    func testValidateTagsWithEmptyArray() {
        let result = ValidationHelper.validateTags([])

        XCTAssertTrue(result.isValid, "Empty tags should be valid")
    }

    // MARK: - Date Validation Tests

    func testValidateNotInPastWithFutureDate() {
        let futureDate = Date().addingTimeInterval(86400) // Tomorrow
        let result = ValidationHelper.validateNotInPast(futureDate, fieldName: "Datum")

        XCTAssertTrue(result.isValid)
    }

    func testValidateNotInPastWithPastDate() {
        let pastDate = Date().addingTimeInterval(-86400) // Yesterday
        let result = ValidationHelper.validateNotInPast(pastDate, fieldName: "Datum")

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorKey, "dateInPast")
    }

    func testValidateMaxFutureDateWithValidDate() {
        let validDate = Date().addingTimeInterval(86400 * 365) // 1 year from now
        let result = ValidationHelper.validateMaxFutureDate(validDate, years: 5, fieldName: "Datum")

        XCTAssertTrue(result.isValid)
    }

    func testValidateMaxFutureDateWithTooFarDate() {
        let farDate = Date().addingTimeInterval(86400 * 365 * 10) // 10 years from now
        let result = ValidationHelper.validateMaxFutureDate(farDate, years: 5, fieldName: "Datum")

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorKey, "dateTooFar")
    }

    func testValidateURLWithProtocolRelative() {
        let result = ValidationHelper.validateURL("//example.com")

        // This may or may not be valid depending on URL parsing
        // The test just verifies it doesn't crash
        XCTAssertNotNil(result)
    }

    func testValidateURLWithoutScheme() {
        // Should now auto-add https://
        let result = ValidationHelper.validateURL("example.com")

        XCTAssertTrue(result.isValid, "URL without scheme should be valid with auto-added https://")
    }

    func testValidateURLWithoutSchemeWithSubdomain() {
        let result = ValidationHelper.validateURL("www.example.com")

        XCTAssertTrue(result.isValid)
    }

    func testNormalizeURL() {
        XCTAssertEqual(ValidationHelper.normalizeURL("example.com"), "https://example.com")
        XCTAssertEqual(ValidationHelper.normalizeURL("http://example.com"), "http://example.com")
        XCTAssertEqual(ValidationHelper.normalizeURL("https://example.com"), "https://example.com")
        XCTAssertEqual(ValidationHelper.normalizeURL(""), "")
        XCTAssertEqual(ValidationHelper.normalizeURL("  "), "")
        XCTAssertEqual(ValidationHelper.normalizeURL("  example.com  "), "https://example.com")
    }

    func testValidateCategoryWithValidCategory() {
        let result = ValidationHelper.validateCategory("Bücher")

        XCTAssertTrue(result.isValid)
    }

    func testValidateCategoryWithEmptyCategory() {
        let result = ValidationHelper.validateCategory("")

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorKey, "empty")
    }

    func testValidateCategoryWithWhitespace() {
        let result = ValidationHelper.validateCategory("   ")

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorKey, "empty")
    }

    func testValidateCategoryWithTooLongCategory() {
        let longCategory = String(repeating: "a", count: 51)
        let result = ValidationHelper.validateCategory(longCategory)

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorKey, "maxLength")
    }

    func testValidateCategoryWithExactlyMaxLength() {
        let category = String(repeating: "a", count: 50)
        let result = ValidationHelper.validateCategory(category)

        XCTAssertTrue(result.isValid)
    }

    func testSanitizeTags() {
        let result = ValidationHelper.sanitizeTags(["tag1", "  tag2  ", "", "tag3", "   "])

        XCTAssertEqual(result, ["tag1", "tag2", "tag3"])
    }

    func testSanitizeTagsWithAllEmpty() {
        let result = ValidationHelper.sanitizeTags(["", "   ", "  "])

        XCTAssertEqual(result, [])
    }

    func testSanitizeTagsWithValidTags() {
        let result = ValidationHelper.sanitizeTags(["tag1", "tag2", "tag3"])

        XCTAssertEqual(result, ["tag1", "tag2", "tag3"])
    }

    func testValidateTagsWithEmptyTagsInArray() {
        // After my changes, empty tags should be filtered out
        let result = ValidationHelper.validateTags(["tag1", "", "  ", "tag2"])

        XCTAssertTrue(result.isValid, "Empty tags should be filtered out")
    }

    func testValidateTagsWithTooManyNonEmptyTags() {
        // Should still fail if there are more than 10 non-empty tags
        let tags = Array(1...11).map { "tag\($0)" }
        let result = ValidationHelper.validateTags(tags)

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorKey, "maxTags")
    }

    func testValidateTagsWithMixedEmptyAndNonEmpty() {
        // 5 valid + 5 empty = should be valid (only non-empty counted)
        let tags = ["tag1", "tag2", "tag3", "tag4", "tag5", "", "", "", "", ""]
        let result = ValidationHelper.validateTags(tags)

        XCTAssertTrue(result.isValid)
    }

    func testValidateGiftIdeaWithValidData() {
        let result = ValidationHelper.validateGiftIdea(
            title: "Test Geschenk",
            budgetMin: 25,
            budgetMax: 50,
            link: "https://example.com",
            tags: ["tag1", "tag2"]
        )

        XCTAssertTrue(result.isValid)
    }

    func testValidateGiftIdeaWithEmptyTitle() {
        let result = ValidationHelper.validateGiftIdea(
            title: "",
            budgetMin: 25,
            budgetMax: 50,
            link: "",
            tags: []
        )

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorKey, "title")
    }

    func testValidateGiftIdeaWithNegativeBudget() {
        let result = ValidationHelper.validateGiftIdea(
            title: "Test",
            budgetMin: -10,
            budgetMax: 50,
            link: "",
            tags: []
        )

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorKey, "budget")
    }

    func testValidateGiftIdeaWithInvalidBudgetRange() {
        let result = ValidationHelper.validateGiftIdea(
            title: "Test",
            budgetMin: 100,
            budgetMax: 50,
            link: "",
            tags: []
        )

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorKey, "budget")
    }

    func testValidateGiftIdeaWithInvalidURL() {
        let result = ValidationHelper.validateGiftIdea(
            title: "Test",
            budgetMin: 0,
            budgetMax: 50,
            link: "not a valid url with spaces",
            tags: []
        )

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorKey, "link")
    }

    func testValidateGiftIdeaWithTooManyTags() {
        let tags = Array(1...11).map { "tag\($0)" }
        let result = ValidationHelper.validateGiftIdea(
            title: "Test",
            budgetMin: 0,
            budgetMax: 50,
            link: "",
            tags: tags
        )

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorKey, "tags")
    }

    func testValidateGiftHistoryWithValidData() {
        let result = ValidationHelper.validateGiftHistory(
            title: "Test Geschenk",
            category: "Bücher",
            year: 2024,
            budget: 50,
            link: "https://example.com"
        )

        XCTAssertTrue(result.isValid)
    }

    func testValidateGiftHistoryWithEmptyTitle() {
        let result = ValidationHelper.validateGiftHistory(
            title: "",
            category: "Bücher",
            year: 2024,
            budget: 50,
            link: ""
        )

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorKey, "title")
    }

    func testValidateGiftHistoryWithEmptyCategory() {
        let result = ValidationHelper.validateGiftHistory(
            title: "Test Geschenk",
            category: "",
            year: 2024,
            budget: 50,
            link: ""
        )

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorKey, "category")
    }

    func testValidateGiftHistoryWithInvalidYearTooOld() {
        let result = ValidationHelper.validateGiftHistory(
            title: "Test",
            category: "Bücher",
            year: 1899,
            budget: 50,
            link: ""
        )

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorKey, "year")
    }

    func testValidateGiftHistoryWithInvalidYearFuture() {
        let currentYear = Calendar.current.component(.year, from: Date())
        let result = ValidationHelper.validateGiftHistory(
            title: "Test",
            category: "Bücher",
            year: currentYear + 1,
            budget: 50,
            link: ""
        )

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorKey, "year")
    }

    func testValidateGiftHistoryWithNegativeBudget() {
        let result = ValidationHelper.validateGiftHistory(
            title: "Test",
            category: "Bücher",
            year: 2024,
            budget: -10,
            link: ""
        )

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorKey, "budget")
    }

    func testValidateGiftHistoryWithInvalidURL() {
        let result = ValidationHelper.validateGiftHistory(
            title: "Test",
            category: "Bücher",
            year: 2024,
            budget: 50,
            link: "not a valid url with spaces"
        )

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorKey, "link")
    }

    // MARK: - Reminder Settings Validation Tests

    func testValidateReminderSettingsWithValidSettings() {
        let result = ValidationHelper.validateReminderSettings(
            leadDays: [30, 14, 7, 2],
            quietHoursStart: 22,
            quietHoursEnd: 8
        )

        XCTAssertTrue(result.isValid)
    }

    func testValidateReminderSettingsWithNoLeadDays() {
        let result = ValidationHelper.validateReminderSettings(
            leadDays: [],
            quietHoursStart: 22,
            quietHoursEnd: 8
        )

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorKey, "noLeadDays")
    }

    func testValidateReminderSettingsWithInvalidQuietHoursStart() {
        let result = ValidationHelper.validateReminderSettings(
            leadDays: [30],
            quietHoursStart: 25,
            quietHoursEnd: 8
        )

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorKey, "quietHoursStart")
    }

    func testValidateReminderSettingsWithInvalidQuietHoursEnd() {
        let result = ValidationHelper.validateReminderSettings(
            leadDays: [30],
            quietHoursStart: 22,
            quietHoursEnd: 25
        )

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorKey, "quietHoursEnd")
    }

    func testValidateReminderSettingsWithNegativeQuietHours() {
        let result = ValidationHelper.validateReminderSettings(
            leadDays: [30],
            quietHoursStart: -1,
            quietHoursEnd: 8
        )

        XCTAssertFalse(result.isValid)
    }

    // MARK: - Edge Cases

    func testValidateEmailWithSubdomains() {
        let result = ValidationHelper.validateEmail("test@sub.example.com")

        XCTAssertTrue(result.isValid)
    }

    func testValidateBudgetRangeWithBothZero() {
        let result = ValidationHelper.validateBudgetRange(min: 0, max: 0)

        XCTAssertTrue(result.isValid, "Both zero should be valid")
    }

    func testValidateTagsWithLongTagExactlyAtLimit() {
        let tags = [String(repeating: "a", count: 30)] // Exactly 30 characters
        let result = ValidationHelper.validateTags(tags)

        XCTAssertTrue(result.isValid, "Tag at max length should be valid")
    }

    func testValidateMaxLengthWithEmptyString() {
        let result = ValidationHelper.validateMaxLength("", maxLength: 10, fieldName: "Test")

        XCTAssertTrue(result.isValid, "Empty string should be valid")
    }
}
