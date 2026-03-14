import SwiftUI
import SwiftData

struct AddGiftIdeaSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let person: PersonRef

    @State private var title: String
    @State private var note: String
    @State private var estimatedPrice: Double
    @State private var link: String
    @State private var tagsInput: String
    @State private var status: GiftStatus
    @State private var formState = AppFormState()
    @State private var showingValidationError = false

    init(person: PersonRef) {
        self.person = person
        self._title = State(initialValue: "")
        self._note = State(initialValue: "")
        self._estimatedPrice = State(initialValue: 0)
        self._link = State(initialValue: "")
        self._tagsInput = State(initialValue: "")
        self._status = State(initialValue: .idea)
        self._formState = State(initialValue: AppFormState())
    }

    init(person: PersonRef, prefillTitle: String, prefillNote: String) {
        self.person = person
        self._title = State(initialValue: prefillTitle)
        self._note = State(initialValue: prefillNote)
        self._estimatedPrice = State(initialValue: 0)
        self._link = State(initialValue: "")
        self._tagsInput = State(initialValue: "")
        self._status = State(initialValue: .idea)
        self._formState = State(initialValue: AppFormState())
    }

    private var linkValidation: (sanitized: String, isValid: Bool) {
        URLValidator.validate(link)
    }

    private var tagsValidation: ValidationError? {
        FormValidator.validateTags(tagsInput)
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        tagsValidation == nil &&
        linkValidation.isValid
    }

    private var validationMessages: String {
        var messages: [String] = []
        if title.trimmingCharacters(in: .whitespaces).isEmpty { messages.append(String(localized: "- Titel darf nicht leer sein")) }
        if let error = tagsValidation { messages.append("- \(error.errorDescription ?? "")") }
        if !linkValidation.isValid && !link.trimmingCharacters(in: .whitespaces).isEmpty { messages.append(String(localized: "- Ungültige URL")) }
        return messages.joined(separator: "\n")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Geschenk") {
                    // SmartInputField for title with real-time validation
                    SmartInputField.titleField(
                        text: $title,
                        minLength: 2,
                        maxLength: 100,
                        placeholder: String(localized: "Name des Geschenks")
                    )

                    // SmartInputField for notes with character limit
                    SmartInputField.noteField(
                        text: $note,
                        maxLength: 500,
                        placeholder: String(localized: "Optionale Notizen")
                    )

                    // SmartInputField for URL with auto-https normalization
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
                                    .foregroundStyle(AppColor.primary)
                            }
                            .accessibilityLabel("Link öffnen")
                            .accessibilityHint("Öffnet den Link im Browser")
                        }
                    }
                }

                Section {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Geschätzter Preis")
                            Spacer()
                            Text(CurrencyManager.shared.formatAmountOrEmpty(estimatedPrice))
                                .foregroundStyle(estimatedPrice > 0 ? AppColor.primary : .secondary)
                                .fontWeight(.semibold)
                        }

                        Slider(value: $estimatedPrice,
                               in: AppConfig.Budget.sliderMinimum...AppConfig.Budget.sliderMaximum,
                               step: AppConfig.Budget.sliderStep) {
                            Text("Geschätzter Preis")
                        } minimumValueLabel: {
                            Text(CurrencyManager.shared.formatAmount(AppConfig.Budget.sliderMinimum)).font(.caption2).foregroundStyle(.secondary)
                        } maximumValueLabel: {
                            Text(CurrencyManager.shared.formatAmount(AppConfig.Budget.sliderMaximum)).font(.caption2).foregroundStyle(.secondary)
                        }
                        .tint(AppColor.primary)
                        .accessibilityLabel(String(localized: "Geschätzter Preis"))
                        .accessibilityValue(CurrencyManager.shared.formatAmount(estimatedPrice))
                    }
                    .padding(.vertical, 4)
                }

                Section("Tags") {
                    TextField("Getrennt durch Kommas", text: $tagsInput)
                        .textInputAutocapitalization(.never)
                        .accessibilityLabel("Tags")
                        .accessibilityHint("Gib bis zu 10 Tags getrennt durch Kommas ein, max 30 Zeichen pro Tag")

                    if let error = tagsValidation {
                        Text(error.errorDescription ?? "")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .accessibilityLabel("Fehler: \(error.errorDescription ?? "")")
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
                    .accessibilityHint("Wähle den Status der Geschenkidee aus")
                }
            }
            .navigationTitle("Geschenk-Idee")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .top) {
                Text("für \(person.displayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
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
                    .accessibilityHint(title.trimmingCharacters(in: .whitespaces).isEmpty ? String(localized: "Titel muss ausgefüllt sein") : String(localized: "Speichert die Geschenkidee"))
                }
            }
        }
        .presentationDragIndicator(.visible)
        .alert("Eingabe prüfen", isPresented: $showingValidationError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(validationMessages)
        }
    }

    private func saveGiftIdea() {
        let tags = tagsInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let linkValue = linkValidation.isValid ? linkValidation.sanitized : link.trimmingCharacters(in: .whitespacesAndNewlines)

        let idea = GiftIdea(
            personId: person.id,
            title: title,
            note: note,
            budgetMin: estimatedPrice,
            budgetMax: estimatedPrice,
            link: linkValue,
            status: status,
            tags: tags
        )

        modelContext.insert(idea)
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
