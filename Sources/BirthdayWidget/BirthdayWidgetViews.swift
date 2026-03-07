import SwiftUI
import WidgetKit

// MARK: - Color Palette

/// Private Farb-Palette für das Widget.
///
/// **Warum eigene Farben?** WidgetKit-Extensions können nicht auf das App-Target zugreifen — daher
/// duplizieren wir hier die System-Farben statt `AppColor` zu importieren. Dies entspricht dem Apple HIG
/// und garantiert Konsistenz über beide Plattformen (App + Widget).
private enum WidgetColors {
    static let birthdayToday = Color(UIColor.systemPink)    // Heute: Rosa/Pink Highlight
    static let birthdaySoon = Color(UIColor.systemOrange)   // ≤2 Tage: Orange Warnung
    static let accent = Color(UIColor.systemOrange)         // Allgemeine Akzente
    static let birthdayUpcoming = Color(UIColor.systemBlue) // >7 Tage: Blau neutral
    static let success = Color(UIColor.systemGreen)         // Gekauft/Erledigt: Grün
}

// MARK: - Medium Widget View

/// Mittleres Widget-Format (systemMedium) — zeigt die nächsten 3 Geburtstage.
///
/// **Layout:**
/// - Header: "Nächste Geburtstage" mit Torten-Icon
/// - Body: bis zu 3 Birthday-Rows oder leere Platzhalter-Nachricht
/// - Footer: "+N weitere"-Hinweis wenn mehr als 3 Einträge vorhanden
///
/// **Deep-Linking:** Tipp auf einen Eintrag → `aipresents://person/{UUID}`
struct BirthdayWidgetMediumView: View {
    let entry: BirthdayTimelineEntry

    private var displayEntries: [WidgetBirthdayEntry] {
        Array(entry.birthdays.prefix(3))  // Max. 3 Einträge im Medium-Format
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack {
                Image(systemName: "birthday.cake.fill")
                    .foregroundStyle(Color.accentColor)
                Text("Nächste Geburtstage")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            if displayEntries.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "gift")
                            .font(.title2)
                            .foregroundStyle(.quaternary)
                        Text("Keine Geburtstage")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                ForEach(displayEntries, id: \.id) { birthday in
                    Link(destination: URL(string: "aipresents://person/\(birthday.id)")!) {
                        BirthdayWidgetRow(entry: birthday)
                    }
                    .accessibilityLabel(birthday.daysUntil == 0
                        ? String(localized: "\(birthday.displayName), hat heute Geburtstag")
                        : String(localized: "\(birthday.displayName), Geburtstag in \(birthday.daysUntil) Tagen"))
                }

                if entry.birthdays.count > 3 {
                    Spacer(minLength: 0)
                    HStack {
                        Spacer()
                        Text("+\(entry.birthdays.count - 3) weitere")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
        .widgetURL(URL(string: "aipresents://")!)
    }
}

// MARK: - Large Widget View

/// Großes Widget-Format (systemLarge) — zeigt die nächsten 7 Geburtstage.
///
/// **Layout:**
/// - Header: "Nächste Geburtstage" mit Torten-Icon
/// - Body: bis zu 7 Birthday-Rows mit Trennlinien zwischen Einträgen
/// - Footer: "+N weitere"-Hinweis wenn mehr als 7 Einträge vorhanden
///
/// **Deep-Linking:** Tipp auf einen Eintrag → `aipresents://person/{UUID}`
struct BirthdayWidgetLargeView: View {
    let entry: BirthdayTimelineEntry

    private var displayEntries: [WidgetBirthdayEntry] {
        Array(entry.birthdays.prefix(7))  // Max. 7 Einträge im Large-Format
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack {
                Image(systemName: "birthday.cake.fill")
                    .foregroundStyle(Color.accentColor)
                Text("Nächste Geburtstage")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            if displayEntries.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "gift")
                            .font(.title)
                            .foregroundStyle(.quaternary)
                        Text("Keine Geburtstage")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                ForEach(displayEntries, id: \.id) { birthday in
                    Link(destination: URL(string: "aipresents://person/\(birthday.id)")!) {
                        BirthdayWidgetRow(entry: birthday)
                    }
                    .accessibilityLabel(birthday.daysUntil == 0
                        ? String(localized: "\(birthday.displayName), hat heute Geburtstag")
                        : String(localized: "\(birthday.displayName), Geburtstag in \(birthday.daysUntil) Tagen"))
                    if birthday.id != displayEntries.last?.id {
                        Divider()
                    }
                }

                if entry.birthdays.count > 7 {
                    Spacer(minLength: 0)
                    HStack {
                        Spacer()
                        Text("+\(entry.birthdays.count - 7) weitere")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .containerBackground(.fill.tertiary, for: .widget)
        .widgetURL(URL(string: "aipresents://")!)
    }
}

// MARK: - Row View (shared)

/// Eine einzelne Birthday-Row — wird in Medium und Large Widget verwendet.
///
/// **Komponenten (von links nach rechts):**
/// 1. Avatar-Kreis mit 2-Buchstaben-Initialen (farbig basierend auf Countdown)
/// 2. Name + Alter-Angabe
/// 3. Gift-Status Badge (gekauft/geplant/X Ideen/—)
/// 4. Countdown-Badge (heute/Tage bis zum Geburtstag)
///
/// **Deep-Linking:** Jede Row ist ein tappable Link → `aipresents://person/{personUUID}`
struct BirthdayWidgetRow: View {
    let entry: WidgetBirthdayEntry

    var body: some View {
        HStack(spacing: 10) {
            // Avatar-Kreis mit 2-Buchstaben-Initialen (dekorativ)
            ZStack {
                Circle()
                    .fill(countdownColor.opacity(0.2))
                Text(twoLetterInitials(for: entry.displayName))
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(countdownColor)
            }
            .frame(width: 28, height: 28)
            .accessibilityHidden(true)

            // Name + Alter
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .privacySensitive()
                if entry.nextAge > 0 {
                    Text("wird \(entry.nextAge)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .privacySensitive()
                }
            }

            Spacer()

            // Gift-Status Badge
            giftStatusBadge

            // Countdown
            countdownBadge
        }
    }

    // MARK: - Gift Status Badge

    @ViewBuilder
    private var giftStatusBadge: some View {
        if entry.skipGift {
            statusText("—", color: .gray)
        } else {
            switch entry.giftStatus {
            case "purchased":
                HStack(spacing: 2) {
                    Image(systemName: "checkmark")
                        .font(.system(.caption2, design: .default, weight: .bold))
                    Text("Gekauft")
                        .font(.caption2)
                }
                .foregroundStyle(WidgetColors.success)
            case "planned":
                statusText(String(localized: "Geplant"), color: Color.accentColor)
            case _ where entry.giftStatus.hasPrefix("ideas:"):
                let count = entry.giftStatus.replacingOccurrences(of: "ideas:", with: "")
                statusText(count == "1" ? String(localized: "1 Idee") : String(localized: "\(count) Ideen"), color: WidgetColors.accent)
            default:
                EmptyView()
            }
        }
    }

    private func statusText(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(color)
    }

    // MARK: - Countdown Badge

    private var countdownBadge: some View {
        Text(countdownText)
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(countdownColor, in: .rect(cornerRadius: 6))
            .accessibilityLabel(
                entry.daysUntil == 0
                    ? String(localized: "Heute")
                    : String(localized: "In \(entry.daysUntil) Tagen")
            )
    }

    private var countdownText: String {
        if entry.daysUntil == 0 {
            return String(localized: "Heute")
        } else {
            return String(localized: "\(entry.daysUntil) T.")
        }
    }

    /// Bestimmt die Countdown-Badge-Farbe basierend auf Tagen bis Geburtstag.
    /// - 0 Tage (heute): Rose (sofort)
    /// - ≤2 Tage: Orange (bald — zeitnah kaufen)
    /// - ≤7 Tage: Orange (diese Woche)
    /// - >7 Tage: Blau (aufkommend — nicht dringend)
    private var countdownColor: Color {
        if entry.daysUntil == 0 {
            return WidgetColors.birthdayToday   // Heute: Rose
        } else if entry.daysUntil <= 2 {
            return WidgetColors.birthdaySoon    // Bald: Orange
        } else if entry.daysUntil <= 7 {
            return WidgetColors.accent          // Diese Woche: Orange
        } else {
            return WidgetColors.birthdayUpcoming  // Aufkommend: Blau
        }
    }

    /// Konvertiert einen Namen zu 2-Buchstaben-Initialen für den Avatar.
    ///
    /// **Logik:**
    /// - Zwei+ Namen (Vor- und Nachname): erste Buchstabe von Vor- und Nachname
    /// - Ein Name: erste zwei Zeichen dieses Namens
    /// - Fallback: "?"
    ///
    /// - Parameter name: Vollständiger Name (z.B. "John Smith", "Sting", "A")
    /// - Returns: 2-Zeichen-String oder "?" bei Leere
    private func twoLetterInitials(for name: String) -> String {
        let parts = name.split(separator: " ").filter { !$0.isEmpty }
        if parts.count >= 2,
           let first = parts.first?.first,
           let last = parts.last?.first {
            return "\(first)\(last)"
        } else if let first = name.first {
            let secondIndex = name.index(after: name.startIndex)
            if secondIndex < name.endIndex {
                return "\(first)\(name[secondIndex])"
            }
            return String(first)
        }
        return "?"
    }
}
