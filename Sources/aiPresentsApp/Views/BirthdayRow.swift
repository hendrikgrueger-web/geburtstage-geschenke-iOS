import SwiftUI

struct BirthdayRow: View {
    let person: PersonRef

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(AppColor.gradientBlue)
                .frame(width: 56, height: 56)
                .overlay {
                    Text(String(person.displayName.prefix(1)))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(person.displayName)
                    .font(.headline)
                    .foregroundColor(AppColor.textPrimary)

                Text(birthdayInfo)
                    .font(.subheadline)
                    .foregroundColor(AppColor.textSecondary)

                // Progress bar for birthdays < 30 days away
                if daysUntilBirthday <= 30 && daysUntilBirthday >= 0 {
                    progressView
                }
            }

            Spacer()

            if let giftCount = person.giftIdeas?.count, giftCount > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(giftCount)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(AppColor.accent)
                    Text("Ideen")
                        .font(.caption2)
                        .foregroundColor(AppColor.textSecondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(AppColor.accent.opacity(0.15))
                .cornerRadius(8)
            }
        }
        .padding(.vertical, 8)
        .listRowBackground(AppColor.cardBackground)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Tap für Details und Geschenkideen")
    }

    private var daysUntilBirthday: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let birthdayThisYear = calendar.date(bySetting: .year, value: calendar.component(.year, from: today), of: person.birthday) ?? person.birthday
        return calendar.dateComponents([.day], from: today, to: birthdayThisYear).day ?? 0
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
            return .red
        } else if daysUntilBirthday <= 7 {
            return .orange
        } else if daysUntilBirthday <= 14 {
            return AppColor.secondary
        } else {
            return AppColor.primary
        }
    }

    private var accessibilityLabel: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let birthdayThisYear = calendar.date(bySetting: .year, value: calendar.component(.year, from: today), of: person.birthday) ?? person.birthday
        let age = calendar.dateComponents([.year], from: person.birthday, to: birthdayThisYear).year ?? 0

        let daysUntil = calendar.dateComponents([.day], from: today, to: birthdayThisYear).day ?? 0

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
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let birthdayThisYear = calendar.date(bySetting: .year, value: calendar.component(.year, from: today), of: person.birthday) ?? person.birthday
        let age = calendar.dateComponents([.year], from: person.birthday, to: birthdayThisYear).year ?? 0

        let daysUntil = calendar.dateComponents([.day], from: today, to: birthdayThisYear).day ?? 0

        if daysUntil == 0 {
            return "🎉 Heute wird \(age)!"
        } else if daysUntil == 1 {
            return "Morgen wird \(age)"
        } else if daysUntil == -1 {
            return "Gestern wurde \(age)"
        } else if daysUntil < -1 {
            return "Vor \(-daysUntil) Tagen wurde \(age)"
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
}
