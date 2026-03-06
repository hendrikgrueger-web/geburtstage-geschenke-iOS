import SwiftUI

struct BirthdayRow: View {
    let person: PersonRef
    let giftIdeas: [GiftIdea]
    let onTap: (() -> Void)?
    let onQuickAdd: (() -> Void)?
    let showCountdown: Bool
    @State private var isAnimating = false

    init(person: PersonRef, giftIdeas: [GiftIdea] = [], onTap: (() -> Void)? = nil, onQuickAdd: (() -> Void)? = nil, showCountdown: Bool = true) {
        self.person = person
        self.giftIdeas = giftIdeas
        self.onTap = onTap
        self.onQuickAdd = onQuickAdd
        self.showCountdown = showCountdown
    }

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            PersonAvatar(person: person, size: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(person.displayName)
                    .font(.headline)
                    .foregroundColor(AppColor.textPrimary)

                Text(birthdayInfo)
                    .font(.subheadline)
                    .foregroundColor(birthdayTextColor)

                // Progress bar for birthdays < 30 days away
                if daysUntilBirthday <= 30 && daysUntilBirthday >= 0 {
                    progressView
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                if showCountdown && daysUntilBirthday >= 0 && daysUntilBirthday <= 30 {
                    BirthdayCountdownBadge(daysUntil: daysUntilBirthday)
                }

                giftStatusBadge
            }
        }
        .padding(.vertical, 8)
        .listRowBackground(daysUntilBirthday <= 7 ? urgentBackgroundColor : AppColor.cardBackground)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(String(localized: "Tap für Details und Geschenkideen"))
        .contentShape(Rectangle())
        .onTapGesture {
            HapticFeedback.light()
            onTap?()
        }
        .onAppear {
            if daysUntilBirthday <= 7 {
                isAnimating = true
            }
        }
    }

    // MARK: - Gift Status Badge

    @ViewBuilder
    private var giftStatusBadge: some View {
        if person.skipGift {
            statusPill(text: "—", color: .gray)
        } else if hasGiftWithStatus(.purchased) || hasGiftWithStatus(.given) {
            statusPill(icon: "checkmark", color: AppColor.success)
        } else if hasGiftWithStatus(.planned) {
            statusPill(text: String(localized: "Geplant"), color: .blue)
        } else if ideaCount > 0 {
            statusPill(text: String(localized: "\(ideaCount) Ideen"), color: AppColor.accent)
        }
    }

    private func statusPill(text: String? = nil, icon: String? = nil, color: Color) -> some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            if let text = text {
                Text(text)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .clipShape(.rect(cornerRadius: 8))
    }

    private var ideaCount: Int {
        giftIdeas.count
    }

    private func hasGiftWithStatus(_ status: GiftStatus) -> Bool {
        giftIdeas.contains { $0.status == status }
    }

    // MARK: - Computed Properties

    private var daysUntilBirthday: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return BirthdayCalculator.daysUntilBirthday(for: person.birthday, from: today) ?? 0
    }

    private var progressView: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(AppColor.textSecondary.opacity(0.2))
                    .frame(height: 4)
                    .clipShape(.rect(cornerRadius: 2))

                Rectangle()
                    .fill(progressColor)
                    .frame(width: geometry.size.width * CGFloat(progressFraction), height: 4)
                    .clipShape(.rect(cornerRadius: 2))
            }
        }
        .frame(height: 4)
    }

    private var progressFraction: Double {
        guard daysUntilBirthday > 0 else { return 1.0 }
        return 1.0 - (Double(daysUntilBirthday) / 30.0)
    }

    private var progressColor: Color {
        if daysUntilBirthday <= 2 {
            return AppColor.birthdaySoon
        } else if daysUntilBirthday <= 7 {
            return AppColor.birthdaySoon
        } else if daysUntilBirthday <= 14 {
            return AppColor.secondary
        } else {
            return AppColor.birthdayUpcoming
        }
    }

    private var accessibilityLabel: String {
        let today = Calendar.current.startOfDay(for: Date())
        guard let age = BirthdayCalculator.age(for: person.birthday, on: today),
              let daysUntil = BirthdayCalculator.daysUntilBirthday(for: person.birthday, from: today) else {
            return person.displayName
        }

        var label = "\(person.displayName), "
        label += String(localized: "\(age) Jahre alt. ")

        if person.skipGift {
            label += String(localized: "Kein Geschenk nötig. ")
        } else if !giftIdeas.isEmpty {
            label += String(localized: "\(giftIdeas.count) Geschenkidee\(giftIdeas.count == 1 ? "" : "n"). ")
        }

        if daysUntil == 0 {
            label += String(localized: "Geburtstag heute!")
        } else {
            label += String(localized: "Geburtstag in \(daysUntil) Tagen.")
        }

        return label
    }

    private var birthdayInfo: String {
        let today = Calendar.current.startOfDay(for: Date())
        guard let age = BirthdayCalculator.age(for: person.birthday, on: today),
              let daysUntil = BirthdayCalculator.daysUntilBirthday(for: person.birthday, from: today) else {
            return ""
        }

        if daysUntil == 0 {
            return "🎉 " + String(localized: "Heute wird \(age)!")
        } else if daysUntil == 1 {
            return String(localized: "Morgen wird \(age)")
        } else if daysUntil == 365 {
            return String(localized: "Nächstes Jahr wird \(age + 1)")
        } else if daysUntil < 7 {
            return String(localized: "In \(daysUntil) Tagen wird \(age)")
        } else if daysUntil < 30 {
            return String(localized: "\(daysUntil) Tage bis zum \(age). Geburtstag")
        } else {
            return String(localized: "Wird \(age) (\(daysUntil) Tage)")
        }
    }

    private var birthdayTextColor: Color {
        if daysUntilBirthday == 0 {
            return AppColor.birthdayToday
        } else if daysUntilBirthday <= 7 {
            return AppColor.birthdaySoon
        } else {
            return AppColor.textSecondary
        }
    }

    private var urgentBackgroundColor: Color {
        if daysUntilBirthday == 0 {
            return AppColor.birthdayToday.opacity(0.15)
        } else if daysUntilBirthday <= 3 {
            return AppColor.birthdaySoon.opacity(0.12)
        } else if daysUntilBirthday <= 7 {
            return AppColor.accent.opacity(0.1)
        } else {
            return AppColor.cardBackground
        }
    }
}
