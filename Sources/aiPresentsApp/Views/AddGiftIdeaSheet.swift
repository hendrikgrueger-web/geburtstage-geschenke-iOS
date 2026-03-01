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

    init(person: PersonRef) {
        self.person = person
        self._title = State(initialValue: "")
        self._note = State(initialValue: "")
        self._budgetMin = State(initialValue: "")
        self._budgetMax = State(initialValue: "")
        self._link = State(initialValue: "")
        self._tagsInput = State(initialValue: "")
        self._status = State(initialValue: .idea)
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
    }

    private var isBudgetInvalid: Bool {
        guard let min = Double(budgetMin), let max = Double(budgetMax), min > 0, max > 0 else {
            return false
        }
        return max < min
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
                }

                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(GiftStatus.allCases, id: \.self) { status in
                            Text(statusText(for: status)).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
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
                        saveGiftIdea()
                        dismiss()
                    }
                    .disabled(title.isEmpty || isBudgetInvalid)
                }
            }
        }
    }

    private func saveGiftIdea() {
        let tags = tagsInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let idea = GiftIdea(
            personId: person.id,
            title: title,
            note: note,
            budgetMin: Double(budgetMin) ?? 0,
            budgetMax: Double(budgetMax) ?? 0,
            link: link,
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
