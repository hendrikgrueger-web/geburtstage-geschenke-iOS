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
                        icon: "iphone",
                        iconColor: .green,
                        title: "KI-Vorschläge — vollständig lokal",
                        content: "Alle KI-Geschenkvorschläge werden ausschließlich auf deinem Gerät berechnet — durch Apple Intelligence (iOS 26+, iPhone 15 Pro oder neuer).\n\n• Kein Netzwerkzugriff\n• Keine Daten verlassen dein iPhone\n• Kein externer KI-Dienst\n• Kein API-Key oder Account nötig\n\nWenn Apple Intelligence auf deinem Gerät nicht verfügbar ist, zeigt die App Demo-Vorschläge an."
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
                        content: "Bei Fragen zum Datenschutz:\n\nHendrik Grüger\nharryhirsch1878@gmail.com"
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
    let title: String
    let content: String

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
