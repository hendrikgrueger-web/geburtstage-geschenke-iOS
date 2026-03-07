import SwiftUI
import WidgetKit

// MARK: - Farben (Hex-Werte aus AppColor, da AppColor im Widget nicht verfügbar)

private enum WidgetColors {
    static let birthdayToday = Color.pink
    static let birthdaySoon = Color.orange
    static let accent = Color.orange
    static let birthdayUpcoming = Color.blue
    static let success = Color.green
}

// MARK: - Medium Widget View

struct BirthdayWidgetMediumView: View {
    let entry: BirthdayTimelineEntry

    private var displayEntries: [WidgetBirthdayEntry] {
        Array(entry.birthdays.prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack {
                Image(systemName: "birthday.cake.fill")
                    .foregroundStyle(WidgetColors.accent)
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

struct BirthdayWidgetLargeView: View {
    let entry: BirthdayTimelineEntry

    private var displayEntries: [WidgetBirthdayEntry] {
        Array(entry.birthdays.prefix(7))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack {
                Image(systemName: "birthday.cake.fill")
                    .foregroundStyle(WidgetColors.accent)
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

struct BirthdayWidgetRow: View {
    let entry: WidgetBirthdayEntry

    var body: some View {
        HStack(spacing: 10) {
            // Avatar-Kreis mit Initiale (dekorativ)
            ZStack {
                Circle()
                    .fill(countdownColor.opacity(0.2))
                Text(String(entry.displayName.prefix(1)))
                    .font(.caption)
                    .fontWeight(.bold)
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
                statusText(String(localized: "Geplant"), color: .blue)
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

    private var countdownColor: Color {
        if entry.daysUntil == 0 {
            return WidgetColors.birthdayToday
        } else if entry.daysUntil <= 2 {
            return WidgetColors.birthdaySoon
        } else if entry.daysUntil <= 7 {
            return WidgetColors.accent
        } else {
            return WidgetColors.birthdayUpcoming
        }
    }
}
