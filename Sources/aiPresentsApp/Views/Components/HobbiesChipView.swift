import SwiftUI

/// Chip-basierte Eingabe für Hobbies und Interessen einer Person.
/// Einheitliches Design: Chips oben, "Eintrag hinzufügen"-Leiste darunter.
/// Maximum: 10 Hobbies pro Person. Wird in PersonDetailView verwendet.
struct HobbiesChipView: View {
    @Binding var hobbies: [String]
    let isEditable: Bool
    @State private var newHobby: String = ""
    @State private var showingInput = false

    private var suggestions: [String] {
        let lang = Locale.current.language.languageCode?.identifier
        if lang == "de" {
            return ["Sport", "Lesen", "Kochen", "Musik", "Reisen",
                    "Gaming", "Garten", "Technik", "Wellness", "Fotografie"]
        } else if lang == "fr" {
            return ["Sport", "Lecture", "Cuisine", "Musique", "Voyages",
                    "Jeux vidéo", "Jardinage", "Technologie", "Bien-être", "Photographie"]
        } else if lang == "es" {
            return ["Deporte", "Lectura", "Cocina", "Música", "Viajes",
                    "Videojuegos", "Jardinería", "Tecnología", "Bienestar", "Fotografía"]
        } else {
            return ["Sports", "Reading", "Cooking", "Music", "Travel",
                    "Gaming", "Gardening", "Tech", "Wellness", "Photography"]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Vorhandene Chips
            if !hobbies.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(hobbies, id: \.self) { hobby in
                        ChipView(text: hobby, isEditable: isEditable) {
                            withAnimation { hobbies.removeAll { $0 == hobby } }
                        }
                    }
                }
            }

            if isEditable && hobbies.count < 10 {
                if showingInput {
                    // Eingabefeld + Vorschläge
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            TextField("Hobby eingeben", text: $newHobby)
                                .textInputAutocapitalization(.words)
                                .onSubmit { addHobby() }

                            if !newHobby.isEmpty {
                                Button { addHobby() } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(AppColor.accent)
                                }
                            }

                            Button { showingInput = false } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // Vorschläge
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
                    }
                } else {
                    // "Eintrag hinzufügen"-Leiste
                    Button {
                        showingInput = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(AppColor.accent)
                            Text("Hobby hinzufügen")
                                .foregroundStyle(AppColor.accent)
                            Spacer()
                        }
                        .font(.subheadline)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "Hobby hinzufügen"))
                }
            } else if isEditable && hobbies.count >= 10 {
                Text("Maximum erreicht (10)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func addHobby() {
        let trimmed = newHobby.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !hobbies.contains(trimmed), hobbies.count < 10 else { return }
        withAnimation { hobbies.append(trimmed) }
        newHobby = ""
    }
}

// MARK: - ChipView

private struct ChipView: View {
    let text: String
    let isEditable: Bool
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.subheadline)
                .accessibilityHidden(true)
            if isEditable {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "\(text) entfernen"))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.fill.secondary)
        .clipShape(Capsule())
        .accessibilityLabel(text)
        .accessibilityHint(isEditable ? String(localized: "Doppeltippen zum Entfernen") : "")
    }
}

// MARK: - FlowLayout

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
