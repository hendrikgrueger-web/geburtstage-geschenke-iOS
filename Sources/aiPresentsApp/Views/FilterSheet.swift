import SwiftUI

struct FilterSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var filterHasIdeas: Bool?
    @Binding var filterRelation: String?

    let availableRelations: [String]
    let onReset: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Geschenkideen") {
                    Picker("Nur zeigen...", selection: $filterHasIdeas) {
                        Text("Alle Kontakte").tag(Bool?.none)
                        Text("Mit Ideen").tag(Bool?.some(true))
                        Text("Ohne Ideen").tag(Bool?.some(false))
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: filterHasIdeas) { _, _ in
                        HapticFeedback.selectionChanged()
                    }
                    .accessibilityLabel("Filter nach Geschenkideen")
                } footer: {
                    Text("Filtere Kontakte nach ob Geschenkideen existieren")
                }

                if !availableRelations.isEmpty {
                    Section("Beziehung") {
                        Picker("Beziehungstyp", selection: $filterRelation) {
                            Text("Alle").tag(String?.none)
                            ForEach(availableRelations, id: \.self) { relation in
                                Text(relation).tag(String?.some(relation))
                            }
                        }
                        .onChange(of: filterRelation) { _, _ in
                            HapticFeedback.selectionChanged()
                        }
                        .accessibilityLabel("Filter nach Beziehung")
                    } footer: {
                        Text("Filtere nach Beziehungsart")
                    }
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        onReset()
                        HapticFeedback.light()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        HapticFeedback.light()
                        dismiss()
                    }
                }
            }
        }
    }
}
