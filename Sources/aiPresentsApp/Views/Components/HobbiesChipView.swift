import SwiftUI

/// Chip-basierte Eingabe für Hobbies und Interessen einer Person.
/// Zeigt vorhandene Hobbies als Chips, bietet Textfeld + Vorschläge zum Hinzufügen.
/// Maximum: 10 Hobbies pro Person. Wird in PersonDetailView verwendet.
struct HobbiesChipView: View {
    @Binding var hobbies: [String]
    let isEditable: Bool
    @State private var newHobby: String = ""

    private let suggestions = [
        "Sport", "Lesen", "Kochen", "Musik", "Reisen",
        "Gaming", "Garten", "Technik", "Wellness", "Fotografie"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Flow-Layout mit bestehenden Chips
            if !hobbies.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(hobbies, id: \.self) { hobby in
                        ChipView(text: hobby, isEditable: isEditable) {
                            withAnimation { hobbies.removeAll { $0 == hobby } }
                        }
                    }
                }
            }

            if isEditable {
                if hobbies.count < 10 {
                    // Textfeld zum Hinzufuegen
                    HStack {
                        TextField("Hobby hinzufügen", text: $newHobby)
                            .textInputAutocapitalization(.words)
                            .onSubmit { addHobby() }

                        if !newHobby.isEmpty {
                            Button { addHobby() } label: {
                                Image(systemName: "plus.circle.fill")
                            }
                        }
                    }

                    // Vorschlaege (nur noch nicht gewaehlte anzeigen)
                    let available = suggestions.filter { !hobbies.contains($0) }
                    if !available.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(available.prefix(5), id: \.self) { suggestion in
                                    Button {
                                        withAnimation { hobbies.append(suggestion) }
                                    } label: {
                                        Text(suggestion)
                                            .font(.caption)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(.fill.tertiary)
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                } else {
                    Text("Maximum erreicht (10 Hobbies)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    /// Fügt ein neues Hobby hinzu — nur wenn nicht leer, nicht doppelt und unter dem Limit von 10.
    private func addHobby() {
        let trimmed = newHobby.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !hobbies.contains(trimmed), hobbies.count < 10 else { return }
        withAnimation { hobbies.append(trimmed) }
        newHobby = ""
    }
}

// MARK: - ChipView

/// Einzelner Chip mit Text und optionalem Entfernen-Button.
/// Wird innerhalb von `HobbiesChipView` im FlowLayout dargestellt.
private struct ChipView: View {
    let text: String
    let isEditable: Bool
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.subheadline)
            if isEditable {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.fill.secondary)
        .clipShape(Capsule())
    }
}

// MARK: - FlowLayout

/// Custom Layout, das Subviews horizontal anordnet und bei Platzmangel automatisch umbricht.
/// Wird für die Chip-Darstellung verwendet, damit Hobbies mehrzeilig fließen.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}
