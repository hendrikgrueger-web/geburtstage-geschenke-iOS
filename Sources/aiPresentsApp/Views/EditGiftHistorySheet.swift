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
    @State private var link: String

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
                    }

                    TextField("Notizen", text: $note, axis: .vertical)
                        .lineLimit(3...6)

                    HStack {
                        Text("Link")
                        TextField("URL", text: $link)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)

                        if !link.isEmpty {
                            Button {
                                if let url = URL(string: link), UIApplication.shared.canOpenURL(url) {
                                    UIApplication.shared.open(url)
                                }
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
                        saveHistory()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func saveHistory() {
        history.title = title.trimmingCharacters(in: .whitespaces)
        history.category = category.isEmpty ? "Sonstiges" : category.trimmingCharacters(in: .whitespaces)
        history.year = year
        history.budget = Double(budget) ?? 0
        history.note = note
        history.link = link
    }
}
