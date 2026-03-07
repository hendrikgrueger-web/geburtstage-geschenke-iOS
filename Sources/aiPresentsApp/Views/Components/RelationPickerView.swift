import SwiftUI

/// Dedizierter Picker-Screen zum Auswählen und Verwalten von Beziehungstypen.
/// Wird via NavigationLink aus PersonDetailView und dem Edit-Sheet geöffnet.
///
/// **Navigation & Persistierung:**
/// - Vordefinierte Typen (z.B. Mutter, Vater, Freund/in): unveränderlich, immer oben
/// - Eigene Typen (user-defined): löschbar per Swipe-to-Delete, persistiert in UserDefaults via `RelationOptions.custom`
/// - "Sonstige": immer am Ende als universeller Fallback für atypische Beziehungen
///
/// **Verhalten:**
/// - Tipp auf eine Relation: sofortige Selection + automatisches Dismiss
/// - Button "Eigenen Typ hinzufügen": öffnet Alert mit TextField
/// - Gelöschte Relation ist aktuell selektiert → Fallback auf "Sonstige"
struct RelationPickerView: View {
    // MARK: - Bindings & Environment
    @Binding var selectedRelation: String
    @Environment(\.dismiss) private var dismiss

    // MARK: - State
    @State private var showingAddAlert = false
    @State private var newRelationName = ""
    @State private var customRelations = RelationOptions.custom

    // MARK: - Body
    var body: some View {
        List {
            // Vordefinierte Typen
            Section {
                ForEach(RelationOptions.predefined.filter { $0 != "Sonstige" }, id: \.self) { relation in
                    relationRow(relation)
                }
            } header: {
                Text(String(localized: "Vorgegeben"))
            }

            // Eigene Typen (nur anzeigen wenn vorhanden)
            if !customRelations.isEmpty {
                Section {
                    ForEach(customRelations, id: \.self) { relation in
                        relationRow(relation)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            RelationOptions.removeCustom(customRelations[index])
                            // Falls die gelöschte Relation aktuell ausgewählt ist → auf "Sonstige" fallen
                            if selectedRelation == customRelations[index] {
                                selectedRelation = "Sonstige"
                            }
                        }
                        customRelations = RelationOptions.custom
                    }
                } header: {
                    Text(String(localized: "Eigene"))
                }
            }

            // "Sonstige" + Hinzufügen-Button — immer am Ende
            Section {
                relationRow("Sonstige")

                Button {
                    newRelationName = ""
                    showingAddAlert = true
                } label: {
                    Label(String(localized: "Eigenen Typ hinzufügen"), systemImage: "plus.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .navigationTitle(String(localized: "Beziehung"))
        .navigationBarTitleDisplayMode(.inline)
        .alert(String(localized: "Eigener Beziehungstyp"), isPresented: $showingAddAlert) {
            TextField(String(localized: "z. B. Oma, Onkel, Mentor"), text: $newRelationName)
                .textInputAutocapitalization(.words)
            Button(String(localized: "Hinzufügen")) {
                let trimmed = newRelationName.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                RelationOptions.addCustom(trimmed)
                customRelations = RelationOptions.custom
                selectedRelation = trimmed
                dismiss()
            }
            Button(String(localized: "Abbrechen"), role: .cancel) { }
        } message: {
            Text(String(localized: "Gib einen eigenen Beziehungstyp ein, z. B. \"Oma\", \"Onkel\" oder \"Mentor\"."))
        }
    }

    // MARK: - Subviews
    /// Selektierbare Relation als Button-Row mit optionalem Checkmark.
    /// - Parameter relation: Der Anzeige-Name der Relation (vordefiniert oder custom)
    /// - Returns: Button-Row mit lokalisierten Label und Checkmark-Indikator
    private func relationRow(_ relation: String) -> some View {
        Button {
            selectedRelation = relation
            dismiss()
        } label: {
            HStack {
                Text(RelationOptions.localizedDisplayName(for: relation))
                    .foregroundStyle(.primary)
                Spacer()
                // Checkmark anzeigen wenn diese Relation aktuell selektiert ist
                if selectedRelation == relation {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RelationPickerView(selectedRelation: .constant("Freund/in"))
    }
}
