import SwiftUI

struct PrivacyView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Datenschutz")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Stand: März 2026")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 16)

                    // Privacy Overview
                    Group {
                        privacySection(
                            title: "Datenschutzerklärung",
                            content: """
                            Die ai-presents-app respektiert Ihre Privatsphäre und schützt Ihre persönlichen Daten. Diese App wurde nach dem Prinzip "Privacy by Design" entwickelt.
                            """
                        )

                        privacySection(
                            title: "Datenverarbeitung",
                            content: """
                            Alle persönlichen Daten (Kontakte, Geschenkideen) werden lokal auf Ihrem Gerät gespeichert. Keine personenbezogenen Daten werden an Dritte übermittelt oder in Cloud-Diensten gespeichert.

                            Optional können Sie iCloud-Sync aktivieren, um Ihre Daten auf Ihren Apple-Geräten zu synchronisieren. Diese Daten werden verschlüsselt in Ihrem persönlichen iCloud-Account gespeichert.
                            """
                        )

                        privacySection(
                            title: "Zugriffsrechte",
                            content: """
                            • Kontakte: Nur für Geburtstags-Import. Nur Namen und Geburtstage werden verwendet.
                            • Benachrichtigungen: Für Geburtstags-Erinnerungen. Lokal auf Ihrem Gerät.
                            """
                        )

                        privacySection(
                            title: "AI-Funktionen",
                            content: """
                            Die optionalen AI-Geschenkideen senden nur minimalen Kontext (Alter, Geschlecht, Beziehung) an OpenRouter. Ihre Kontakte und persönlichen Geschenkideen verlassen niemals Ihr Gerät.
                            """
                        )

                        privacySection(
                            title: "Ihre Rechte",
                            content: """
                            Sie haben jederzeit das Recht auf:
                            • Auskunft über Ihre gespeicherten Daten
                            • Löschung aller Daten über die App-Einstellungen
                            • Widerruf der erteilten Berechtigungen in den iOS-Einstellungen
                            """
                        )

                        privacySection(
                            title: "Kontakt",
                            content: """
                            Bei Fragen zum Datenschutz erreichen Sie uns unter:
                            harryhirsch1878@gmail.com
                            """
                        )
                    }

                    Spacer(minLength: 32)
                }
                .padding()
            }
            .navigationTitle("Datenschutz")
            .navigationBarTitleDisplayMode(.inline)
            .background(AppColor.background)
        }
    }

    private func privacySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(AppColor.textPrimary)

            Text(content)
                .font(.body)
                .foregroundColor(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(AppColor.cardBackground)
        .cornerRadius(12)
    }
}
