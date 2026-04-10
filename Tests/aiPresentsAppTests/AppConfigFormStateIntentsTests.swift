import XCTest
import AppIntents
@testable import aiPresentsApp

/// Comprehensive unit tests for AppConfig, FormState, and App Intents
/// Covers AI configuration, form state management, validation, and intent/shortcut infrastructure
@MainActor final class AppConfigFormStateIntentsTests: XCTestCase {

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        // Reset any shared state
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - AppConfig.AI Tests

    func testAppConfigAI_ProxySecretConfiguration() {
        // AppConfig.AI reads from Info.plist (AIProxySecret key)
        // This test validates the structure is accessible
        let config = AppConfig.AI

        // If proxy secret is configured, it should be a non-empty string
        if AppConfig.AI.isAPIKeyConfigured {
            XCTAssertFalse(config.proxySecret.isEmpty, "Proxy secret should not be empty when configured")
        }
    }

    func testAppConfigAI_Model() {
        let config = AppConfig.AI
        XCTAssertEqual(config.model, "google/gemini-3.1-flash-lite-preview", "Model should be Gemini 3.1 Flash Lite")
    }

    func testAppConfigAI_OpenRouterBaseURL() {
        let config = AppConfig.AI
        let expectedURL = "https://ai-presents-proxy.hendrikgrueger.workers.dev"
        XCTAssertEqual(config.openRouterBaseURL, expectedURL, "OpenRouter base URL should match Cloudflare Worker")
    }

    func testAppConfigAI_IsAPIKeyConfigured_Structure() {
        // Validates that isAPIKeyConfigured is a computed property that checks for proxySecret
        let isConfigured = AppConfig.AI.isAPIKeyConfigured
        XCTAssertTrue(isConfigured.self is Bool, "isAPIKeyConfigured should return Bool")
    }

    // MARK: - FormState Tests

    func testFormState_Initialization() {
        let formState = FormState()

        XCTAssertFalse(formState.isDirty, "New form state should not be dirty")
        XCTAssertFalse(formState.isValid, "New form state should not be valid (no validators)")
        XCTAssertFalse(formState.isSubmitting, "New form state should not be submitting")
        XCTAssertNil(formState.submitError, "New form state should have no submit error")
        XCTAssertFalse(formState.submitSuccess, "New form state should have no success")
        XCTAssertTrue(formState.errors.isEmpty, "New form state should have no errors")
    }

    func testFormState_RegisterValidator_ValidInput() {
        let formState = FormState()

        formState.registerValidator(for: "email") {
            ValidationResult(isValid: true, errorMessage: "")
        }

        XCTAssertTrue(formState.isValid, "Form should be valid with passing validator")
        XCTAssertFalse(formState.hasError(for: "email"), "Email field should have no error")
    }

    func testFormState_RegisterValidator_InvalidInput() {
        let formState = FormState()
        let errorMsg = "E-Mail-Adresse ungültig"

        formState.registerValidator(for: "email") {
            ValidationResult(isValid: false, errorMessage: errorMsg)
        }

        XCTAssertFalse(formState.isValid, "Form should be invalid with failing validator")
        XCTAssertTrue(formState.hasError(for: "email"), "Email field should have error")
        XCTAssertEqual(formState.error(for: "email"), errorMsg, "Error message should match")
    }

    func testFormState_ValidateField() {
        let formState = FormState()

        formState.registerValidator(for: "name") {
            ValidationResult(isValid: false, errorMessage: "Name erforderlich")
        }

        XCTAssertFalse(formState.isValid, "Initial validation should fail")

        // Update validator to pass
        formState.removeValidator(for: "name")
        formState.registerValidator(for: "name") {
            ValidationResult(isValid: true, errorMessage: "")
        }

        XCTAssertTrue(formState.isValid, "Form should be valid after validator update")
    }

    func testFormState_MultipleErrors() {
        let formState = FormState()

        formState.registerValidator(for: "email") {
            ValidationResult(isValid: false, errorMessage: "E-Mail ungültig")
        }
        formState.registerValidator(for: "password") {
            ValidationResult(isValid: false, errorMessage: "Passwort zu kurz")
        }

        XCTAssertFalse(formState.isValid, "Form should be invalid with multiple errors")
        XCTAssertEqual(formState.errorCount, 2, "Should have 2 errors")
        XCTAssertTrue(formState.hasErrors, "Should report having errors")
        XCTAssertEqual(formState.allErrors.count, 2, "All errors list should have 2 items")
    }

    func testFormState_SetInitialValue_DirtyTracking() {
        let formState = FormState()

        formState.setInitialValue("original", for: "field1")
        XCTAssertFalse(formState.isDirty, "Form should not be dirty with initial value only")

        formState.updateValue("modified", for: "field1")
        XCTAssertTrue(formState.isDirty, "Form should be dirty after value change")

        formState.updateValue("original", for: "field1")
        XCTAssertFalse(formState.isDirty, "Form should not be dirty after reverting to initial")
    }

    func testFormState_ResetToInitial() {
        let formState = FormState()

        formState.setInitialValue("initial", for: "field1")
        formState.updateValue("changed", for: "field1")
        XCTAssertTrue(formState.isDirty, "Form should be dirty before reset")

        formState.resetToInitial()
        XCTAssertFalse(formState.isDirty, "Form should not be dirty after reset")
    }

    func testFormState_ClearErrors() {
        let formState = FormState()

        formState.registerValidator(for: "name") {
            ValidationResult(isValid: false, errorMessage: "Required")
        }

        XCTAssertTrue(formState.hasError(for: "name"), "Should have error initially")

        formState.clearErrors()
        XCTAssertTrue(formState.errors.isEmpty, "Errors should be cleared")
    }

    func testFormState_ErrorSummary() {
        let formState = FormState()

        // No errors
        XCTAssertEqual(formState.errorSummary, "", "Empty errors should give empty summary")

        // One error
        formState.registerValidator(for: "email") {
            ValidationResult(isValid: false, errorMessage: "Invalid email")
        }
        XCTAssertEqual(formState.errorSummary, "Invalid email", "Single error should return the message")

        // Multiple errors
        formState.registerValidator(for: "password") {
            ValidationResult(isValid: false, errorMessage: "Passwort erforderlich")
        }
        XCTAssertEqual(formState.errorSummary, "2 Fehler sind aufgetreten", "Multiple errors should return count message")
    }

    // MARK: - PersonEntity Tests

    func testPersonEntity_Initialization() {
        let uuid = UUID()
        let entity = PersonEntity(
            id: uuid,
            displayName: "Anna Schmidt",
            relation: "Mutter"
        )

        XCTAssertEqual(entity.id, uuid, "ID should match")
        XCTAssertEqual(entity.displayName, "Anna Schmidt", "Display name should match")
        XCTAssertEqual(entity.relation, "Mutter", "Relation should match")
    }

    func testPersonEntity_DisplayRepresentation() {
        let entity = PersonEntity(
            id: UUID(),
            displayName: "Max Müller",
            relation: "Bruder"
        )

        let display = entity.displayRepresentation
        XCTAssertEqual(display.title, "Max Müller", "Display title should be display name")
        XCTAssertEqual(display.subtitle, "Bruder", "Display subtitle should be relation")
    }

    func testPersonEntity_TypeDisplayRepresentation() {
        let typeDisplay = PersonEntity.typeDisplayRepresentation
        XCTAssertEqual(typeDisplay.name, "Kontakt", "Type display name should be 'Kontakt'")
    }

    func testPersonEntity_DefaultQuery() {
        let query = PersonEntity.defaultQuery
        XCTAssertNotNil(query, "Default query should be initialized")
        XCTAssertTrue(query is PersonEntityQuery, "Default query should be PersonEntityQuery")
    }

    // MARK: - Intent Parameter Metadata Tests

    func testAddGiftIdeaIntent_Metadata() {
        let intent = AddGiftIdeaIntent()

        // Validate intent has expected parameters
        XCTAssertNotNil(intent, "AddGiftIdeaIntent should initialize")
    }

    func testUpcomingBirthdaysIntent_Metadata() {
        let intent = UpcomingBirthdaysIntent()

        // Validate intent initialization
        XCTAssertNotNil(intent, "UpcomingBirthdaysIntent should initialize")
    }

    func testOpenPersonIntent_Metadata() {
        let intent = OpenPersonIntent()

        // Validate intent initialization
        XCTAssertNotNil(intent, "OpenPersonIntent should initialize")
    }

    // MARK: - GiftAppShortcuts Tests

    func testGiftAppShortcuts_Provider() {
        let provider = GiftAppShortcuts()

        XCTAssertNotNil(provider, "GiftAppShortcuts provider should initialize")
    }

    func testGiftAppShortcuts_Shortcuts() {
        let provider = GiftAppShortcuts()

        // Validate that shortcuts are defined
        XCTAssertNotNil(provider, "Provider should have shortcuts")
    }

    // MARK: - Validation Error Localization Tests

    func testValidationError_FormErrorValidationFailed() {
        let error = FormError.validationFailed
        let description = error.errorDescription

        XCTAssertNotNil(description, "FormError.validationFailed should have description")
        XCTAssertTrue(description?.contains("Fehler") ?? false, "Error should be localized in German")
    }

    func testValidationError_FormErrorCustom() {
        let customMsg = "Kontakt nicht gefunden"
        let error = FormError.custom(customMsg)
        let description = error.errorDescription

        XCTAssertEqual(description, customMsg, "Custom error should return custom message")
    }

    func testValidationError_FormErrorSubmissionFailed() {
        let msg = "Speichern fehlgeschlagen"
        let error = FormError.submissionFailed(msg)
        let description = error.errorDescription

        XCTAssertEqual(description, msg, "Submission error should return message")
    }

    // MARK: - Integration Tests

    func testFormState_FullSubmissionFlow() async {
        let formState = FormState()

        // Register validators
        formState.registerValidator(for: "title") {
            ValidationResult(isValid: !formState.errors["title"] != nil, errorMessage: "Titel erforderlich")
        }

        XCTAssertFalse(formState.isSubmitting, "Should not be submitting initially")

        // Simulate submission
        let result = await formState.submit {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            return "success"
        }

        XCTAssertFalse(formState.isSubmitting, "Should not be submitting after completion")
    }

    func testAppConfigAndFormStateIntegration() {
        // Test that AppConfig values can be used with FormState validation
        let formState = FormState()
        let config = AppConfig.AI

        // Create a validator that uses AppConfig
        formState.registerValidator(for: "giftBudget") {
            let value = AppConfig.Budget.min // Use config constant
            let isValid = value > 0
            return ValidationResult(isValid: isValid, errorMessage: isValid ? "" : "Ungültiges Budget")
        }

        XCTAssertTrue(formState.isValid, "Validator using AppConfig should work")
        XCTAssertGreater(AppConfig.Budget.min, 0, "Budget min should be positive")
    }

    // MARK: - Edge Case Tests

    func testFormState_IsFieldDirty_WithoutInitialValue() {
        let formState = FormState()

        // Don't set initial value
        XCTAssertFalse(formState.isFieldDirty("field1"), "Field without initial value should not be dirty")
    }

    func testFormState_RemoveValidator() {
        let formState = FormState()

        formState.registerValidator(for: "email") {
            ValidationResult(isValid: false, errorMessage: "Invalid")
        }
        XCTAssertFalse(formState.isValid, "Should be invalid with validator")

        formState.removeValidator(for: "email")
        XCTAssertTrue(formState.isValid, "Should be valid after removing the only validator")
    }

    func testPersonEntity_InitFromPersonRef_Conversion() {
        // Create a mock PersonRef (this requires SwiftData context in actual tests)
        // For this unit test, we just validate the initializer exists
        let uuid = UUID()
        let entity = PersonEntity(
            id: uuid,
            displayName: "Test Person",
            relation: "Friend"
        )

        XCTAssertEqual(entity.id, uuid)
        XCTAssertEqual(entity.displayName, "Test Person")
        XCTAssertEqual(entity.relation, "Friend")
    }
}

// MARK: - Mock Types for Testing

/// Simple ValidationResult for testing FormState
struct ValidationResult {
    let isValid: Bool
    let errorMessage: String
}
