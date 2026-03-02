import Foundation
import SwiftUI

// MARK: - Validation Result
struct ValidationResult {
    let isValid: Bool
    let errorMessage: String?
    let errorKey: String?

    static let valid = ValidationResult(isValid: true, errorMessage: nil, errorKey: nil)

    init(isValid: Bool, errorMessage: String?, errorKey: String? = nil) {
        self.isValid = isValid
        self.errorMessage = errorMessage
        self.errorKey = errorKey
    }
}

// MARK: - Validation Helper
struct ValidationHelper {
    // MARK: - String Validation

    /// Validates that a string is not empty
    static func validateNotEmpty(_ value: String, fieldName: String) -> ValidationResult {
        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return ValidationResult(
                isValid: false,
                errorMessage: "\(fieldName) darf nicht leer sein",
                errorKey: "empty"
            )
        }
        return .valid
    }

    /// Validates minimum length
    static func validateMinLength(_ value: String, minLength: Int, fieldName: String) -> ValidationResult {
        if value.count < minLength {
            return ValidationResult(
                isValid: false,
                errorMessage: "\(fieldName) muss mindestens \(minLength) Zeichen haben",
                errorKey: "minLength"
            )
        }
        return .valid
    }

    /// Validates maximum length
    static func validateMaxLength(_ value: String, maxLength: Int, fieldName: String) -> ValidationResult {
        if value.count > maxLength {
            return ValidationResult(
                isValid: false,
                errorMessage: "\(fieldName) darf maximal \(maxLength) Zeichen haben",
                errorKey: "maxLength"
            )
        }
        return .valid
    }

    /// Validates URL format
    static func validateURL(_ urlString: String) -> ValidationResult {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

        // Empty URL is valid (optional field)
        if trimmed.isEmpty {
            return .valid
        }

        // Check if it's a valid URL
        if let url = URL(string: trimmed), url.scheme != nil {
            return .valid
        }

        return ValidationResult(
            isValid: false,
            errorMessage: "Bitte gib eine gültige URL ein (z.B. https://example.com)",
            errorKey: "invalidURL"
        )
    }

    /// Validates email format
    static func validateEmail(_ email: String) -> ValidationResult {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)

        // Empty email is valid (optional field)
        if trimmed.isEmpty {
            return .valid
        }

        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)

        if !predicate.evaluate(with: trimmed) {
            return ValidationResult(
                isValid: false,
                errorMessage: "Bitte gib eine gültige E-Mail-Adresse ein",
                errorKey: "invalidEmail"
            )
        }

        return .valid
    }

    // MARK: - Number Validation

    /// Validates minimum value
    static func validateMinValue(_ value: Double, minValue: Double, fieldName: String) -> ValidationResult {
        if value < minValue {
            return ValidationResult(
                isValid: false,
                errorMessage: "\(fieldName) muss mindestens \(minValue) sein",
                errorKey: "minValue"
            )
        }
        return .valid
    }

    /// Validates maximum value
    static func validateMaxValue(_ value: Double, maxValue: Double, fieldName: String) -> ValidationResult {
        if value > maxValue {
            return ValidationResult(
                isValid: false,
                errorMessage: "\(fieldName) darf maximal \(maxValue) sein",
                errorKey: "maxValue"
            )
        }
        return .valid
    }

    /// Validates budget range (min <= max)
    static func validateBudgetRange(min: Double, max: Double) -> ValidationResult {
        if min > max {
            return ValidationResult(
                isValid: false,
                errorMessage: "Das Mindestbudget darf nicht höher als das Maximalbudget sein",
                errorKey: "budgetRange"
            )
        }
        return .valid
    }

    // MARK: - Array Validation

    /// Validates array maximum length
    static func validateMaxArrayLength<T>(_ array: [T], maxLength: Int, fieldName: String) -> ValidationResult {
        if array.count > maxLength {
            return ValidationResult(
                isValid: false,
                errorMessage: "Maximal \(maxLength) \(fieldName) erlaubt",
                errorKey: "maxArrayLength"
            )
        }
        return .valid
    }

    /// Validates tags array
    static func validateTags(_ tags: [String]) -> ValidationResult {
        // Check max tags
        if tags.count > 10 {
            return ValidationResult(
                isValid: false,
                errorMessage: "Maximal 10 Tags erlaubt",
                errorKey: "maxTags"
            )
        }

        // Validate each tag
        for (index, tag) in tags.enumerated() {
            if tag.count > 30 {
                return ValidationResult(
                    isValid: false,
                    errorMessage: "Tag \(index + 1) darf maximal 30 Zeichen haben",
                    errorKey: "tagTooLong"
                )
            }
        }

        return .valid
    }

    // MARK: - Date Validation

    /// Validates that a date is not in the past
    static func validateNotInPast(_ date: Date, fieldName: String) -> ValidationResult {
        if date < Date() {
            return ValidationResult(
                isValid: false,
                errorMessage: "\(fieldName) darf nicht in der Vergangenheit liegen",
                errorKey: "dateInPast"
            )
        }
        return .valid
    }

    /// Validates that a date is not too far in the future
    static func validateMaxFutureDate(_ date: Date, years: Int = 5, fieldName: String) -> ValidationResult {
        let maxDate = Calendar.current.date(byAdding: .year, value: years, to: Date()) ?? Date()

        if date > maxDate {
            return ValidationResult(
                isValid: false,
                errorMessage: "\(fieldName) darf nicht mehr als \(years) Jahre in der Zukunft liegen",
                errorKey: "dateTooFar"
            )
        }
        return .valid
    }

    // MARK: - Gift-Specific Validation

    /// Validates gift idea fields
    static func validateGiftIdea(
        title: String,
        budgetMin: Double,
        budgetMax: Double,
        link: String,
        tags: [String]
    ) -> ValidationResult {
        // Validate title
        if let error = validateNotEmpty(title, fieldName: "Titel").errorMessage {
            return ValidationResult(isValid: false, errorMessage: error, errorKey: "title")
        }
        if let error = validateMaxLength(title, maxLength: 100, fieldName: "Titel").errorMessage {
            return ValidationResult(isValid: false, errorMessage: error, errorKey: "title")
        }

        // Validate budget
        if budgetMin < 0 || budgetMax < 0 {
            return ValidationResult(isValid: false, errorMessage: "Budget darf nicht negativ sein", errorKey: "budget")
        }
        if let error = validateBudgetRange(min: budgetMin, max: budgetMax).errorMessage {
            return ValidationResult(isValid: false, errorMessage: error, errorKey: "budget")
        }

        // Validate link
        if let error = validateURL(link).errorMessage {
            return ValidationResult(isValid: false, errorMessage: error, errorKey: "link")
        }

        // Validate tags
        if let error = validateTags(tags).errorMessage {
            return ValidationResult(isValid: false, errorMessage: error, errorKey: "tags")
        }

        return .valid
    }

    /// Validates gift history fields
    static func validateGiftHistory(
        title: String,
        year: Int,
        budget: Double,
        link: String
    ) -> ValidationResult {
        // Validate title
        if let error = validateNotEmpty(title, fieldName: "Titel").errorMessage {
            return ValidationResult(isValid: false, errorMessage: error, errorKey: "title")
        }
        if let error = validateMaxLength(title, maxLength: 100, fieldName: "Titel").errorMessage {
            return ValidationResult(isValid: false, errorMessage: error, errorKey: "title")
        }

        // Validate year
        let currentYear = Calendar.current.component(.year, from: Date())
        if year < 1900 || year > currentYear {
            return ValidationResult(
                isValid: false,
                errorMessage: "Jahr muss zwischen 1900 und \(currentYear) liegen",
                errorKey: "year"
            )
        }

        // Validate budget
        if budget < 0 {
            return ValidationResult(isValid: false, errorMessage: "Budget darf nicht negativ sein", errorKey: "budget")
        }

        // Validate link
        if let error = validateURL(link).errorMessage {
            return ValidationResult(isValid: false, errorMessage: error, errorKey: "link")
        }

        return .valid
    }

    /// Validates reminder settings
    static func validateReminderSettings(
        leadDays: Set<Int>,
        quietHoursStart: Int,
        quietHoursEnd: Int
    ) -> ValidationResult {
        // Check if at least one lead day is selected
        if leadDays.isEmpty {
            return ValidationResult(
                isValid: false,
                errorMessage: "Mindestens eine Vorwarnung muss ausgewählt sein",
                errorKey: "noLeadDays"
            )
        }

        // Validate quiet hours range (0-23)
        if quietHoursStart < 0 || quietHoursStart > 23 {
            return ValidationResult(
                isValid: false,
                errorMessage: "Ruhestunden-Start muss zwischen 0 und 23 liegen",
                errorKey: "quietHoursStart"
            )
        }

        if quietHoursEnd < 0 || quietHoursEnd > 23 {
            return ValidationResult(
                isValid: false,
                errorMessage: "Ruhestunden-Ende muss zwischen 0 und 23 liegen",
                errorKey: "quietHoursEnd"
            )
        }

        return .valid
    }
}

// MARK: - Validation Error View
struct ValidationErrorView: View {
    let result: ValidationResult

    var body: some View {
        if !result.isValid, let errorMessage = result.errorMessage {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)

                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
            .transition(.opacity)
        }
    }
}

// MARK: - Preview
#Preview("Validation Helper") {
    VStack(alignment: .leading, spacing: 16) {
        Text("Validation Helper Examples")
            .font(.headline)

        ValidationErrorView(result: ValidationHelper.validateNotEmpty("", fieldName: "Titel"))
        ValidationErrorView(result: ValidationHelper.validateMaxLength("A", maxLength: 10, fieldName: "Titel"))
        ValidationErrorView(result: ValidationHelper.validateURL("invalid-url"))
        ValidationErrorView(result: ValidationHelper.validateBudgetRange(min: 100, max: 50))
        ValidationErrorView(result: .valid)
    }
    .padding()
}
