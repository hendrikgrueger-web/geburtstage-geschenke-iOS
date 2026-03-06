import SwiftUI
import SwiftData

struct AddGiftIdeaSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let person: PersonRef

    @State private var title: String
    @State private var note: String
    @State private var budgetMin: String
    @State private var budgetMax: String
    @State private var link: String
    @State private var tagsInput: String
    @State private var status: GiftStatus
    @State private var formState = AppFormState()
    @State private var showingValidationError = false
    @State private var budgetMinSlider: Double = 0
    @State private var budgetMaxSlider: Double = 0
    @State private var useSlider = false

    init(person: PersonRef) {
        self.person = person
        self._title = State(initialValue: "")
        self._note = State(initialValue: "")
        self._budgetMin = State(initialValue: "")
        self._budgetMax = State(initialValue: "")
        self._link = State(initialValue: "")
        self._tagsInput = State(initialValue: "")
        self._status = State(initialValue: .idea)
        self._formState = State(initialValue: AppFormState())
    }

    init(person: PersonRef, prefillTitle: String, prefillNote: String) {
        self.person = person
        self._title = State(initialValue: prefillTitle)
        self._note = State(initialValue: prefillNote)
        self._budgetMin = State(initialValue: "")
        self._budgetMax = State(initialValue: "")
        self._link = State(initialValue: "")
        self._tagsInput = State(initialValue: "")
        self._status = State(initialValue: .idea)
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
                                    .foregroundColor(.blue)
                            }
                            .accessibilityLabel("Link öffnen")
                            .accessibilityHint("Öffnet den Link im Browser")
                        }
                    }
                }

                Section("Budget") {
                    Toggle("Slider verwenden", isOn: $useSlider.animation())
                        .accessibleToggle(label: "Budget-Slider verwenden", isOn: useSlider)

                    if useSlider {
                        VStack(spacing: 16) {
                            HStack {
                                Text("Min")
                                Text("\(Int(budgetMinSlider)) €")
                                    .foregroundColor(AppColor.primary)
                                    .fontWeight(.semibold)
                                Spacer()
                            }

                            Slider(value: $budgetMinSlider,
                                   in: AppConfig.Budget.sliderMinimum...AppConfig.Budget.sliderMaximum,
                                   step: AppConfig.Budget.sliderStep) {
                                Text("Min Budget")
                            } minimumValueLabel: {
                                Text("\(Int(AppConfig.Budget.sliderMinimum))€").font(.caption2).foregroundColor(.secondary)
                            } maximumValueLabel: {
                                Text("\(Int(AppConfig.Budget.sliderMaximum))€").font(.caption2).foregroundColor(.secondary)
                            }
                            .tint(AppColor.primary)
                            .accessibilityLabel("Mindestbudget-Slider")
                            .accessibilityHint("Wähle das Mindestbudget")

                            HStack {
                                Text("Max")
                                Text("\(Int(budgetMaxSlider)) €")
                                    .foregroundColor(AppColor.accent)
                                    .fontWeight(.semibold)
                                Spacer()
                            }

                            Slider(value: $budgetMaxSlider,
                                   in: AppConfig.Budget.sliderMinimum...AppConfig.Budget.sliderMaximum,
                                   step: AppConfig.Budget.sliderStep) {
                                Text("Max Budget")
                            } minimumValueLabel: {
                                Text("\(Int(AppConfig.Budget.sliderMinimum))€").font(.caption2).foregroundColor(.secondary)
                            } maximumValueLabel: {
                                Text("\(Int(AppConfig.Budget.sliderMaximum))€").font(.caption2).foregroundColor(.secondary)
                            }
                            .tint(AppColor.accent)
                            .accessibilityLabel("Maximalbudget-Slider")
                            .accessibilityHint("Wähle das Maximalbudget")
                        }
                        .padding(.vertical, 8)
                    } else {
                        HStack {
                            Text("Min")
                            TextField("€", text: $budgetMin)
                                .keyboardType(.decimalPad)
                                .accessibilityLabel("Mindestbudget")
                                .accessibilityHint("Gib das Mindestbudget in Euro ein")
                        }

                        HStack {
                            Text("Max")
                            TextField("€", text: $budgetMax)
                                .keyboardType(.decimalPad)
                                .foregroundColor(isBudgetInvalid ? .red : .primary)
                                .accessibilityLabel("Maximalbudget")
                                .accessibilityHint("Gib das Maximalbudget in Euro ein")
                        }
                    }

                    if isBudgetInvalid {
                        Text("Max darf nicht kleiner als Min sein")
                            .font(.caption)
                            .foregroundColor(.red)
                            .accessibilityLabel("Fehler: Ungültiges Budget")
                    }
                }

                Section("Tags") {
                    TextField("Getrennt durch Kommas", text: $tagsInput)
                        .textInputAutocapitalization(.never)
                        .accessibilityLabel("Tags")
                        .accessibilityHint("Gib bis zu 10 Tags getrennt durch Kommas ein, max 30 Zeichen pro Tag")

                    if let error = tagsValidation {
                        Text(error.errorDescription ?? "")
                            .font(.caption)
                            .foregroundColor(.red)
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

        let minBudget = useSlider ? budgetMinSlider : (Double(budgetMin) ?? 0)
        let maxBudget = useSlider ? budgetMaxSlider : (Double(budgetMax) ?? 0)

        let idea = GiftIdea(
            personId: person.id,
            title: title,
            note: note,
            budgetMin: minBudget,
            budgetMax: maxBudget,
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
