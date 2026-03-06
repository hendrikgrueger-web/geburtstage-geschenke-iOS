import SwiftUI
import SwiftData

struct EditGiftIdeaSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let person: PersonRef
    @Bindable var idea: GiftIdea

    @State private var title: String
    @State private var note: String
    @State private var budgetMin: String
    @State private var budgetMax: String
    @State private var link: String
    @State private var tagsInput: String
    @State private var status: GiftStatus
    @State private var formState = AppFormState()
    @State private var showingValidationError = false

    init(person: PersonRef, idea: GiftIdea) {
        self.person = person
        self._idea = Bindable(idea)
        self._title = State(initialValue: idea.title)
        self._note = State(initialValue: idea.note)
        self._budgetMin = State(initialValue: idea.budgetMin == 0 ? "" : "\(idea.budgetMin)")
        self._budgetMax = State(initialValue: idea.budgetMax == 0 ? "" : "\(idea.budgetMax)")
        self._link = State(initialValue: idea.link)
        self._tagsInput = State(initialValue: idea.tags.joined(separator: ", "))
        self._status = State(initialValue: idea.status)
        self._formState = State(initialValue: AppFormState())
    }

    private var isBudgetInvalid: Bool {
        FormValidator.validateBudget(minString: budgetMin, maxString: budgetMax) != nil
    }

    private var linkValidation: (sanitized: String, isValid: Bool) {
        URLValidator.validate(link)
    }

    private var tagsValidation: ValidationError? {
        FormValidator.validateTags(tagsInput)
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !isBudgetInvalid &&
        tagsValidation == nil &&
        linkValidation.isValid
    }

    private var validationMessages: String {
        var messages: [String] = []
        if title.trimmingCharacters(in: .whitespaces).isEmpty { messages.append(String(localized: "- Titel darf nicht leer sein")) }
        if isBudgetInvalid { messages.append(String(localized: "- Ungültiges Budget")) }
        if let error = tagsValidation { messages.append("- \(error.errorDescription ?? "")") }
        if !linkValidation.isValid && !link.trimmingCharacters(in: .whitespaces).isEmpty { messages.append(String(localized: "- Ungültige URL")) }
        return messages.joined(separator: "\n")
    }

    private var giftSection: some View {
        Section("Geschenk") {
            SmartInputField.titleField(text: $title, minLength: 2, maxLength: 100, placeholder: String(localized: "Name des Geschenks"))
            SmartInputField.noteField(text: $note, maxLength: 500, placeholder: String(localized: "Optionale Notizen"))
            HStack {
                SmartInputField.urlField(text: $link, placeholder: "https://example.com")
                if linkValidation.isValid && !linkValidation.sanitized.isEmpty {
                    Button {
                        if let url = URL(string: linkValidation.sanitized) {
                            UIApplication.shared.open(url) { success in
                                if !success { AppLogger.ui.warning("Failed to open URL: \(linkValidation.sanitized)") }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.right.square").foregroundColor(.blue)
                    }
                    .accessibilityLabel("Link öffnen")
                }
            }
        }
    }

    private var budgetSection: some View {
        Section("Budget") {
            HStack {
                Text("Min")
                TextField("€", text: $budgetMin).keyboardType(.decimalPad)
            }
            HStack {
                Text("Max")
                TextField("€", text: $budgetMax).keyboardType(.decimalPad).foregroundColor(isBudgetInvalid ? .red : .primary)
            }
            if isBudgetInvalid {
                Text("Max darf nicht kleiner als Min sein").font(.caption).foregroundColor(.red)
            }
        }
    }

    private var tagsSection: some View {
        Section("Tags") {
            TextField("Getrennt durch Kommas", text: $tagsInput).textInputAutocapitalization(.never)
            if let error = tagsValidation {
                Text(error.errorDescription ?? "").font(.caption).foregroundColor(.red)
            }
        }
    }

    private var statusSection: some View {
        Section("Status") {
            Picker("Status", selection: $status) {
                ForEach(GiftStatus.allCases, id: \.self) { s in
                    Text(statusText(for: s)).tag(s)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                giftSection
                budgetSection
                tagsSection
                statusSection
            }
            .navigationTitle("Idee bearbeiten")
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
                            saveGiftIdea()
                            HapticFeedback.success()
                            dismiss()
                        } else {
                            showingValidationError = true
                            HapticFeedback.error()
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                    .accessibilityLabel("Speichern")
                    .accessibilityHint(title.trimmingCharacters(in: .whitespaces).isEmpty ? String(localized: "Titel muss ausgefüllt sein") : String(localized: "Speichert die Änderungen"))
                }
            }
        }
        .alert("Eingabe prüfen", isPresented: $showingValidationError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(validationMessages)
        }
    }

    private func saveGiftIdea() {
        idea.title = title
        idea.note = note
        idea.budgetMin = Double(budgetMin) ?? 0
        idea.budgetMax = Double(budgetMax) ?? 0
        idea.link = linkValidation.isValid ? linkValidation.sanitized : link.trimmingCharacters(in: .whitespacesAndNewlines)
        idea.status = status

        let tags = tagsInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        idea.tags = tags
    }

    private func statusText(for status: GiftStatus) -> String {
        switch status {
        case .idea: return String(localized: "Idee")
        case .planned: return String(localized: "Geplant")
        case .purchased: return String(localized: "Gekauft")
        case .given: return String(localized: "Verschenkt")
        }
    }
}
