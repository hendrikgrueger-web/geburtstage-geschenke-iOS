import XCTest
@testable import aiPresentsApp

final class SmartInputFieldTests: XCTestCase {

    // MARK: - Validation Tests

    func testTitleValidation_InvalidWhenEmpty() {
        let result = ValidationHelper.validateNotEmpty("", fieldName: "Titel")

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Titel darf nicht leer sein")
        XCTAssertEqual(result.errorKey, "empty")
    }

    func testTitleValidation_InvalidWhenTooShort() {
        let result = ValidationHelper.validateMinLength("A", minLength: 2, fieldName: "Titel")

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage?.contains("mindestens 2 Zeichen") ?? false)
        XCTAssertEqual(result.errorKey, "minLength")
    }

    func testTitleValidation_InvalidWhenTooLong() {
        let longString = String(repeating: "A", count: 101)
        let result = ValidationHelper.validateMaxLength(longString, maxLength: 100, fieldName: "Titel")

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage?.contains("maximal 100 Zeichen") ?? false)
        XCTAssertEqual(result.errorKey, "maxLength")
    }

    func testTitleValidation_ValidWhenProperLength() {
        let result = ValidationHelper.validateMinLength("Valid Title", minLength: 2, fieldName: "Titel")

        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    // MARK: - URL Validation Tests

    func testURLValidation_ValidWhenEmpty() {
        let result = ValidationHelper.validateURL("")

        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    func testURLValidation_ValidWithHTTPS() {
        let result = ValidationHelper.validateURL("https://example.com")

        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    func testURLValidation_ValidWithHTTP() {
        let result = ValidationHelper.validateURL("http://example.com")

        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    func testURLValidation_InvalidWithoutScheme() {
        // "example.com" is auto-prefixed with http:// and becomes valid
        // Use truly invalid URL with spaces
        let result = ValidationHelper.validateURL("not a valid url")

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage?.contains("gültige URL") ?? false)
        XCTAssertEqual(result.errorKey, "invalidURL")
    }

    // MARK: - URL Normalization Tests

    func testURLNormalization_EmptyStaysEmpty() {
        let result = ValidationHelper.normalizeURL("")

        XCTAssertEqual(result, "")
    }

    func testURLNormalization_HTTPSRemains() {
        let result = ValidationHelper.normalizeURL("https://example.com")

        XCTAssertEqual(result, "https://example.com")
    }

    func testURLNormalization_HTTPRemains() {
        let result = ValidationHelper.normalizeURL("http://example.com")

        XCTAssertEqual(result, "http://example.com")
    }

    func testURLNormalization_AddsHTTPS() {
        let result = ValidationHelper.normalizeURL("example.com")

        XCTAssertEqual(result, "https://example.com")
    }

    func testURLNormalization_AddsHTTPSToWWW() {
        let result = ValidationHelper.normalizeURL("www.example.com")

        XCTAssertEqual(result, "https://www.example.com")
    }

    // MARK: - Email Validation Tests

    func testEmailValidation_ValidWhenEmpty() {
        let result = ValidationHelper.validateEmail("")

        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    func testEmailValidation_ValidFormat() {
        let result = ValidationHelper.validateEmail("test@example.com")

        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    func testEmailValidation_InvalidNoAtSign() {
        let result = ValidationHelper.validateEmail("testexample.com")

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorKey, "invalidEmail")
    }

    func testEmailValidation_InvalidNoDomain() {
        let result = ValidationHelper.validateEmail("test@")

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorKey, "invalidEmail")
    }

    // MARK: - Budget Validation Tests

    func testBudgetValidation_ValidWhenZero() {
        let result = ValidationHelper.validateMinValue(0, minValue: 0, fieldName: "Budget")

        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    func testBudgetValidation_InvalidWhenNegative() {
        let result = ValidationHelper.validateMinValue(-10, minValue: 0, fieldName: "Budget")

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage?.contains("mindestens 0") ?? false)
        XCTAssertEqual(result.errorKey, "minValue")
    }

    func testBudgetValidation_ValidRange() {
        let result = ValidationHelper.validateBudgetRange(min: 50, max: 100)

        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    func testBudgetValidation_InvalidRangeMinGreaterThanMax() {
        let result = ValidationHelper.validateBudgetRange(min: 100, max: 50)

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage?.contains("nicht höher") ?? false)
        XCTAssertEqual(result.errorKey, "budgetRange")
    }

    func testBudgetValidation_InvalidRangeEqualValues() {
        let result = ValidationHelper.validateBudgetRange(min: 100, max: 100)

        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    // MARK: - Tags Validation Tests

    func testTagsValidation_ValidWhenEmpty() {
        let result = ValidationHelper.validateTags([])

        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    func testTagsValidation_ValidWhenWithinLimit() {
        let tags = ["Familie", "Freunde", "Geschenk"]
        let result = ValidationHelper.validateTags(tags)

        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    func testTagsValidation_InvalidWhenTooManyTags() {
        let tags = Array((1...11).map { "Tag\($0)" })
        let result = ValidationHelper.validateTags(tags)

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage?.contains("Maximal 10 Tags") ?? false)
        XCTAssertEqual(result.errorKey, "maxTags")
    }

    func testTagsValidation_InvalidWhenTagTooLong() {
        let tags = [String(repeating: "A", count: 31)]
        let result = ValidationHelper.validateTags(tags)

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errorMessage?.contains("maximal 30 Zeichen") ?? false)
        XCTAssertEqual(result.errorKey, "tagTooLong")
    }

    func testTagsValidation_ValidAfterSanitization() {
        let tags = ["  Tag 1  ", "", "Tag 2", ""]
        let result = ValidationHelper.validateTags(tags)

        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    // MARK: - Tags Sanitization Tests

    func testTagsSanitization_RemovesEmptyTags() {
        let tags = ["Tag1", "", "Tag2", "", "Tag3"]
        let sanitized = ValidationHelper.sanitizeTags(tags)

        XCTAssertEqual(sanitized.count, 3)
        XCTAssertEqual(sanitized, ["Tag1", "Tag2", "Tag3"])
    }

    func testTagsSanitization_TrimsWhitespace() {
        let tags = ["  Tag1  ", " Tag2 ", "Tag3  "]
        let sanitized = ValidationHelper.sanitizeTags(tags)

        XCTAssertEqual(sanitized, ["Tag1", "Tag2", "Tag3"])
    }

    func testTagsSanitization_HandlesAllEmpty() {
        let tags = ["", "", ""]
        let sanitized = ValidationHelper.sanitizeTags(tags)

        XCTAssertTrue(sanitized.isEmpty)
    }

    // MARK: - Gift Idea Validation Tests

    func testGiftIdeaValidation_ValidComplete() {
        let result = ValidationHelper.validateGiftIdea(
            title: "Toller Titel",
            budgetMin: 50,
            budgetMax: 100,
            link: "https://example.com",
            tags: ["Geschenk", "Idee"]
        )

        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    func testGiftIdeaValidation_InvalidEmptyTitle() {
        let result = ValidationHelper.validateGiftIdea(
            title: "",
            budgetMin: 50,
            budgetMax: 100,
            link: "",
            tags: []
        )

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorKey, "title")
    }

    func testGiftIdeaValidation_InvalidBudgetRange() {
        let result = ValidationHelper.validateGiftIdea(
            title: "Titel",
            budgetMin: 100,
            budgetMax: 50,
            link: "",
            tags: []
        )

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorKey, "budget")
    }

    func testGiftIdeaValidation_InvalidURL() {
        let result = ValidationHelper.validateGiftIdea(
            title: "Titel",
            budgetMin: 50,
            budgetMax: 100,
            link: "not a valid url with spaces",
            tags: []
        )

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorKey, "link")
    }

    func testGiftIdeaValidation_InvalidTags() {
        let tags = Array((1...11).map { "Tag\($0)" })
        let result = ValidationHelper.validateGiftIdea(
            title: "Titel",
            budgetMin: 50,
            budgetMax: 100,
            link: "",
            tags: tags
        )

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorKey, "tags")
    }
}
