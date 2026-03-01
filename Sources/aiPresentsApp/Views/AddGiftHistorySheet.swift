import SwiftUI
import SwiftData

struct AddGiftHistorySheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let person: PersonRef

    @State private var title = ""
    @State private var category = ""
    @State private var year: Int

    private let calendar = Calendar.current
    private let currentYear: Int

    init(person: PersonRef) {
        self.person = person
        _year = State(initialValue: Calendar.current.component(.year, from: Date()))
        calendar = Calendar.current
        currentYear = calendar.component(.year, from: Date())
    }

    private var isTitleValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
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
        let history = GiftHistory(
            personId: person.id,
            title: title.trimmingCharacters(in: .whitespaces),
            category: category.isEmpty ? "Sonstiges" : category.trimmingCharacters(in: .whitespaces),
            year: year
        )

        modelContext.insert(history)
    }
}
