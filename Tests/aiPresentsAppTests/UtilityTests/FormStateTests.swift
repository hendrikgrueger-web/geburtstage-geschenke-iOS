import XCTest
@testable import aiPresentsApp

@MainActor
final class FormStateTests: XCTestCase {

    var formState: FormState!

    override func setUp() async throws {
        formState = FormState()
    }

    // MARK: - Validation Tests

    func testValidation_AllFieldsValid() {
        formState.registerValidator(for: "title") {
            ValidationResult(isValid: true, errorMessage: nil)
        }

        formState.registerValidator(for: "budget") {
            ValidationResult(isValid: true, errorMessage: nil)
        }

        formState.validateAll()

        XCTAssertTrue(formState.isValid)
        XCTAssertFalse(formState.hasErrors)
        XCTAssertEqual(formState.errorCount, 0)
    }

    func testValidation_OneFieldInvalid() {
        formState.registerValidator(for: "title") {
            ValidationResult(isValid: false, errorMessage: "Titel darf nicht leer sein")
        }

        formState.registerValidator(for: "budget") {
            ValidationResult(isValid: true, errorMessage: nil)
        }

        formState.validateAll()

        XCTAssertFalse(formState.isValid)
        XCTAssertTrue(formState.hasErrors)
        XCTAssertEqual(formState.errorCount, 1)
        XCTAssertEqual(formState.error(for: "title"), "Titel darf nicht leer sein")
    }

    func testValidation_MultipleFieldsInvalid() {
        formState.registerValidator(for: "title") {
            ValidationResult(isValid: false, errorMessage: "Titel darf nicht leer sein")
        }

        formState.registerValidator(for: "budget") {
            ValidationResult(isValid: false, errorMessage: "Budget muss positiv sein")
        }

        formState.registerValidator(for: "url") {
            ValidationResult(isValid: false, errorMessage: "URL ungültig")
        }

        formState.validateAll()

        XCTAssertFalse(formState.isValid)
        XCTAssertTrue(formState.hasErrors)
        XCTAssertEqual(formState.errorCount, 3)
    }

    func testValidateField_SpecificField() {
        formState.registerValidator(for: "title") {
            ValidationResult(isValid: true, errorMessage: nil)
        }

        formState.registerValidator(for: "budget") {
            ValidationResult(isValid: false, errorMessage: "Budget muss positiv sein")
        }

        formState.validateField("title")

        XCTAssertNil(formState.error(for: "title"))
        // validateField triggers validateAll(), so budget validator also runs
        XCTAssertNotNil(formState.error(for: "budget"))
    }

    func testRemoveValidator() {
        formState.registerValidator(for: "title") {
            ValidationResult(isValid: false, errorMessage: "Titel darf nicht leer sein")
        }

        formState.validateAll()
        XCTAssertFalse(formState.isValid)

        formState.removeValidator(for: "title")
        XCTAssertTrue(formState.isValid)
    }

    // MARK: - Dirty Tracking Tests

    func testDirtyTracking_InitialNotDirty() {
        formState.setInitialValue("Initial", for: "title")

        XCTAssertFalse(formState.isDirty)
    }

    func testDirtyTracking_ValueChanged() {
        formState.setInitialValue("Initial", for: "title")
        formState.updateValue("Changed", for: "title")

        XCTAssertTrue(formState.isDirty)
    }

    func testDirtyTracking_ValueChangedToSame() {
        formState.setInitialValue("Initial", for: "title")
        formState.updateValue("Initial", for: "title")

        XCTAssertFalse(formState.isDirty)
    }

    func testDirtyTracking_MultipleFields() {
        formState.setInitialValue("Title", for: "title")
        formState.setInitialValue("Note", for: "note")

        formState.updateValue("Changed Title", for: "title")

        XCTAssertTrue(formState.isDirty)
        XCTAssertTrue(formState.isFieldDirty("title"))
        XCTAssertFalse(formState.isFieldDirty("note"))
    }

    func testDirtyTracking_ResetToInitial() {
        formState.setInitialValue("Initial", for: "title")
        formState.updateValue("Changed", for: "title")

        XCTAssertTrue(formState.isDirty)

        formState.resetToInitial()

        XCTAssertFalse(formState.isDirty)
    }

    func testDirtyTracking_IntegerValues() {
        formState.setInitialValue(100, for: "budget")

        XCTAssertFalse(formState.isDirty)

        formState.updateValue(200, for: "budget")

        XCTAssertTrue(formState.isDirty)
    }

    func testDirtyTracking_DoubleValues() {
        formState.setInitialValue(99.99, for: "price")

        XCTAssertFalse(formState.isDirty)

        formState.updateValue(199.99, for: "price")

        XCTAssertTrue(formState.isDirty)
    }

    // MARK: - Submit Tests

    func testSubmit_ValidOperation() async {
        formState.registerValidator(for: "title") {
            ValidationResult(isValid: true, errorMessage: nil)
        }

        let result: String? = await formState.submit {
            return "Success"
        }

        XCTAssertEqual(result, "Success")
        XCTAssertTrue(formState.submitSuccess)
        XCTAssertFalse(formState.isSubmitting)
        XCTAssertNil(formState.submitError)
    }

    func testSubmit_InvalidForm() async {
        formState.registerValidator(for: "title") {
            ValidationResult(isValid: false, errorMessage: "Required")
        }

        let result: String? = await formState.submit {
            return "Should not execute"
        }

        XCTAssertNil(result)
        XCTAssertFalse(formState.submitSuccess)
        XCTAssertFalse(formState.isSubmitting)
        XCTAssertNotNil(formState.submitError)
    }

    func testSubmit_OperationFails() async {
        formState.registerValidator(for: "title") {
            ValidationResult(isValid: true, errorMessage: nil)
        }

        let result: String? = await formState.submit {
            throw FormError.submissionFailed("Test error")
        }

        XCTAssertNil(result)
        XCTAssertFalse(formState.submitSuccess)
        XCTAssertFalse(formState.isSubmitting)
        XCTAssertNotNil(formState.submitError)
    }

    func testSubmit_WhileSubmitting() async {
        formState.registerValidator(for: "title") {
            ValidationResult(isValid: true, errorMessage: nil)
        }

        let operation: @Sendable () async throws -> String = {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            return "Success"
        }

        Task {
            _ = await formState.submit(operation: operation)
        }

        // Give the task a moment to start
        try? await Task.sleep(nanoseconds: 10_000_000)

        XCTAssertTrue(formState.isSubmitting)
    }

    // MARK: - Reset Tests

    func testReset_ClearsAllState() {
        formState.registerValidator(for: "title") {
            ValidationResult(isValid: false, errorMessage: "Required")
        }

        formState.setInitialValue("Initial", for: "title")
        formState.updateValue("Changed", for: "title")
        formState.validateAll()

        XCTAssertFalse(formState.isValid)
        XCTAssertTrue(formState.isDirty)
        XCTAssertTrue(formState.hasErrors)

        formState.reset()

        XCTAssertFalse(formState.isValid) // Reset doesn't auto-validate
        XCTAssertFalse(formState.isDirty)
        XCTAssertFalse(formState.hasErrors)
        XCTAssertFalse(formState.isSubmitting)
        XCTAssertNil(formState.submitError)
        XCTAssertFalse(formState.submitSuccess)
    }

    // MARK: - Error Handling Tests

    func testErrorSummary_SingleError() {
        formState.registerValidator(for: "title") {
            ValidationResult(isValid: false, errorMessage: "Titel erforderlich")
        }

        formState.validateAll()

        XCTAssertEqual(formState.errorSummary, "Titel erforderlich")
    }

    func testErrorSummary_MultipleErrors() {
        formState.registerValidator(for: "title") {
            ValidationResult(isValid: false, errorMessage: "Titel erforderlich")
        }

        formState.registerValidator(for: "budget") {
            ValidationResult(isValid: false, errorMessage: "Budget ungültig")
        }

        formState.validateAll()

        XCTAssertTrue(formState.errorSummary.contains("2"))
    }

    func testErrorSummary_NoErrors() {
        formState.registerValidator(for: "title") {
            ValidationResult(isValid: true, errorMessage: nil)
        }

        formState.validateAll()

        XCTAssertEqual(formState.errorSummary, "")
    }

    func testClearErrors() {
        formState.registerValidator(for: "title") {
            ValidationResult(isValid: false, errorMessage: "Error")
        }

        formState.validateAll()
        XCTAssertTrue(formState.hasErrors)

        formState.clearErrors()

        XCTAssertFalse(formState.hasErrors)
        XCTAssertNil(formState.error(for: "title"))
    }

    func testHasError() {
        formState.registerValidator(for: "title") {
            ValidationResult(isValid: false, errorMessage: "Error")
        }

        formState.validateAll()

        XCTAssertTrue(formState.hasError(for: "title"))
        XCTAssertFalse(formState.hasError(for: "budget"))
    }

    // MARK: - Complex Scenario Tests

    func testComplexForm_MultiStep() async {
        // Step 1: Set initial values
        formState.setInitialValue("", for: "title")
        formState.setInitialValue(0, for: "budget")

        // Step 2: Register validators
        formState.registerValidator(for: "title") {
            let result = ValidationHelper.validateNotEmpty(self.formState.currentValues["title"] as? String ?? "", fieldName: "Titel")
            return result
        }

        formState.registerValidator(for: "budget") {
            let result = ValidationHelper.validateMinValue(self.formState.currentValues["budget"] as? Double ?? 0, minValue: 0, fieldName: "Budget")
            return result
        }

        // Step 3: Validate (should fail - empty title)
        formState.validateAll()
        XCTAssertFalse(formState.isValid)

        // Step 4: Update values
        formState.updateValue("New Title", for: "title")
        formState.updateValue(100, for: "budget")

        // Step 5: Validate again (should pass)
        formState.validateAll()
        XCTAssertTrue(formState.isValid)

        // Step 6: Submit
        let result: Bool? = await formState.submit {
            return true
        }

        XCTAssertEqual(result, true)
        XCTAssertTrue(formState.submitSuccess)

        // Step 7: Reset
        formState.reset()
        XCTAssertFalse(formState.isDirty)
    }

    func testFormState_WithOptionalFields() {
        formState.registerValidator(for: "title") {
            ValidationResult(isValid: true, errorMessage: nil)
        }

        formState.registerValidator(for: "note") {
            // Note is optional - always valid
            ValidationResult(isValid: true, errorMessage: nil)
        }

        formState.validateAll()

        XCTAssertTrue(formState.isValid)
    }
}

// MARK: - Test Helper Extension

extension FormState {
    var currentValues: [String: Any] {
        get {
            // Access the private property via mirror for testing
            let mirror = Mirror(reflecting: self)
            if let child = mirror.children.first(where: { $0.label == "currentValues" }) {
                return child.value as? [String: Any] ?? [:]
            }
            return [:]
        }
    }
}
