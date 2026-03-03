import SwiftUI

/// DSGVO-konformer Einwilligungsdialog für KI-Features.
/// Zeigt welche Daten an OpenRouter / Google Gemini übertragen werden.
struct AIConsentSheet: View {
    @Binding var isPresented: Bool
    let onConsent: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.purple.opacity(0.15))
                                .frame(width: 64, height: 64)
                            Image(systemName: "sparkles")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(.purple)
                        }

                        VStack(spacing: 4) {
                            Text("KI-Assistent")
                                .font(.title2.bold())
                            Text("Datenverarbeitung durch Dritte")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    // Übertragene Daten
                    ConsentSection(
                        icon: "arrow.up.circle.fill",
                        iconColor: .orange,
                        title: "Welche Daten werden übertragen?"
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            ConsentDataRow(icon: "person.fill", text: "Vorname (aus Kontaktdaten)")
                            ConsentDataRow(icon: "number", text: "Alter (berechnet aus Geburtsdatum, nicht das Datum selbst)")
                            ConsentDataRow(icon: "heart.fill", text: "Beziehungstyp (z.B. \"Freund\", \"Mutter\")")
                            ConsentDataRow(icon: "star.fill", text: "Sternzeichen (berechnet, keine Personaldaten)")
                            ConsentDataRow(icon: "tag.fill", text: "Interessen/Tags (sofern vorhanden)")
                            ConsentDataRow(icon: "eurosign.circle", text: "Budget-Rahmen (Min/Max, für passende Vorschläge)")
                            ConsentDataRow(icon: "gift.fill", text: "Titel vergangener Geschenke (keine Notizen)")
                        }
                    }

                    // Nicht übertragen
                    ConsentSection(
                        icon: "xmark.shield.fill",
                        iconColor: .green,
                        title: "Was wird NICHT übertragen?"
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            ConsentDataRow(icon: "calendar", text: "Geburtsdatum")
                            ConsentDataRow(icon: "link", text: "Links")
                            ConsentDataRow(icon: "note.text", text: "Notizen")
                            ConsentDataRow(icon: "phone.fill", text: "Kontaktdaten / Telefonnummer")
                        }
                    }

                    // Verarbeiter
                    ConsentSection(
                        icon: "building.2.fill",
                        iconColor: .blue,
                        title: "Wer verarbeitet die Daten?"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("OpenRouter Inc. (USA)")
                                    .font(.subheadline.bold())
                                Text("Leitet Anfragen weiter an")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Google Vertex AI / Google AI Studio (USA)")
                                    .font(.subheadline.bold())
                                Text("Verarbeitet die KI-Anfragen")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Divider()

                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "globe")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                    .padding(.top, 2)
                                Text("Datenübertragung in die USA. Rechtsgrundlage: Standardvertragsklauseln gemäß Art. 46 DSGVO. Server-Standort: USA.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    // Rechtsgrundlage
                    ConsentSection(
                        icon: "doc.text.fill",
                        iconColor: .purple,
                        title: "Rechtsgrundlage"
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Art. 6 Abs. 1 lit. a DSGVO (Einwilligung)")
                                .font(.subheadline.bold())
                            Text("Deine Einwilligung ist freiwillig. Die App funktioniert auch ohne KI-Features (Demo-Modus).")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Widerruf jederzeit möglich: Einstellungen → KI-Assistent → \"Widerrufen\"")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Buttons
                    VStack(spacing: 12) {
                        Button {
                            AIConsentManager.shared.giveConsent()
                            isPresented = false
                            onConsent()
                        } label: {
                            Text("Zustimmen und KI aktivieren")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                        .controlSize(.large)

                        Button {
                            isPresented = false
                        } label: {
                            Text("Ablehnen")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .navigationTitle("Datenschutz-Einwilligung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Hilfs-Views

private struct ConsentSection<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 24)
                Text(title)
                    .font(.headline)
            }
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct ConsentDataRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .font(.caption)
                .frame(width: 16)
                .padding(.top, 2)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}
