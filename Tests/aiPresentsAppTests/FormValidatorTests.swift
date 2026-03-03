import XCTest
@testable import aiPresentsApp

@MainActor
final class FormValidatorTests: XCTestCase {

    // MARK: - Budget Validation Tests

    func testValidateBudgetBothEmpty() {
        let error = FormValidator.validateBudget(minString: "", maxString: "")
        XCTAssertNil(error, "Both empty should be valid")
    }

    func testValidateBudgetValidRange() {
        let error = FormValidator.validateBudget(minString: "10", maxString: "50")
        XCTAssertNil(error, "Valid range should not error")
    }

    func testValidateBudgetMaxLessThanMin() {
        let error = FormValidator.validateBudget(minString: "50", maxString: "10")
        XCTAssertEqual(error, .budgetMinMaxMismatch, "Max < Min should error")
    }

    func testValidateBudgetMinZero() {
        let error = FormValidator.validateBudget(minString: "0", maxString: "50")
        XCTAssertNil(error, "Min = 0 should be valid")
    }

    func testValidateBudgetNegativeMin() {
        let error = FormValidator.validateBudget(minString: "-10", maxString: "50")
        XCTAssertEqual(error, .invalidBudget, "Negative values should error")
    }

    func testValidateBudgetNegativeMax() {
        let error = FormValidator.validateBudget(minString: "10", maxString: "-5")
        XCTAssertEqual(error, .invalidBudget, "Negative values should error")
    }

    func testValidateBudgetInvalidFormat() {
        let error = FormValidator.validateBudget(minString: "abc", maxString: "50")
        XCTAssertEqual(error, .invalidBudget, "Invalid format should error")
    }

    func testValidateBudgetOnlyMinFilled() {
        let error = FormValidator.validateBudget(minString: "25", maxString: "")
        XCTAssertNil(error, "Only min filled should be valid")
    }

    func testValidateBudgetOnlyMaxFilled() {
        let error = FormValidator.validateBudget(minString: "", maxString: "100")
        XCTAssertNil(error, "Only max filled should be valid")
    }

    // MARK: - Required Field Validation Tests

    func testValidateRequiredNonEmpty() {
        let error = FormValidator.validateRequired("Test Value", fieldName: "Name")
        XCTAssertNil(error, "Non-empty field should be valid")
    }

    func testValidateRequiredEmpty() {
        let error = FormValidator.validateRequired("", fieldName: "Name")
        XCTAssertEqual(error, .emptyField("Name"), "Empty field should error")
    }

    func testValidateRequiredWhitespaceOnly() {
        let error = FormValidator.validateRequired("   ", fieldName: "Name")
        XCTAssertEqual(error, .emptyField("Name"), "Whitespace-only should error")
    }

    // MARK: - Title Validation Tests

    func testValidateTitleValid() {
        let error = FormValidator.validateTitle("Valid Title")
        XCTAssertNil(error, "Valid title should not error")
    }

    func testValidateTitleEmpty() {
        let error = FormValidator.validateTitle("")
        XCTAssertEqual(error, .emptyField("Titel"), "Empty title should error")
    }

    func testValidateTitleTooLong() {
        let longTitle = String(repeating: "a", count: 101)
        let error = FormValidator.validateTitle(longTitle)
        XCTAssertEqual(error, .tooLong(maxLength: 100), "Title > 100 chars should error")
    }

    func testValidateTitleMaxLength() {
        let title = String(repeating: "a", count: 100)
        let error = FormValidator.validateTitle(title)
        XCTAssertNil(error, "Title = 100 chars should be valid")
    }

    // MARK: - Note Validation Tests

    func testValidateNoteValid() {
        let error = FormValidator.validateNote("Valid note")
        XCTAssertNil(error, "Valid note should not error")
    }

    func testValidateNoteTooLong() {
        let longNote = String(repeating: "a", count: 501)
        let error = FormValidator.validateNote(longNote)
        XCTAssertEqual(error, .tooLong(maxLength: 500), "Note > 500 chars should error")
    }

    func testValidateNoteMaxLength() {
        let note = String(repeating: "a", count: 500)
        let error = FormValidator.validateNote(note)
        XCTAssertNil(error, "Note = 500 chars should be valid")
    }

    func testValidateNoteEmpty() {
        let error = FormValidator.validateNote("")
        XCTAssertNil(error, "Empty note should be valid")
    }

    // MARK: - URL Validation Tests

    func testValidateURLEmpty() {
        let error = FormValidator.validateURL("")
        XCTAssertNil(error, "Empty URL should be valid")
    }

    func testValidateURLValid() {
        let error = FormValidator.validateURL("https://example.com")
        XCTAssertNil(error, "Valid HTTPS URL should be valid")
    }

    func testValidateURLInvalid() {
        let error = FormValidator.validateURL("not a valid url with spaces")
        XCTAssertEqual(error, .invalidURL, "Invalid URL should error")
    }

    func testValidateURLWithoutScheme() {
        let error = FormValidator.validateURL("example.com")
        XCTAssertNil(error, "URL without scheme should be valid (adds https://)")
    }

    // MARK: - Tags Validation Tests

    func testValidateTagsValid() {
        let error = FormValidator.validateTags("tech,books,home")
        XCTAssertNil(error, "Valid tags should not error")
    }

    func testValidateTagsEmpty() {
        let error = FormValidator.validateTags("")
        XCTAssertNil(error, "Empty tags should be valid")
    }

    func testValidateTagsTooMany() {
        let manyTags = (1...11).map { "tag\($0)" }.joined(separator: ",")
        let error = FormValidator.validateTags(manyTags)
        XCTAssertEqual(error, .tooLong(maxLength: 10), "More than 10 tags should error")
    }

    func testValidateTagsTagTooLong() {
        let longTag = String(repeating: "a", count: 31)
        let error = FormValidator.validateTags(longTag)
        XCTAssertEqual(error, .tooLong(maxLength: 30), "Tag > 30 chars should error")
    }

    func testValidateTagsWithWhitespace() {
        let error = FormValidator.validateTags("  tech ,  books ,  home  ")
        XCTAssertNil(error, "Tags with whitespace should be valid")
    }

    func testValidateTagsEmptyTagsInMiddle() {
        let error = FormValidator.validateTags("tech,,books")
        XCTAssertNil(error, "Empty tags in middle should be filtered out")
    }

    // MARK: - Category Validation Tests

    func testValidateCategoryValid() {
        let error = FormValidator.validateCategory("Books")
        XCTAssertNil(error, "Valid category should not error")
    }

    func testValidateCategoryEmpty() {
        let error = FormValidator.validateCategory("")
        XCTAssertEqual(error, .emptyField("Kategorie"), "Empty category should return emptyField error")
    }

    func testValidateCategoryWhitespace() {
        let error = FormValidator.validateCategory("   ")
        XCTAssertEqual(error, .emptyField("Kategorie"), "Whitespace-only category should return emptyField error")
    }

    func testValidateCategoryTooLong() {
        let longCategory = String(repeating: "a", count: 51)
        let error = FormValidator.validateCategory(longCategory)
        XCTAssertEqual(error, .tooLong(maxLength: 50), "Category > 50 chars should error")
    }

    func testValidateCategoryMaxLength() {
        let category = String(repeating: "a", count: 50)
        let error = FormValidator.validateCategory(category)
        XCTAssertNil(error, "Category = 50 chars should be valid")
    }

    // MARK: - ValidationError Description Tests

    func testValidationErrorDescriptions() {
        XCTAssertEqual(ValidationError.emptyField("Test").errorDescription, "Test darf nicht leer sein")
        XCTAssertEqual(ValidationError.invalidBudget.errorDescription, "Bitte gib eine gültige Zahl ein")
        XCTAssertEqual(ValidationError.budgetMinMaxMismatch.errorDescription, "Maximalbetrag muss größer als Minimalbetrag sein")
        XCTAssertEqual(ValidationError.invalidURL.errorDescription, "Bitte gib eine gültige URL ein")
        XCTAssertEqual(ValidationError.tooShort(minLength: 5).errorDescription, "Mindestens 5 Zeichen erforderlich")
        XCTAssertEqual(ValidationError.tooLong(maxLength: 100).errorDescription, "Maximal 100 Zeichen erlaubt")
    }

    // MARK: - FormState Tests

    func testFormStateInitial() {
        let formState = AppFormState()
        XCTAssertFalse(formState.hasErrors(), "Initial state should have no errors")
        XCTAssertTrue(formState.isValid, "Initial state should be valid")
        XCTAssertNil(formState.error(for: "field"), "Initial error should be nil")
    }

    func testFormStateSetError() {
        let formState = AppFormState()
        formState.setError(.emptyField("Test"), for: "title")
        XCTAssertTrue(formState.hasErrors(), "Should have errors after setting one")
        XCTAssertFalse(formState.isValid, "Should be invalid after error")
        XCTAssertNotNil(formState.error(for: "title"), "Error should be retrievable")
        XCTAssertEqual(formState.error(for: "title"), .emptyField("Test"))
    }

    func testFormStateClearError() {
        let formState = AppFormState()
        formState.setError(.emptyField("Test"), for: "title")
        formState.clearError(for: "title")
        XCTAssertFalse(formState.hasErrors(), "Should have no errors after clearing")
        XCTAssertTrue(formState.isValid, "Should be valid after clearing")
        XCTAssertNil(formState.error(for: "title"), "Error should be nil after clearing")
    }

    func testFormStateClearAllErrors() {
        let formState = AppFormState()
        formState.setError(.emptyField("Test1"), for: "title")
        formState.setError(.invalidURL, for: "link")
        formState.clearAllErrors()
        XCTAssertFalse(formState.hasErrors(), "Should have no errors after clearing all")
        XCTAssertTrue(formState.isValid, "Should be valid after clearing all")
    }

    func testFormStateMultipleErrors() {
        let formState = AppFormState()
        formState.setError(.emptyField("Test1"), for: "title")
        formState.setError(.invalidURL, for: "link")
        formState.setError(.budgetMinMaxMismatch, for: "budget")
        XCTAssertTrue(formState.hasErrors(), "Should have errors")
        XCTAssertEqual(formState.errors.count, 3, "Should have 3 errors")
        XCTAssertFalse(formState.isValid, "Should be invalid")
    }
}
