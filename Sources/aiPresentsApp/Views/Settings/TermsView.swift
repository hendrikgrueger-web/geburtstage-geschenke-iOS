import SwiftUI

struct TermsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                LegalSection(
                    title: "Nutzungsberechtigung",
                    content: "Du musst mindestens 16 Jahre alt sein, um diese App zu nutzen. Eltern oder Erziehungsberechtigte können die App für Kinder unter 16 Jahren unter Aufsicht verwenden.\n\nDurch die Nutzung der App bestätigst du, das Mindestalter erreicht zu haben oder die Einwilligung deiner Erziehungsberechtigten zu besitzen."
                )

                LegalSection(
                    title: "KI-Funktionen",
                    content: "Die KI-Funktionen (Geschenkideen, Geburtstagsnachrichten) werden auf eigene Gefahr genutzt.\n\nWir garantieren nicht:\n• Die Richtigkeit oder Eignung der KI-Empfehlungen\n• Die Qualität der generierten Inhalte\n• Die Verfügbarkeit externer KI-Dienste\n\nDer Entwickler übernimmt keine Verantwortung für KI-generierte Inhalte oder Schäden aus deren Nutzung."
                )

                LegalSection(
                    title: "Haftungsausschluss",
                    content: "Die App wird \"wie besehen\" und \"wie verfügbar\" bereitgestellt. Wir übernehmen keine Garantien bezüglich Fehlerfreiheit, Sicherheit oder Verfügbarkeit.\n\nDer Entwickler haftet nicht für:\n• Verlust von Daten\n• Direkte oder indirekte Schäden aus Fehlfunktionen\n• Schäden aus Downtime oder Service-Unterbrechungen\n\nDie Gesamthaftung ist auf den von dir für die App gezahlten Betrag begrenzt."
                )

                LegalSection(
                    title: "Datenschutz",
                    content: "Deine persönlichen Daten werden gemäß unserer Datenschutzerklärung verarbeitet (Einstellungen → Datenschutz).\n\nWir sammeln nur die für die App-Funktionalität notwendigen Daten, verwenden keine Tracking-Tools oder Werbung, und du kannst deine Daten jederzeit löschen."
                )

                LegalSection(
                    title: "Geltendes Recht",
                    content: "Diese Nutzungsbedingungen unterliegen dem Recht der Bundesrepublik Deutschland.\n\nFür alle Streitigkeiten ist der Sitz des Entwicklers (Deutschland) zuständig, sofern zwingende gesetzliche Bestimmungen nichts anderes vorsehen. Bei Streitigkeiten wird zunächst eine einvernehmliche Lösung angestrebt."
                )

                LegalSection(
                    title: "Kontakt",
                    content: "Grüpi GmbH\nRennekamp 19\n59494 Soest\n\nE-Mail: hendriks-apps@gruepi.de\nGeschäftsführer: Hendrik Grüger, Sebastian Mause\n\nStand: März 2026"
                )

                Spacer(minLength: 32)
            }
            .padding()
        }
        .navigationTitle("Nutzungsbedingungen")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppColor.background)
    }
}
