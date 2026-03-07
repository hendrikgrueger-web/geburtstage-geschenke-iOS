import Foundation
import SwiftUI

/// Generic form state management with validation, dirty tracking, and error handling
@MainActor
final class FormState: ObservableObject {
    // MARK: - Published Properties
    @Published var isDirty: Bool = false
    @Published var isValid: Bool = false
    @Published var isSubmitting: Bool = false
    @Published var submitError: Error?
    @Published var submitSuccess: Bool = false
    @Published var errors: [String: String] = [:]

    // MARK: - Private Properties
    private var validators: [String: () -> ValidationResult] = [:]
    private var initialValues: [String: Any] = [:]
    private var currentValues: [String: Any] = [:]

    // MARK: - Validation

    /// Register a validator for a field
    func registerValidator(for field: String, validator: @escaping () -> ValidationResult) {
        validators[field] = validator
        validateAll()
    }

    /// Remove a validator for a field
    func removeValidator(for field: String) {
        validators.removeValue(forKey: field)
        validateAll()
    }

    /// Validate a specific field
    func validateField(_ field: String) {
        guard let validator = validators[field] else { return }

        let result = validator()
        if result.isValid {
            errors.removeValue(forKey: field)
        } else {
            errors[field] = result.errorMessage
        }

        validateAll()
    }

    /// Validate all registered fields
    func validateAll() {
        var allValid = true

        for (field, validator) in validators {
            let result = validator()
            if result.isValid {
                errors.removeValue(forKey: field)
            } else {
                errors[field] = result.errorMessage
                allValid = false
            }
        }

        isValid = allValid
    }

    // MARK: - Dirty Tracking

    /// Track the initial value for a field
    func setInitialValue<T: Equatable>(_ value: T, for field: String) {
        initialValues[field] = value
        currentValues[field] = value
        updateDirtyState()
    }

    /// Update the current value for a field
    func updateValue<T: Equatable>(_ value: T, for field: String) {
        currentValues[field] = value
        updateDirtyState()
    }

    /// Check if a specific field is dirty (changed from initial)
    func isFieldDirty(_ field: String) -> Bool {
        guard let initial = initialValues[field], let current = currentValues[field] else {
            return false
        }

        return String(describing: initial) != String(describing: current)
    }

    /// Update the overall dirty state
    private func updateDirtyState() {
        isDirty = !initialValues.isEmpty && initialValues.keys.contains { key in
            String(describing: initialValues[key]) != String(describing: currentValues[key])
        }
    }

    /// Reset to initial values (clear dirty state)
    func resetToInitial() {
        currentValues = initialValues
        isDirty = false
        validateAll()
    }

    // MARK: - Form Submission

    /// Submit the form with an async operation
    func submit<T>(operation: @escaping () async throws -> T) async -> T? {
        // Validate before submitting
        validateAll()

        guard isValid else {
            submitError = FormError.validationFailed
            return nil
        }

        isSubmitting = true
        submitError = nil
        submitSuccess = false

        do {
            let result = try await operation()
            submitSuccess = true
            isSubmitting = false
            return result
        } catch {
            submitError = error
            isSubmitting = false
            AppLogger.forms.error("Form submission failed", error: error)
            return nil
        }
    }

    /// Reset the form to initial state
    func reset() {
        isDirty = false
        isValid = false
        isSubmitting = false
        submitError = nil
        submitSuccess = false
        errors = [:]
        currentValues = initialValues
    }

    // MARK: - Error Handling

    /// Get the error message for a specific field
    func error(for field: String) -> String? {
        return errors[field]
    }

    /// Check if a specific field has an error
    func hasError(for field: String) -> Bool {
        return errors[field] != nil
    }

    /// Clear all errors
    func clearErrors() {
        errors = [:]
        isValid = validators.values.allSatisfy { $0().isValid }
    }

    // MARK: - Computed Properties

    /// Whether the form has any errors
    var hasErrors: Bool {
        !errors.isEmpty
    }

    /// Number of errors
    var errorCount: Int {
        errors.count
    }

    /// All error messages
    var allErrors: [String] {
        Array(errors.values)
    }

    /// User-friendly error summary
    var errorSummary: String {
        if errors.isEmpty {
            return ""
        }

        if errors.count == 1 {
            return Array(errors.values).first ?? ""
        }

        return "\(errors.count) Fehler sind aufgetreten"
    }
}

// MARK: - Form Error Types

enum FormError: LocalizedError {
    case validationFailed
    case networkError(Error)
    case submissionFailed(String)
    case custom(String)

    var errorDescription: String? {
        switch self {
        case .validationFailed:
            return String(localized: "Bitte korrigiere die Fehler im Formular")
        case .networkError(let error):
            return String(localized: "Netzwerkfehler:") + " \(error.localizedDescription)"
        case .submissionFailed(let message):
            return message
        case .custom(let message):
            return message
        }
    }
}

// MARK: - SwiftUI View Modifiers

extension View {
    /// Bind a text field to a FormState with validation
    func formField<T: Equatable>(
        _ value: Binding<T>,
        for field: String,
        validator: @escaping (T) -> ValidationResult
    ) -> some View {
        self
            .onAppear {
                // Register validator and set initial value
            }
            .onChange(of: value.wrappedValue) { _, newValue in
                // Update value and validate
            }
    }
}

// MARK: - Form Field Wrapper

struct FormField<FieldContent: View>: View {
    let label: String
    let field: String
    @ObservedObject var formState: FormState
    let content: FieldContent

    init(
        label: String,
        field: String,
        formState: FormState,
        @ViewBuilder content: () -> FieldContent
    ) {
        self.label = label
        self.field = field
        self.formState = formState
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(AppColor.textSecondary)

            // Content
            content

            // Error message
            if let errorMessage = formState.error(for: field) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(AppColor.accent)

                    Text(errorMessage)
                        .font(.caption2)
                        .foregroundStyle(AppColor.accent)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppColor.accent.opacity(0.1))
                .clipShape(.rect(cornerRadius: 6))
                .transition(.opacity)
            }
        }
    }
}

// MARK: - Form Submit Button

struct FormSubmitButton: View {
    @ObservedObject var formState: FormState
    let title: String
    let action: () -> Void
    let disabledTitle: String?

    init(
        title: String,
        formState: FormState,
        disabledTitle: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.formState = formState
        self.disabledTitle = disabledTitle
        self.action = action
    }

    var body: some View {
        Button(action: {
            HapticFeedback.medium()
            action()
        }) {
            HStack {
                if formState.isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else if formState.submitSuccess {
                    Image(systemName: "checkmark")
                } else {
                    Text(buttonTitle)
                }
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(backgroundColor)
            .clipShape(.rect(cornerRadius: 12))
        }
        .disabled(formState.isSubmitting || !formState.isValid)
        .opacity(formState.isSubmitting || !formState.isValid ? 0.6 : 1.0)
    }

    private var buttonTitle: String {
        if let disabledTitle = disabledTitle, !formState.isValid {
            return disabledTitle
        }
        return title
    }

    private var backgroundColor: Color {
        if formState.submitSuccess {
            return .green
        }
        return AppColor.primary
    }
}

// MARK: - Preview

#Preview("Form Field with Error") {
    struct PreviewWrapper: View {
        @StateObject private var formState = FormState()

        var body: some View {
            Form {
                FormField(
                    label: "Titel",
                    field: "title",
                    formState: formState
                ) {
                    TextField("Titel eingeben", text: .constant(""))
                }

                FormSubmitButton(
                    title: "Speichern",
                    formState: formState
                ) {
                    // Submit action
                }
            }
            .onAppear {
                formState.errors["title"] = "Titel darf nicht leer sein"
                formState.isValid = false
            }
        }
    }

    return PreviewWrapper()
}
