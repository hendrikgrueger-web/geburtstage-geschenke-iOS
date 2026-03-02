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
    @State private var formState = FormState()
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
        self._formState = State(initialValue: FormState())
    }

    private var isBudgetInvalid: Bool {
        let error = FormValidator.validateBudget(minString: budgetMin, maxString: budgetMax)
        formState.setError(error, for: "budget")
        return error != nil
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

    private var tagsValidation: ValidationError? {
        let error = FormValidator.validateTags(tagsInput)
        formState.setError(error, for: "tags")
        return error
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !isBudgetInvalid &&
        tagsValidation == nil &&
        linkValidation.isValid
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Geschenk") {
                    TextField("Titel", text: $title)

                    TextField("Notizen", text: $note, axis: .vertical)
                        .lineLimit(3...6)

                    HStack {
                        Text("Link")
                        TextField("URL", text: $link)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)

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
                        }
                    }
                }

                Section("Budget") {
                    HStack {
                        Text("Min")
                        TextField("€", text: $budgetMin)
                            .keyboardType(.decimalPad)
                    }

                    HStack {
                        Text("Max")
                        TextField("€", text: $budgetMax)
                            .keyboardType(.decimalPad)
                            .foregroundColor(isBudgetInvalid ? .red : .primary)
                    }

                    if isBudgetInvalid {
                        Text("Max darf nicht kleiner als Min sein")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Section("Tags") {
                    TextField("Getrennt durch Kommas", text: $tagsInput)
                        .textInputAutocapitalization(.never)

                    if let error = tagsValidation {
                        Text(error.errorDescription ?? "")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(GiftStatus.allCases, id: \.self) { status in
                            Text(statusText(for: status)).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Geschenkstatus")
                }
            }
            .navigationTitle("Idee bearbeiten")
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
                            saveGiftIdea()
                            HapticFeedback.success()
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

                if title.trimmingCharacters(in: .whitespaces).isEmpty {
                    messages.append("- Titel darf nicht leer sein")
                }

                if isBudgetInvalid {
                    messages.append("- Ungültiges Budget")
                }

                if let error = tagsValidation {
                    messages.append("- \(error.errorDescription ?? "")")
                }

                if !linkValidation.isValid && !link.trimmingCharacters(in: .whitespaces).isEmpty {
                    messages.append("- Ungültige URL")
                }

                Text(messages.joined(separator: "\n"))
            }
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
        case .idea: return "Idee"
        case .planned: return "Geplant"
        case .purchased: return "Gekauft"
        case .given: return "Verschenkt"
        }
    }
}
