import SwiftUI
import SwiftData

struct AddGiftIdeaSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let person: PersonRef

    @State private var title = ""
    @State private var note = ""
    @State private var budgetMin = ""
    @State private var budgetMax = ""
    @State private var link = ""
    @State private var tagsInput = ""
    @State private var status: GiftStatus = .idea

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
                    .disabled(title.isEmpty)
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
