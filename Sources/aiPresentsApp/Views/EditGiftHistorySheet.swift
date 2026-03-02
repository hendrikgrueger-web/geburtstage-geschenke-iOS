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
    @State private var formState = FormState()
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

                    TextField("Kategorie", text: $category)
                        .textInputAutocapitalization(.sentences)
                } footer: {
                    Text("z.B. Schmuck, Buch, Erlebnis, Geld")
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

                Section("Details") {
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

                    TextField("Notizen", text: $note, axis: .vertical)
                        .lineLimit(3...6)

                    HStack {
                        Text("Link")
                        TextField("URL", text: $link)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)

                        if linkValidation.isValid && !linkValidation.sanitized.isEmpty {
                            Button {
                                UIApplication.shared.open(URL(string: linkValidation.sanitized)!)
                            } label: {
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundColor(.blue)
                            }
                            .accessibilityLabel("Link öffnen")
                        }
                    }
                }
            }
            .navigationTitle("Geschenk bearbeiten")
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

    private func saveHistory() {
        history.title = title.trimmingCharacters(in: .whitespaces)
        history.category = category.isEmpty ? "Sonstiges" : category.trimmingCharacters(in: .whitespaces)
        history.year = year
        history.budget = Double(budget) ?? 0
        history.note = note
        history.link = linkValidation.isValid ? linkValidation.sanitized : link.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
