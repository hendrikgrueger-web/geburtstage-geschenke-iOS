import SwiftUI
import SwiftData

struct EditGiftIdeaSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let person: PersonRef
    @Bindable var idea: GiftIdea

    @State private var title: String
    @State private var note: String
    @State private var estimatedPrice: Double
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
        self._estimatedPrice = State(initialValue: idea.budgetMax > 0 ? idea.budgetMax : idea.budgetMin)
        self._link = State(initialValue: idea.link)
        self._tagsInput = State(initialValue: idea.tags.joined(separator: ", "))
        self._status = State(initialValue: idea.status)
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
                        Image(systemName: "arrow.up.right.square").foregroundStyle(AppColor.primary)
                    }
                    .accessibilityLabel(String(localized: "Link öffnen"))
                }
            }
        }
    }

    private var budgetSection: some View {
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
    }

    private var tagsSection: some View {
        Section("Tags") {
            TextField("Getrennt durch Kommas", text: $tagsInput).textInputAutocapitalization(.never)
            if let error = tagsValidation {
                Text(error.errorDescription ?? "").font(.caption).foregroundStyle(AppColor.danger)
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
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                    .accessibilityLabel(String(localized: "Abbrechen"))
                    .accessibilityHint(String(localized: "Schließt das Formular ohne zu speichern"))
                }

                ToolbarItem(placement: .topBarTrailing) {
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
                    .accessibilityLabel(String(localized: "Speichern"))
                    .accessibilityHint(title.trimmingCharacters(in: .whitespaces).isEmpty ? String(localized: "Titel muss ausgefüllt sein") : String(localized: "Speichert die Änderungen"))
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
        idea.title = title
        idea.note = note
        idea.budgetMin = estimatedPrice
        idea.budgetMax = estimatedPrice
        idea.link = linkValidation.isValid ? linkValidation.sanitized : link.trimmingCharacters(in: .whitespacesAndNewlines)
        idea.status = status

        let tags = tagsInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        idea.tags = tags
        WidgetDataService.shared.updateWidgetData(from: modelContext)
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
