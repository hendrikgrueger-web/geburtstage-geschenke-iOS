import SwiftUI

struct BirthdayRow: View {
    let person: PersonRef
    let onTap: (() -> Void)?
    let onQuickAdd: (() -> Void)?
    let showCountdown: Bool
    @State private var isAnimating = false

    init(person: PersonRef, onTap: (() -> Void)? = nil, onQuickAdd: (() -> Void)? = nil, showCountdown: Bool = true) {
        self.person = person
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

                if let giftCount = person.giftIdeas?.count, giftCount > 0 {
                    HStack(spacing: 4) {
                        Text("\(giftCount)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(AppColor.accent)
                        Text("Ideen")
                            .font(.caption2)
                            .foregroundColor(AppColor.textSecondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColor.accent.opacity(0.15))
                    .cornerRadius(8)
                }

                if let onQuickAdd = onQuickAdd {
                    Button(action: {
                        HapticFeedback.light()
                        onQuickAdd()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(AppColor.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 8)
        .listRowBackground(daysUntilBirthday <= 7 ? urgentBackgroundColor : AppColor.cardBackground)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Tap für Details und Geschenkideen")
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

    private var daysUntilBirthday: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return BirthdayCalculator.daysUntilBirthday(for: person.birthday, from: today) ?? 0
    }

    private var progressView: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Rectangle()
                    .fill(AppColor.textSecondary.opacity(0.2))
                    .frame(height: 4)
                    .cornerRadius(2)

                // Progress
                Rectangle()
                    .fill(progressColor)
                    .frame(width: geometry.size.width * CGFloat(progressFraction), height: 4)
                    .cornerRadius(2)
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
        label += "\(age) Jahre alt. "

        if let giftCount = person.giftIdeas?.count, giftCount > 0 {
            label += "\(giftCount) Geschenkidee\(giftCount == 1 ? "" : "n"). "
        }

        if daysUntil == 0 {
            label += "Geburtstag heute!"
        } else {
            label += "Geburtstag in \(daysUntil) Tagen."
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
            return "🎉 Heute wird \(age)!"
        } else if daysUntil == 1 {
            return "Morgen wird \(age)"
        } else if daysUntil == 365 {
            return "Nächstes Jahr wird \(age + 1)"
        } else if daysUntil < 7 {
            return "In \(daysUntil) Tagen wird \(age)"
        } else if daysUntil < 30 {
            return "\(daysUntil) Tage bis zum \(age). Geburtstag"
        } else {
            return "Wird \(age) (\(daysUntil) Tage)"
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
