import SwiftUI

/// A smart text field with real-time validation, debounced feedback, and accessibility support
struct SmartInputField: View {
    // MARK: - Properties
    let title: String
    @Binding var text: String
    let placeholder: String
    let validator: ((String) -> ValidationResult)?
    let keyboardType: UIKeyboardType
    let autocapitalization: TextInputAutocapitalization
    let isSecure: Bool

    @State private var isFocused: Bool = false
    @State private var validationResult: ValidationResult = .valid
    @State private var debouncedText: String = ""
    @FocusState private var fieldFocus: Bool

    @StateObject private var debouncer = Debouncer(delay: 0.3)

    // MARK: - Computed Properties
    private var borderColor: Color {
        if !isFocused {
            return .gray.opacity(0.3)
        }
        return validationResult.isValid ? AppColor.primary : .orange
    }

    private var icon: String? {
        guard !text.isEmpty else { return nil }

        switch validationResult.errorKey {
        case "empty":
            return "exclamationmark.triangle.fill"
        case "minLength", "maxLength":
            return "text.alignleft"
        case "invalidURL", "invalidEmail":
            return "link.badge"
        case "minValue", "maxValue", "budgetRange":
            return "number"
        default:
            return validationResult.isValid ? "checkmark.circle.fill" : nil
        }
    }

    private var iconColor: Color? {
        guard let icon = icon else { return nil }

        if validationResult.isValid {
            return .green
        }

        switch validationResult.errorKey {
        case "empty", "minLength", "maxLength", "invalidURL", "invalidEmail", "minValue", "maxValue", "budgetRange":
            return .orange
        default:
            return nil
        }
    }

    // MARK: - Initializer
    init(
        title: String,
        text: Binding<String>,
        placeholder: String,
        validator: ((String) -> ValidationResult)? = nil,
        keyboardType: UIKeyboardType = .default,
        autocapitalization: TextInputAutocapitalization = .sentences,
        isSecure: Bool = false
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.validator = validator
        self.keyboardType = keyboardType
        self.autocapitalization = autocapitalization
        self.isSecure = isSecure
    }

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(AppColor.textSecondary)

            // Text field with validation
            HStack(spacing: 12) {
                ZStack(alignment: .leading) {
                    if isSecure || text.isEmpty {
                        Text(placeholder)
                            .foregroundColor(.gray.opacity(0.5))
                            .font(.body)
                    }

                    if isSecure {
                        SecureField("", text: $text)
                            .font(.body)
                            .textInputAutocapitalization(autocapitalization)
                            .keyboardType(keyboardType)
                            .focused($fieldFocus)
                            .onChange(of: text) { _, newValue in
                                handleTextChange(newValue)
                            }
                    } else {
                        TextField("", text: $text)
                            .font(.body)
                            .textInputAutocapitalization(autocapitalization)
                            .keyboardType(keyboardType)
                            .focused($fieldFocus)
                            .onChange(of: text) { _, newValue in
                                handleTextChange(newValue)
                            }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(borderColor, lineWidth: isFocused ? 2 : 1)
                )
                .onChange(of: fieldFocus) { _, newValue in
                    isFocused = newValue
                    if !newValue {
                        // Final validation when losing focus
                        validateImmediate()
                    }
                }

                // Validation icon
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundColor(iconColor)
                        .symbolEffect(.bounce, options: .repeating, isActive: !validationResult.isValid && isFocused)
                }
            }

            // Validation error message
            if !validationResult.isValid && isFocused, let errorMessage = validationResult.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)

                    Text(errorMessage)
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Character count for text fields
            if keyboardType == .default && !isSecure, let validator = validator {
                characterCountView
            }
        }
        .animation(.easeInOut(duration: 0.2), value: validationResult.isValid)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(text.isEmpty ? "leer" : text)")
        .accessibilityHint(validationResult.errorMessage ?? "")
        .accessibilityValue(validationResult.isValid ? "gültig" : "ungültig")
    }

    // MARK: - Subviews
    private var characterCountView: some View {
        HStack {
            Spacer()
            Text("\(text.count) Zeichen")
                .font(.caption2)
                .foregroundColor(
                    validationResult.errorKey == "maxLength"
                        ? .orange
                        : .gray.opacity(0.6)
                )
        }
    }

    // MARK: - Methods
    private func handleTextChange(_ newValue: String) {
        // Debounced validation
        debouncer.debounce {
            DispatchQueue.main.async {
                debouncedText = newValue
                validateImmediate()
            }
        }
    }

    private func validateImmediate() {
        if let validator = validator {
            validationResult = validator(text)
        } else {
            validationResult = .valid
        }
    }
}

// MARK: - Predefined Smart Input Fields

extension SmartInputField {
    static func titleField(
        text: Binding<String>,
        minLength: Int = 2,
        maxLength: Int = 100,
        placeholder: String = "Titel eingeben"
    ) -> some View {
        SmartInputField(
            title: "Titel",
            text: text,
            placeholder: placeholder,
            validator: { value in
                var result = ValidationHelper.validateNotEmpty(value, fieldName: "Titel")
                if result.isValid {
                    result = ValidationHelper.validateMinLength(value, minLength: minLength, fieldName: "Titel")
                }
                if result.isValid {
                    result = ValidationHelper.validateMaxLength(value, maxLength: maxLength, fieldName: "Titel")
                }
                return result
            }
        )
    }

    static func urlField(
        text: Binding<String>,
        placeholder: String = "https://example.com"
    ) -> some View {
        SmartInputField(
            title: "Link",
            text: text,
            placeholder: placeholder,
            validator: { value in
                // Auto-normalize URL on focus loss
                if let url = URL(string: value), url.scheme == nil, !value.isEmpty {
                    DispatchQueue.main.async {
                        text.wrappedValue = "https://" + value
                    }
                }
                return ValidationHelper.validateURL(value)
            },
            keyboardType: .URL,
            autocapitalization: .never
        )
    }

    static func emailField(
        text: Binding<String>,
        placeholder: String = "email@example.com"
    ) -> some View {
        SmartInputField(
            title: "E-Mail",
            text: text,
            placeholder: placeholder,
            validator: ValidationHelper.validateEmail,
            keyboardType: .emailAddress,
            autocapitalization: .never
        )
    }

    static func noteField(
        text: Binding<String>,
        maxLength: Int = 500,
        placeholder: String = "Notiz hinzufügen"
    ) -> some View {
        SmartInputField(
            title: "Notiz",
            text: text,
            placeholder: placeholder,
            validator: { value in
                if !value.isEmpty {
                    return ValidationHelper.validateMaxLength(value, maxLength: maxLength, fieldName: "Notiz")
                }
                return .valid
            }
        )
    }

    static func budgetField(
        value: Binding<Double>,
        title: String = "Budget",
        placeholder: String = "€0.00",
        minValue: Double = 0,
        maxValue: Double = 10000
    ) -> some View {
        HStack(alignment: .top, spacing: 8) {
            SmartInputField(
                title: title,
                text: Binding(
                    get: { value.wrappedValue == 0 ? "" : String(format: "%.2f", value.wrappedValue) },
                    set: { newValue in
                        if let parsed = Double(newValue) {
                            value.wrappedValue = Swift.min(maxValue, Swift.max(minValue, parsed))
                        }
                    }
                ),
                placeholder: placeholder,
                validator: { valueText in
                    if valueText.isEmpty {
                        return .valid
                    }
                    guard let parsed = Double(valueText) else {
                        return ValidationResult(isValid: false, errorMessage: "Bitte gib eine gültige Zahl ein", errorKey: "invalidNumber")
                    }
                    if parsed < minValue {
                        return ValidationResult(isValid: false, errorMessage: "Minimum: \(minValue)€", errorKey: "minValue")
                    }
                    if parsed > maxValue {
                        return ValidationResult(isValid: false, errorMessage: "Maximum: \(maxValue)€", errorKey: "maxValue")
                    }
                    return .valid
                },
                keyboardType: .decimalPad,
                autocapitalization: .never
            )
        }
    }
}

// MARK: - Preview

#Preview("Smart Input Fields") {
    Form {
        Section("Beispiele") {
            SmartInputField.titleField(text: .constant("Beispiel Titel"))
            SmartInputField.urlField(text: .constant("https://example.com"))
            SmartInputField.emailField(text: .constant("test@example.com"))
            SmartInputField.noteField(text: .constant("Dies ist eine Notiz"))
            SmartInputField.budgetField(value: .constant(99.99))
        }

        Section("Validation Errors") {
            SmartInputField.titleField(text: .constant(""))
            SmartInputField.urlField(text: .constant("invalid-url"))
        }
    }
}

#Preview("Real-time Validation") {
    struct PreviewWrapper: View {
        @State private var title: String = ""
        @State private var url: String = ""

        var body: some View {
            Form {
                Section {
                    SmartInputField.titleField(text: $title)
                    SmartInputField.urlField(text: $url)
                }
            }
        }
    }

    return PreviewWrapper()
}
