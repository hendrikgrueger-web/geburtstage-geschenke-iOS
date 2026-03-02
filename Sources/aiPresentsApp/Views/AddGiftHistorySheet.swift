import SwiftUI
import SwiftData

struct AddGiftHistorySheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let person: PersonRef

    @State private var title = ""
    @State private var category = ""
    @State private var year: Int
    @State private var budget = ""
    @State private var note = ""
    @State private var link = ""
    @State private var formState = FormState()
    @State private var showingValidationError = false

    private let calendar = Calendar.current
    private let currentYear: Int

    init(person: PersonRef) {
        self.person = person
        _year = State(initialValue: Calendar.current.component(.year, from: Date()))
        calendar = Calendar.current
        currentYear = calendar.component(.year, from: Date())
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

    var body: some View {
        NavigationStack {
            Form {
                Section("Geschenk") {
                    TextField("Was wurde verschenkt?", text: $title)
                        .textInputAutocapitalization(.sentences)
                        .accessibilityLabel("Geschenk-Titel")
                        .accessibilityHint("Gib den Namen des Geschenks ein")

                    TextField("Kategorie", text: $category)
                        .textInputAutocapitalization(.sentences)
                        .accessibilityLabel("Geschenk-Kategorie")
                        .accessibilityHint("z.B. Schmuck, Buch, Erlebnis, Geld")
                } footer: {
                    Text("z.B. Schmuck, Buch, Erlebnis, Geld")
                }

                Section("Details") {
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

                    TextField("Notizen", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityLabel("Notizen zum Geschenk")
                        .accessibilityHint("Optionale zusätzliche Informationen")

                    HStack {
                        Text("Link")
                        TextField("URL", text: $link)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            .accessibilityLabel("Link zum Geschenk")
                            .accessibilityHint("Optional: Link zur Webseite")

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

                Section("Wann") {
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
            }
            .navigationTitle("Geschenk vermerken")
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
                    .accessibilityHint(title.trimmingCharacters(in: .whitespaces).isEmpty ? "Titel muss ausgefüllt sein" : "Speichert das Geschenk")
                }
            }
        }
        .alert("Eingabe prüfen", isPresented: $showingValidationError) {
            Button("OK", role: .cancel) { }
        } message: {
            if !canSave {
                var messages: [String] = []

                if !isTitleValid {
                    messages.append("- Titel darf nicht leer sein")
                }

                if !isBudgetValid && !budget.isEmpty {
                    messages.append("- Ungültiges Budget")
                }

                if let error = categoryValidation {
                    messages.append("- \(error.errorDescription ?? "")")
                }

                if !linkValidation.isValid && !link.trimmingCharacters(in: .whitespaces).isEmpty {
                    messages.append("- Ungültige URL")
                }

                Text(messages.joined(separator: "\n"))
            }
        }
    }

    private func saveGiftHistory() {
        let linkValue = linkValidation.isValid ? linkValidation.sanitized : link.trimmingCharacters(in: .whitespacesAndNewlines)
        let history = GiftHistory(
            personId: person.id,
            title: title.trimmingCharacters(in: .whitespaces),
            category: category.isEmpty ? "Sonstiges" : category.trimmingCharacters(in: .whitespaces),
            year: year,
            budget: Double(budget) ?? 0,
            note: note,
            link: linkValue
        )

        modelContext.insert(history)
    }
}
