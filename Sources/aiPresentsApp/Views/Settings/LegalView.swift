import SwiftUI

struct LegalView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Anbieter
                    LegalSection(
                        title: "Anbieter",
                        content: "Gruepi GmbH\nGoethestraße 3\n36304 Alsfeld\n\nhendrik@gruepi.de\nGeschäftsführer: Hendrik Grüger\n\nHandelsregister: Amtsgericht Gießen, HRB 12564"
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
                        content: "Name: AI Präsente\nPlattform: iOS\nVersion: siehe Einstellungen → App-Info\nStand: März 2026"
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
}

// MARK: - Section Component

private struct LegalSection: View {
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
