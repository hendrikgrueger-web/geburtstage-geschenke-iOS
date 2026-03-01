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

                        Text("Angaben gemäß § 5 TMG")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 16)

                    // Legal Information
                    Group {
                        legalSection(
                            title: "Verantwortlich",
                            content: """
                            Hendrik Grüger
                            Harry (Digitaler Mitarbeiter)
                            """
                        )

                        legalSection(
                            title: "Kontakt",
                            content: """
                            E-Mail: harryhirsch1878@gmail.com
                            Telegram: @harryhirsch1878

                            Für Anfragen zur App oder Feedback kontaktieren Sie uns gerne über obenstehende Kanäle.
                            """
                        )

                        legalSection(
                            title: "Haftung für Inhalte",
                            content: """
                            Als Diensteanbieter sind wir gemäß § 7 Abs.1 TMG für eigene Inhalte auf diesen Seiten nach den allgemeinen Gesetzen verantwortlich. Nach §§ 8 bis 10 TMG sind wir als Diensteanbieter jedoch nicht verpflichtet, übermittelte oder gespeicherte fremde Informationen zu überwachen oder nach Umständen zu forschen, die auf eine rechtswidrige Tätigkeit hinweisen.
                            """
                        )

                        legalSection(
                            title: "Haftung für Links",
                            content: """
                            Unser Angebot enthält Links zu externen Websites Dritter, auf deren Inhalte wir keinen Einfluss haben. Deshalb können wir für diese fremden Inhalte auch keine Gewähr übernehmen. Für die Inhalte der verlinkten Seiten ist stets der jeweilige Anbieter oder Betreiber der Seiten verantwortlich.
                            """
                        )

                        legalSection(
                            title: "Urheberrecht",
                            content: """
                            Die durch die App-Betreiber erstellten Inhalte und Werke auf diesen Seiten unterliegen dem deutschen Urheberrecht. Die Vervielfältigung, Bearbeitung, Verbreitung und jede Art der Verwertung außerhalb der Grenzen des Urheberrechtes bedürfen der schriftlichen Zustimmung des jeweiligen Autors bzw. Erstellers.
                            """
                        )

                        legalSection(
                            title: "App-Informationen",
                            content: """
                            Version: 1.0.0
                            Plattform: iOS (iPhone)
                            Verfügbar im App Store

                            Diese App wurde mit SwiftUI entwickelt und entspricht den Apple Human Interface Guidelines.
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
