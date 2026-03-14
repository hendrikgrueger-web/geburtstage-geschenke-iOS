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
                                .fill(AppColor.secondary.opacity(0.15))
                                .frame(width: 64, height: 64)
                            Image(systemName: "sparkles")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(AppColor.secondary)
                        }

                        VStack(spacing: 4) {
                            Text("KI-Assistent")
                                .font(.title2.bold())
                            Text("Anonymisierte Datenverarbeitung")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    // Übertragene Daten
                    ConsentSection(
                        icon: "arrow.up.circle.fill",
                        iconColor: .orange,
                        title: "Was wird übertragen?"
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            ConsentDataRow(icon: "person.fill", text: "Vorname (damit die KI deine Kontakte erkennt)")
                            ConsentDataRow(icon: "person.2.fill", text: "Geschlecht (lokal aus Name/Beziehung abgeleitet)")
                            ConsentDataRow(icon: "number", text: "Altersgruppe (z.B. \u{201E}Mitte 30\u{201C}, nicht das exakte Alter)")
                            ConsentDataRow(icon: "heart.fill", text: "Beziehungstyp (z.B. \u{201E}Freund/in\u{201C}, \u{201E}Mutter\u{201C})")
                            ConsentDataRow(icon: "star.fill", text: "Sternzeichen (aus Geburtsmonat und -tag)")
                            ConsentDataRow(icon: "tag.fill", text: "Hobbies und Interessen (sofern vorhanden)")
                            ConsentDataRow(icon: "eurosign.circle", text: "Budget-Rahmen (Min/Max für passende Vorschläge)")
                            ConsentDataRow(icon: "gift.fill", text: "Geschenkideen: Titel und Status (geplant/gekauft)")
                            ConsentDataRow(icon: "clock.arrow.circlepath", text: "Geschenkhistorie: Titel früher gemachter Geschenke")
                        }
                    }

                    // Nicht übertragen
                    ConsentSection(
                        icon: "xmark.shield.fill",
                        iconColor: .green,
                        title: "Was wird NICHT übertragen?"
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            ConsentDataRow(icon: "person.text.rectangle", text: "Nachname")
                            ConsentDataRow(icon: "calendar", text: "Geburtsdatum (kein Tag, Monat oder Jahr)")
                            ConsentDataRow(icon: "number.circle", text: "Exaktes Alter")
                            ConsentDataRow(icon: "link", text: "Links")
                            ConsentDataRow(icon: "note.text", text: "Notizen")
                            ConsentDataRow(icon: "phone.fill", text: "Kontaktdaten / Telefonnummer")
                        }
                    }

                    // Datenschutz-Prinzip
                    ConsentSection(
                        icon: "shield.checkmark.fill",
                        iconColor: .green,
                        title: "Datenschutz-Prinzip"
                    ) {
                        Text("Die KI kennt nur Vornamen, Altersgruppe und Beziehung — keine Nachnamen, keine Geburtsdaten, keine Kontaktdaten. Ein Vorname allein ist nicht personenbezogen.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Verarbeiter
                    ConsentSection(
                        icon: "building.2.fill",
                        iconColor: .blue,
                        title: "Wer verarbeitet die Daten?"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Cloudflare Inc. (USA)")
                                    .font(.subheadline.bold())
                                Text("Proxy — schützt den API-Key, leitet Anfragen weiter")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("OpenRouter Inc. (USA)")
                                    .font(.subheadline.bold())
                                Text("API-Gateway — leitet Anfragen an das Sprachmodell weiter")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Google LLC — Google Gemini (USA)")
                                    .font(.subheadline.bold())
                                Text("Verarbeitet die KI-Anfragen")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Divider()

                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "globe")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                    .padding(.top, 2)
                                Text("Datenübertragung in die USA. Rechtsgrundlage: Standardvertragsklauseln gemäß Art. 46 DSGVO. Server-Standort: USA.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    // Rechtsgrundlage
                    ConsentSection(
                        icon: "doc.text.fill",
                        iconColor: AppColor.secondary,
                        title: "Rechtsgrundlage"
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Art. 6 Abs. 1 lit. a DSGVO (Einwilligung)")
                                .font(.subheadline.bold())
                            Text("Deine Einwilligung ist freiwillig. Die App funktioniert auch ohne KI-Features.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Widerruf jederzeit möglich: Einstellungen → KI-Assistent → \"Widerrufen\"")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Altersbestätigung (DSGVO Art. 8)
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "person.badge.shield.checkmark.fill")
                            .foregroundStyle(AppColor.secondary)
                            .font(.caption)
                            .padding(.top, 2)
                        Text("Mit der Zustimmung bestätige ich, dass ich mindestens 16 Jahre alt bin. (DSGVO Art. 8)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 4)

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
                        .tint(AppColor.secondary)
                        .controlSize(.large)

                        Button {
                            isPresented = false
                        } label: {
                            Text("Ablehnen")
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(.secondary)
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
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Hilfs-Views

private struct ConsentSection<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: LocalizedStringKey
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
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
    let text: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .font(.caption)
                .frame(width: 16)
                .padding(.top, 2)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }
}
