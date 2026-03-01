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

    private let calendar = Calendar.current
    private let currentYear: Int

    init(person: PersonRef) {
        self.person = person
        _year = State(initialValue: Calendar.current.component(.year, from: Date()))
        calendar = Calendar.current
        currentYear = calendar.component(.year, from: Date())
    }

    private var isTitleValid: Bool {
        FormValidator.validateTitle(title) == nil
    }

    private var linkValidation: (sanitized: String, isValid: Bool) {
        URLValidator.validate(link)
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

                Section("Details") {
                    HStack {
                        Text("Budget")
                        TextField("€", text: $budget)
                            .keyboardType(.decimalPad)
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
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Speichern") {
                        saveGiftHistory()
                        dismiss()
                    }
                    .disabled(!isTitleValid)
                }
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
