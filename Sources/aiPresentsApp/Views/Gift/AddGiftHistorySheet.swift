import SwiftUI
import SwiftData

struct AddGiftHistorySheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let person: PersonRef
    /// Richtung des Geschenks — `.given` (verschenkt) oder `.received` (erhalten).
    /// Steuert Platzhaltertexte, Titel und Footer-Texte im Formular.
    let direction: GiftDirection

    @State private var title = ""
    @State private var category = ""
    @State private var year: Int
    @State private var budget = ""
    @State private var note = ""
    @State private var link = ""
    @State private var formState = AppFormState()
    @State private var showingValidationError = false

    private let calendar = Calendar.current
    private let currentYear: Int

    init(person: PersonRef, direction: GiftDirection = .given) {
        self.person = person
        self.direction = direction
        _year = State(initialValue: Calendar.current.component(.year, from: Date()))
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
        if !isTitleValid { messages.append(String(localized: "- Titel darf nicht leer sein")) }
        if !isBudgetValid && !budget.isEmpty { messages.append(String(localized: "- Ungültiges Budget")) }
        if let error = categoryValidation { messages.append("- \(error.errorDescription ?? "")") }
        if !linkValidation.isValid && !link.trimmingCharacters(in: .whitespaces).isEmpty { messages.append(String(localized: "- Ungültige URL")) }
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
                        placeholder: direction == .given ? String(localized: "Was wurde verschenkt?") : String(localized: "Was hast du erhalten?")
                    )

                    // SmartInputField for category
                    SmartInputField(
                        title: String(localized: "Kategorie"),
                        text: $category,
                        placeholder: String(localized: "z.B. Schmuck, Buch, Erlebnis, Geld"),
                        validator: { value in
                            if !value.isEmpty {
                                return ValidationHelper.validateMaxLength(value, maxLength: 50, fieldName: String(localized: "Kategorie"))
                            }
                            return .valid
                        }
                    )
                } header: {
                    Text("Geschenk")
                } footer: {
                    Text("z.B. Schmuck, Buch, Erlebnis, Geld")
                }

                Section("Details") {
                    // SmartInputField for budget with number validation
                    HStack {
                        Text("Budget")
                        TextField("€", text: $budget)
                            .keyboardType(.decimalPad)
                            .foregroundColor(isBudgetValid ? .primary : .red)
                            .accessibilityLabel("Budget")
                            .accessibilityHint("Gib das Budget in Euro ein")
                    }

                    if !isBudgetValid && !budget.isEmpty {
                        Text("Bitte gib eine gültige Zahl ein")
                            .font(.caption)
                            .foregroundColor(.red)
                            .accessibilityLabel("Fehler: Ungültiges Budget")
                    }

                    // SmartInputField for notes
                    SmartInputField.noteField(
                        text: $note,
                        maxLength: 500,
                        placeholder: String(localized: "Optionale Notizen")
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
                            .accessibilityHint("Öffnet den Link im Browser")
                        }
                    }
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
                    if direction == .given {
                        Text("Wähle das Jahr, in dem das Geschenk verschenkt wurde")
                    } else {
                        Text("Wähle das Jahr, in dem du das Geschenk erhalten hast")
                    }
                }
            }
            .navigationTitle(direction == .given ? String(localized: "Geschenk vermerken") : String(localized: "Erhaltenes Geschenk"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                    .accessibilityLabel("Abbrechen")
                    .accessibilityHint("Schließt das Formular ohne zu speichern")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Speichern") {
                        if canSave {
                            saveGiftHistory()
                            dismiss()
                        } else {
                            showingValidationError = true
                            HapticFeedback.error()
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                    .accessibilityLabel("Speichern")
                    .accessibilityHint(title.trimmingCharacters(in: .whitespaces).isEmpty ? String(localized: "Titel muss ausgefüllt sein") : String(localized: "Speichert das Geschenk"))
                }
            }
        }
        .alert("Eingabe prüfen", isPresented: $showingValidationError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(validationMessages)
        }
    }

    private func saveGiftHistory() {
        let linkValue = linkValidation.isValid ? linkValidation.sanitized : link.trimmingCharacters(in: .whitespacesAndNewlines)
        let history = GiftHistory(
            personId: person.id,
            title: title.trimmingCharacters(in: .whitespaces),
            category: category.isEmpty ? String(localized: "Sonstiges") : category.trimmingCharacters(in: .whitespaces),
            year: year,
            budget: Double(budget) ?? 0,
            note: note,
            link: linkValue,
            direction: direction
        )

        modelContext.insert(history)
    }
}
