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
                errorMessage: String(localized: "\(fieldName) darf nicht leer sein"),
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
                errorMessage: String(localized: "\(fieldName) muss mindestens \(minLength) Zeichen haben"),
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
                errorMessage: String(localized: "\(fieldName) darf maximal \(maxLength) Zeichen haben"),
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

        // Try to auto-add http:// or https:// if scheme is missing
        let withHTTP = "http://" + trimmed
        if let url = URL(string: withHTTP), url.scheme != nil && url.host != nil {
            return .valid
        }

        let withHTTPS = "https://" + trimmed
        if let url = URL(string: withHTTPS), url.scheme != nil && url.host != nil {
            return .valid
        }

        return ValidationResult(
            isValid: false,
            errorMessage: String(localized: "Bitte gib eine gültige URL ein (z.B. https://example.com)"),
            errorKey: "invalidURL"
        )
    }

    /// Normalizes URL by adding https:// if scheme is missing
    static func normalizeURL(_ urlString: String) -> String {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return trimmed
        }

        // If URL already has a scheme, return as-is
        if let url = URL(string: trimmed), url.scheme != nil {
            return trimmed
        }

        // Prefer https:// for modern sites
        return "https://" + trimmed
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
                errorMessage: String(localized: "Bitte gib eine gültige E-Mail-Adresse ein"),
                errorKey: "invalidEmail"
            )
        }

        return .valid
    }

    /// Validates category (for gift history)
    static func validateCategory(_ category: String) -> ValidationResult {
        let trimmed = category.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return ValidationResult(
                isValid: false,
                errorMessage: String(localized: "Kategorie darf nicht leer sein"),
                errorKey: "empty"
            )
        }

        if trimmed.count > 50 {
            return ValidationResult(
                isValid: false,
                errorMessage: String(localized: "Kategorie darf maximal 50 Zeichen haben"),
                errorKey: "maxLength"
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
                errorMessage: String(localized: "\(fieldName) muss mindestens \(minValue) sein"),
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
                errorMessage: String(localized: "\(fieldName) darf maximal \(maxValue) sein"),
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
                errorMessage: String(localized: "Das Mindestbudget darf nicht höher als das Maximalbudget sein"),
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
                errorMessage: String(localized: "Maximal \(maxLength) \(fieldName) erlaubt"),
                errorKey: "maxArrayLength"
            )
        }
        return .valid
    }

    /// Validates tags array
    static func validateTags(_ tags: [String]) -> ValidationResult {
        // Filter out empty tags first
        let nonEmptyTags = tags.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        // Check max tags (after filtering empty ones)
        if nonEmptyTags.count > 10 {
            return ValidationResult(
                isValid: false,
                errorMessage: String(localized: "Maximal 10 Tags erlaubt"),
                errorKey: "maxTags"
            )
        }

        // Validate each tag
        for (index, tag) in nonEmptyTags.enumerated() {
            let trimmedTag = tag.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedTag.count > 30 {
                return ValidationResult(
                    isValid: false,
                    errorMessage: String(localized: "Tag \(index + 1) darf maximal 30 Zeichen haben"),
                    errorKey: "tagTooLong"
                )
            }
        }

        return .valid
    }

    /// Sanitizes tags array by trimming whitespace and removing empty tags
    static func sanitizeTags(_ tags: [String]) -> [String] {
        return tags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    // MARK: - Date Validation

    /// Validates that a date is not in the past
    static func validateNotInPast(_ date: Date, fieldName: String) -> ValidationResult {
        if date < Date() {
            return ValidationResult(
                isValid: false,
                errorMessage: String(localized: "\(fieldName) darf nicht in der Vergangenheit liegen"),
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
                errorMessage: String(localized: "\(fieldName) darf nicht mehr als \(years) Jahre in der Zukunft liegen"),
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
        let titleFieldName = String(localized: "Titel")
        if let error = validateNotEmpty(title, fieldName: titleFieldName).errorMessage {
            return ValidationResult(isValid: false, errorMessage: error, errorKey: "title")
        }
        if let error = validateMaxLength(title, maxLength: 100, fieldName: titleFieldName).errorMessage {
            return ValidationResult(isValid: false, errorMessage: error, errorKey: "title")
        }

        // Validate budget
        if budgetMin < 0 || budgetMax < 0 {
            return ValidationResult(isValid: false, errorMessage: String(localized: "Budget darf nicht negativ sein"), errorKey: "budget")
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
        category: String,
        year: Int,
        budget: Double,
        link: String
    ) -> ValidationResult {
        // Validate title
        let titleFieldName = String(localized: "Titel")
        if let error = validateNotEmpty(title, fieldName: titleFieldName).errorMessage {
            return ValidationResult(isValid: false, errorMessage: error, errorKey: "title")
        }
        if let error = validateMaxLength(title, maxLength: 100, fieldName: titleFieldName).errorMessage {
            return ValidationResult(isValid: false, errorMessage: error, errorKey: "title")
        }

        // Validate category
        if let error = validateCategory(category).errorMessage {
            return ValidationResult(isValid: false, errorMessage: error, errorKey: "category")
        }

        // Validate year
        let currentYear = Calendar.current.component(.year, from: Date())
        if year < 1900 || year > currentYear {
            return ValidationResult(
                isValid: false,
                errorMessage: String(localized: "Jahr muss zwischen 1900 und \(currentYear) liegen"),
                errorKey: "year"
            )
        }

        // Validate budget
        if budget < 0 {
            return ValidationResult(isValid: false, errorMessage: String(localized: "Budget darf nicht negativ sein"), errorKey: "budget")
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
                errorMessage: String(localized: "Mindestens eine Vorwarnung muss ausgewählt sein"),
                errorKey: "noLeadDays"
            )
        }

        // Validate quiet hours range (0-23)
        if quietHoursStart < 0 || quietHoursStart > 23 {
            return ValidationResult(
                isValid: false,
                errorMessage: String(localized: "Ruhestunden-Start muss zwischen 0 und 23 liegen"),
                errorKey: "quietHoursStart"
            )
        }

        if quietHoursEnd < 0 || quietHoursEnd > 23 {
            return ValidationResult(
                isValid: false,
                errorMessage: String(localized: "Ruhestunden-Ende muss zwischen 0 und 23 liegen"),
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
                    .foregroundStyle(AppColor.accent)
                    .font(.caption)

                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(AppColor.accent)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppColor.accent.opacity(0.1))
            .clipShape(.rect(cornerRadius: 8))
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
