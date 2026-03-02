import Foundation
import SwiftUI

enum ValidationError: LocalizedError {
    case emptyField(String)
    case invalidBudget
    case budgetMinMaxMismatch
    case invalidURL
    case tooShort(minLength: Int)
    case tooLong(maxLength: Int)

    var errorDescription: String? {
        switch self {
        case .emptyField(let field):
            return "\(field) darf nicht leer sein"
        case .invalidBudget:
            return "Bitte gib eine gültige Zahl ein"
        case .budgetMinMaxMismatch:
            return "Maximalbetrag muss größer als Minimalbetrag sein"
        case .invalidURL:
            return "Bitte gib eine gültige URL ein"
        case .tooShort(let length):
            return "Mindestens \(length) Zeichen erforderlich"
        case .tooLong(let length):
            return "Maximal \(length) Zeichen erlaubt"
        }
    }
}

struct FormValidator {
    /// Validates budget input
    static func validateBudget(minString: String, maxString: String) -> ValidationError? {
        // Both empty is valid
        if minString.isEmpty && maxString.isEmpty {
            return nil
        }

        // Check if min is valid
        guard let min = Double(minString), min >= 0 else {
            return !minString.isEmpty ? .invalidBudget : nil
        }

        // Check if max is valid
        guard let max = Double(maxString), max >= 0 else {
            return !maxString.isEmpty ? .invalidBudget : nil
        }

        // Check if max >= min
        if max > 0 && min > max {
            return .budgetMinMaxMismatch
        }

        return nil
    }

    /// Validates a required text field
    static func validateRequired(_ text: String, fieldName: String) -> ValidationError? {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .emptyField(fieldName)
        }
        return nil
    }

    /// Validates title length
    static func validateTitle(_ text: String) -> ValidationError? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return .emptyField("Titel")
        }
        if trimmed.count > AppConfig.Limits.maxTitleLength {
            return .tooLong(maxLength: AppConfig.Limits.maxTitleLength)
        }
        return nil
    }

    /// Validates note length
    static func validateNote(_ text: String) -> ValidationError? {
        if text.count > AppConfig.Limits.maxNoteLength {
            return .tooLong(maxLength: AppConfig.Limits.maxNoteLength)
        }
        return nil
    }

    /// Validates URL string
    static func validateURL(_ urlString: String) -> ValidationError? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return nil // Empty is valid
        }

        let (sanitized, isValid) = URLValidator.validate(trimmed)
        if !isValid {
            return .invalidURL
        }
        return nil
    }

    /// Validates tags (comma-separated)
    static func validateTags(_ tagsInput: String) -> ValidationError? {
        let tags = tagsInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        for tag in tags {
            if tag.count > AppConfig.Limits.maxTagLength {
                return .tooLong(maxLength: AppConfig.Limits.maxTagLength)
            }
        }

        if tags.count > AppConfig.Limits.maxTags {
            return .tooLong(maxLength: AppConfig.Limits.maxTags)
        }

        return nil
    }

    /// Validates category field
    static func validateCategory(_ category: String) -> ValidationError? {
        let trimmed = category.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return .emptyField("Kategorie")
        }
        if trimmed.count > AppConfig.Limits.maxCategoryLength {
            return .tooLong(maxLength: AppConfig.Limits.maxCategoryLength)
        }
        return nil
    }
}

// MARK: - View Extensions for Form Validation

extension View {
    /// Adds validation error indicator
    func validationIndicator(isValid: Bool) -> some View {
        self
            .overlay(alignment: .trailing) {
                if !isValid {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .padding(.trailing, 8)
                }
            }
    }

    /// Adds visual feedback for text field validation
    func validationFeedback(validation: ValidationError?) -> some View {
        self
            .overlay(alignment: .bottom) {
                if let error = validation {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption)
                        Text(error.errorDescription ?? "")
                            .font(.caption)
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .transition(.opacity)
                }
            }
    }
}

// MARK: - Validation State Helper

@Observable
class AppFormState {
    var errors: [String: ValidationError] = [:]

    func setError(_ error: ValidationError?, for field: String) {
        errors[field] = error
    }

    func clearError(for field: String) {
        errors.removeValue(forKey: field)
    }

    func clearAllErrors() {
        errors.removeAll()
    }

    func hasErrors() -> Bool {
        !errors.isEmpty
    }

    func error(for field: String) -> ValidationError? {
        errors[field]
    }

    var isValid: Bool {
        errors.isEmpty
    }
}
