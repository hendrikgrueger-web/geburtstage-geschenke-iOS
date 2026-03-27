import SwiftUI

struct LegalView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                    // Impressum
                    LegalSection(
                        title: "Angaben gemäß § 5 DDG",
                        content: "Grüpi GmbH\nRennekamp 19\n59494 Soest\n\nVertreten durch die Geschäftsführer:\nHendrik Grüger, Sebastian Mause\n\nE-Mail: hendriks-apps@gruepi.de\nWeb: gruepi.de\n\nRegistergericht: Amtsgericht Arnsberg\nRegisternummer: HRB 12564\nUSt-IdNr.: DE322907053"
                    )

                    // EU-Streitschlichtung
                    LegalSection(
                        title: "EU-Streitschlichtung",
                        content: "Die Europäische Kommission stellt eine Plattform zur Online-Streitbeilegung (OS) bereit:\nhttps://ec.europa.eu/consumers/odr/\n\nWir sind nicht bereit oder verpflichtet, an Streitbeilegungsverfahren vor einer Verbraucherschlichtungsstelle teilzunehmen."
                    )

                    // Haftungsausschluss
                    LegalSection(
                        title: "Haftungsausschluss",
                        content: "Die App wird ohne Gewährleistung bereitgestellt. Der Anbieter übernimmt keine Haftung für Schäden, die durch die Nutzung entstehen.\n\nKI-generierte Geschenkvorschläge sind unverbindlich. Sie werden algorithmisch erstellt und können unpassend oder fehlerhaft sein. Der Anbieter übernimmt keine Verantwortung für die Qualität oder Eignung der KI-Vorschläge."
                    )

                    // Urheberrecht
                    LegalSection(
                        title: "Urheberrecht",
                        content: "Der App-Code und das Design sind urheberrechtlich geschützt. Die App verwendet SF Symbols und Standard-UI-Komponenten von Apple Inc., die Apples Nutzungsbedingungen unterliegen."
                    )

                    // Datenschutz
                    LegalSection(
                        title: "Datenschutz",
                        content: "Informationen zum Datenschutz findest du in der Datenschutzerklärung (Einstellungen → Datenschutz)."
                    )

                    // App-Info
                    LegalSection(
                        title: "App-Informationen",
                        content: "Name: Geschenke AI\nPlattform: iOS\nVersion: siehe Einstellungen → App-Info\nStand: März 2026"
                    )

                    Spacer(minLength: 32)
                }
                .padding()
        }
        .navigationTitle("Impressum")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppColor.background)
    }
}

// MARK: - Section Component

struct LegalSection: View {
    let title: LocalizedStringKey
    let content: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(AppColor.textPrimary)

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
