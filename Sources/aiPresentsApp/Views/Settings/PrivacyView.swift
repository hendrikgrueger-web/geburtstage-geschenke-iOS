import SwiftUI

struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                    // Auf einen Blick
                    PrivacySection(
                        icon: "checkmark.shield.fill",
                        iconColor: .green,
                        title: "Auf einen Blick",
                        content: "Diese App sammelt keine Daten für den Betreiber. Alles, was du eingibst, bleibt auf deinem Gerät. Kein eigener Server, keine eigene Datenbank, kein Tracking."
                    )

                    // Verantwortlicher
                    PrivacySection(
                        icon: "building.2.fill",
                        iconColor: AppColor.primary,
                        title: "Verantwortlicher (Art. 13 Abs. 1 DSGVO)",
                        content: "Grüpi GmbH\nRennekamp 19, 59494 Soest\nGeschäftsführer: Hendrik Grüger, Sebastian Mause\nE-Mail: hendriks-apps@gruepi.de\nWeb: gruepi.de"
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

                    // Speicherdauer
                    PrivacySection(
                        icon: "clock.fill",
                        iconColor: AppColor.primary,
                        title: "Speicherdauer",
                        content: "Deine Daten werden gespeichert, solange du die App nutzt. Bei Deinstallation werden alle lokalen Daten gelöscht. iCloud-Daten bleiben erhalten, bis du sie manuell löschst. KI-Anfragen werden nicht gespeichert (Zero Data Retention)."
                    )

                    // Deine Rechte
                    PrivacySection(
                        icon: "hand.raised.fill",
                        iconColor: .red,
                        title: "Deine Rechte (Art. 15–21 DSGVO)",
                        content: "Du hast folgende Rechte:\n\n• Auskunft (Art. 15): Welche Daten über dich gespeichert sind\n• Berichtigung (Art. 16): Falsche Daten korrigieren\n• Löschung (Art. 17): Alle Daten löschen (Einstellungen → Alle Daten löschen)\n• Einschränkung (Art. 18): Verarbeitung einschränken\n• Datenübertragbarkeit (Art. 20): Daten in maschinenlesbarem Format\n• Widerspruch (Art. 21): Der Verarbeitung widersprechen\n• Widerruf (Art. 7 Abs. 3): Einwilligung jederzeit widerrufen\n\nBerechtigungen (Kontakte, Benachrichtigungen) kannst du jederzeit in den iOS-Einstellungen widerrufen. Die App deinstallieren löscht alle lokal gespeicherten Daten.\n\nAnfragen per E-Mail an: hendriks-apps@gruepi.de"
                    )

                    // Beschwerderecht
                    PrivacySection(
                        icon: "exclamationmark.bubble.fill",
                        iconColor: .orange,
                        title: "Beschwerderecht",
                        content: "Du hast das Recht, dich bei einer Datenschutz-Aufsichtsbehörde zu beschweren (Art. 77 DSGVO).\n\nZuständige Aufsichtsbehörde:\nLandesbeauftragte für Datenschutz und Informationsfreiheit Nordrhein-Westfalen\nKavalleriestraße 2–4, 40213 Düsseldorf\npoststelle@ldi.nrw.de\nhttps://www.ldi.nrw.de"
                    )

                    // Kontakt
                    PrivacySection(
                        icon: "envelope.fill",
                        iconColor: AppColor.primary,
                        title: "Kontakt",
                        content: "Bei Fragen zum Datenschutz:\n\nGrüpi GmbH\nhendriks-apps@gruepi.de"
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
