import SwiftUI
import SwiftData

struct EditGiftHistorySheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let person: PersonRef
    @Bindable var history: GiftHistory

    @State private var title: String
    @State private var category: String
    @State private var year: Int
    @State private var budget: String
    @State private var note: String
    @State private var link = ""
    @State private var formState = AppFormState()
    @State private var showingValidationError = false

    private let calendar = Calendar.current
    private let currentYear: Int

    init(person: PersonRef, history: GiftHistory) {
        self.person = person
        self._history = Bindable(history)
        self._title = State(initialValue: history.title)
        self._category = State(initialValue: history.category)
        self._year = State(initialValue: history.year)
        self._budget = State(initialValue: history.budget == 0 ? "" : "\(history.budget)")
        self._note = State(initialValue: history.note)
        self._link = State(initialValue: history.link)
        currentYear = Calendar.current.component(.year, from: Date())
    }

    private var isTitleValid: Bool {
        let error = FormValidator.validateTitle(title)
        formState.setError(error, for: "title")
        return error == nil
    }

    private var isBudgetValid: Bool {
        guard !budget.isEmpty else { return true }
        guard let value = Double(budget), value >= 0 else {
            formState.setError(.invalidBudget, for: "budget")
            return false
        }
        formState.clearError(for: "budget")
        return true
    }

    private var linkValidation: (sanitized: String, isValid: Bool) {
        let (sanitized, isValid) = URLValidator.validate(link)
        if !isValid && !link.trimmingCharacters(in: .whitespaces).isEmpty {
            formState.setError(.invalidURL, for: "link")
        } else {
            formState.clearError(for: "link")
        }
        return (sanitized, isValid)
    }

    private var categoryValidation: ValidationError? {
        let error = FormValidator.validateCategory(category)
        formState.setError(error, for: "category")
        return error
    }

    private var canSave: Bool {
        isTitleValid && isBudgetValid && linkValidation.isValid && categoryValidation == nil
    }

    private var validationMessages: String {
        var messages: [String] = []
        if !isTitleValid { messages.append("- Titel darf nicht leer sein") }
        if !isBudgetValid && !budget.isEmpty { messages.append("- Ungültiges Budget") }
        if let error = categoryValidation { messages.append("- \(error.errorDescription ?? "")") }
        if !linkValidation.isValid && !link.trimmingCharacters(in: .whitespaces).isEmpty { messages.append("- Ungültige URL") }
        return messages.joined(separator: "\n")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // SmartInputField for title with validation
                    SmartInputField.titleField(
                        text: $title,
                        minLength: 2,
                        maxLength: 100,
                        placeholder: history.giftDirection == .received ? "Was hast du erhalten?" : "Was wurde verschenkt?"
                    )

                    // SmartInputField for category
                    SmartInputField(
                        title: "Kategorie",
                        text: $category,
                        placeholder: "z.B. Schmuck, Buch, Erlebnis, Geld",
                        validator: { value in
                            if !value.isEmpty {
                                return ValidationHelper.validateMaxLength(value, maxLength: 50, fieldName: "Kategorie")
                            }
                            return .valid
                        }
                    )
                } header: {
                    Text("Geschenk")
                } footer: {
                    Text("z.B. Schmuck, Buch, Erlebnis, Geld")
                }

                Section {
                    Picker("Jahr", selection: $year) {
                        ForEach((currentYear - 10)...currentYear, id: \.self) { y in
                            Text("\(y)").tag(y)
                        }
                    }
                    .accessibilityLabel("Jahr des Geschenks")
                } header: {
                    Text("Jahr des Geschenks")
                } footer: {
                    Text("Wähle das Jahr, in dem das Geschenk verschenkt wurde")
                }

                Section("Details") {
                    // SmartInputField for budget with number validation
                    HStack {
                        Text("Budget")
                        TextField("€", text: $budget)
                            .keyboardType(.decimalPad)
                            .foregroundColor(isBudgetValid ? .primary : .red)
                    }

                    if !isBudgetValid && !budget.isEmpty {
                        Text("Bitte gib eine gültige Zahl ein")
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    // SmartInputField for notes
                    SmartInputField.noteField(
                        text: $note,
                        maxLength: 500,
                        placeholder: "Optionale Notizen"
                    )

                    // SmartInputField for URL with auto-https
                    HStack {
                        SmartInputField.urlField(
                            text: $link,
                            placeholder: "https://example.com"
                        )

                        if linkValidation.isValid && !linkValidation.sanitized.isEmpty {
                            Button {
                                if let url = URL(string: linkValidation.sanitized) {
                                    UIApplication.shared.open(url) { success in
                                        if !success {
                                            AppLogger.ui.warning("Failed to open URL: \(linkValidation.sanitized)")
                                        }
                                    }
                                }
                            } label: {
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundColor(.blue)
                            }
                            .accessibilityLabel("Link öffnen")
                        }
                    }
                }
            }
            .navigationTitle(history.giftDirection == .given ? "Geschenk bearbeiten" : "Erhaltenes Geschenk bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Speichern") {
                        if canSave {
                            saveHistory()
                            dismiss()
                        } else {
                            showingValidationError = true
                            HapticFeedback.error()
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .alert("Eingabe prüfen", isPresented: $showingValidationError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(validationMessages)
        }
    }

    private func saveHistory() {
        history.title = title.trimmingCharacters(in: .whitespaces)
        history.category = category.isEmpty ? "Sonstiges" : category.trimmingCharacters(in: .whitespaces)
        history.year = year
        history.budget = Double(budget) ?? 0
        history.note = note
        history.link = linkValidation.isValid ? linkValidation.sanitized : link.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
