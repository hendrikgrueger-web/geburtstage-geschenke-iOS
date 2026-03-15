import SwiftUI

struct PrivacyView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Auf einen Blick
                    PrivacySection(
                        icon: "checkmark.shield.fill",
                        iconColor: .green,
                        title: "Auf einen Blick",
                        content: "Diese App sammelt keine Daten für den Betreiber. Alles, was du eingibst, bleibt auf deinem Gerät. Kein eigener Server, keine eigene Datenbank, kein Tracking."
                    )

                    // Lokale Daten
                    PrivacySection(
                        icon: "iphone",
                        iconColor: AppColor.primary,
                        title: "Welche Daten werden gespeichert?",
                        content: "Die App speichert lokal auf deinem Gerät:\n\n• Namen und Geburtstage der Personen, die du einträgst\n• Deine Geschenkideen und Notizen\n• Erinnerungsregeln\n\nDiese Daten verlassen dein Gerät nicht — es sei denn, du aktivierst iCloud Sync (siehe unten)."
                    )

                    // iCloud
                    PrivacySection(
                        icon: "icloud.fill",
                        iconColor: .blue,
                        title: "iCloud Sync (optional)",
                        content: "Wenn du iCloud Sync in den Einstellungen aktivierst, werden deine Daten über Apples eigene iCloud-Infrastruktur zwischen deinen Apple-Geräten synchronisiert.\n\nDer Betreiber dieser App hat keinen Zugriff auf deine iCloud-Daten. Es gelten Apples Datenschutzrichtlinien:\napple.com/legal/privacy/de-ww/"
                    )

                    // KI-Vorschläge
                    PrivacySection(
                        icon: "sparkles",
                        iconColor: .purple,
                        title: "KI-Vorschläge (optional, mit Einwilligung)",
                        content: "Wenn du die KI-Funktion aktivierst (nach expliziter Einwilligung), werden folgende Daten an externe Dienste übertragen:\n\n• Vorname (für bessere, persönliche Vorschläge)\n• Geschlecht (lokal abgeleitet, z.B. \"weiblich\")\n• Altersgruppe (z.B. \"Mitte 30\", nicht das exakte Alter)\n• Beziehungstyp (z.B. \"Freund\", \"Mutter\")\n• Sternzeichen (berechnet)\n• Interessen/Hobbies (sofern eingetragen)\n• Budget-Rahmen\n• Titel vergangener Geschenke\n\nNICHT übertragen werden: Nachname, Geburtsdatum, exaktes Alter, Links, Notizen, Telefonnummern. Der Nachname verbleibt ausschließlich auf deinem Gerät.\n\nKeine dauerhafte Speicherung: Die KI-Anfragen werden mit Zero Data Retention (ZDR) gesendet — weder OpenRouter noch Google speichern deine Daten dauerhaft oder nutzen sie zum Training.\n\nDer Datenweg:\n• Cloudflare Workers (Proxy) → OpenRouter Inc. (USA) → Google Gemini (USA)\n\nDatenübertragung in die USA auf Basis von Standardvertragsklauseln (Art. 46 DSGVO).\nRechtsgrundlage: Art. 6 Abs. 1 lit. a DSGVO (Einwilligung).\n\nOhne Einwilligung werden keine Daten übertragen."
                    )

                    // Kontakte
                    PrivacySection(
                        icon: "person.2.fill",
                        iconColor: .orange,
                        title: "Kontakte-Import (optional)",
                        content: "Wenn du Kontakte aus deinem Adressbuch importierst, liest die App nur Namen und Geburtstage. Keine Telefonnummern, Adressen oder andere Kontaktdaten werden verwendet.\n\nDie importierten Daten werden ausschließlich lokal auf deinem Gerät gespeichert."
                    )

                    // Deine Rechte
                    PrivacySection(
                        icon: "hand.raised.fill",
                        iconColor: .red,
                        title: "Deine Rechte",
                        content: "Da alle Daten lokal auf deinem Gerät liegen, hast du die vollständige Kontrolle:\n\n• Alle Daten können jederzeit in den App-Einstellungen gelöscht werden (Einstellungen → Alle Daten löschen)\n• Berechtigungen (Kontakte, Benachrichtigungen) kannst du jederzeit in den iOS-Einstellungen widerrufen\n• Die App deinstallieren löscht alle lokal gespeicherten Daten"
                    )

                    // Kontakt
                    PrivacySection(
                        icon: "envelope.fill",
                        iconColor: AppColor.primary,
                        title: "Kontakt",
                        content: "Bei Fragen zum Datenschutz:\n\nHendrik Grüger\nhendrik@gruepi.de"
                    )

                    Text("Stand: März 2026")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)

                    Spacer(minLength: 32)
                }
                .padding()
            }
            .navigationTitle("Datenschutz")
            .navigationBarTitleDisplayMode(.inline)
            .background(AppColor.background)
        }
    }
}

// MARK: - Section Component

private struct PrivacySection: View {
    let icon: String
    let iconColor: Color
    let title: LocalizedStringKey
    let content: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 28)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppColor.textPrimary)
            }

            Text(content)
                .font(.body)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
