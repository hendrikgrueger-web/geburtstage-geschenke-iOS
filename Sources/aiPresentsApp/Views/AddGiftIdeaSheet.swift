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
    @State private var formState = FormState()
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
        self._formState = State(initialValue: FormState())
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
                            .accessibilityLabel("Link öffnen")
                        }
                    }
                }

                Section("Budget") {
                    Toggle("Slider verwenden", isOn: $useSlider.animation())

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
                        }
                        .padding(.vertical, 8)
                    } else {
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
            .navigationTitle("Geschenk-Idee")
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
        case .idea: return "Idee"
        case .planned: return "Geplant"
        case .purchased: return "Gekauft"
        case .given: return "Verschenkt"
        }
    }
}
