import SwiftUI

struct LegalView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Impressum")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Stand: März 2026")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 16)

                    // Legal Information
                    Group {
                        legalSection(
                            title: "Anbieter",
                            content: """
                            Hendrik Grüger
                            """
                        )

                        legalSection(
                            title: "Kontakt",
                            content: """
                            E-Mail: harryhirsch1878@gmail.com
                            """
                        )

                        legalSection(
                            title: "Haftungsausschluss",
                            content: """
                            Diese App wird "wie besehen" bereitgestellt. Der Anbieter übernimmt keine Gewähr für die Vollständigkeit, Richtigkeit oder Aktualität der bereitgestellten Informationen.

                            Der Anbieter haftet nicht für Schäden, die durch die Nutzung oder Nicht-Nutzung der Informationen entstehen. Dies gilt insbesondere bei direkten oder indirekten Schäden, einschließlich entgangenen Gewinns.
                            """
                        )

                        legalSection(
                            title: "Urheberrecht",
                            content: """
                            Alle Inhalte dieser App sind urheberrechtlich geschützt. Die Vervielfältigung, Bearbeitung oder Verbreitung bedarf der schriftlichen Zustimmung des Anbieters.

                            Die App verwendet System-Symbols und Standard-UI-Elemente von Apple Inc., die deren Urheberrecht unterliegen.
                            """
                        )

                        legalSection(
                            title: "Links zu Dritten",
                            content: """
                            Die App enthält Links zu externen Websites (z.B. für Geschenkideen). Der Anbieter hat keinen Einfluss auf deren Inhalt. Die Verantwortung für diese externen Inhalte liegt bei den jeweiligen Betreibern.

                            Zum Zeitpunkt der Verlinkung waren keine Rechtsverstöße erkennbar. Sollten sich Inhalte ändern, wird der Link unverzüglich entfernt.
                            """
                        )

                        legalSection(
                            title: "Datenschutz",
                            content: """
                            Informationen zum Datenschutz finden Sie in der Datenschutzerklärung in den Einstellungen.
                            """
                        )

                        legalSection(
                            title: "App-Informationen",
                            content: """
                            App-Name: ai-presents-app
                            Version: siehe Einstellungen
                            Plattform: iOS (iPhone)
                            """
                        )
                    }

                    Spacer(minLength: 32)
                }
                .padding()
            }
            .navigationTitle("Impressum")
            .navigationBarTitleDisplayMode(.inline)
            .background(AppColor.background)
        }
    }

    private func legalSection(title: String, content: String) -> some View {
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
