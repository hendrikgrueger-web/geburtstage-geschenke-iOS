import SwiftUI
import SwiftData

struct QuickStatsView: View {
    @Query private var people: [PersonRef]
    @Query private var giftIdeas: [GiftIdea]

    var body: some View {
        HStack(spacing: 16) {
            statCard(
                icon: "person.2.fill",
                value: "\(people.count)",
                label: "Kontakte",
                color: AppColor.primary
            )

            statCard(
                icon: "lightbulb.fill",
                value: "\(upcomingBirthdaysCount)",
                label: "Diese Woche",
                color: AppColor.accent
            )

            statCard(
                icon: "gift.fill",
                value: "\(totalGiftIdeas)",
                label: "Ideen",
                color: AppColor.secondary
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var upcomingBirthdaysCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return people.filter { person in
            guard let nextBirthday = nextBirthday(for: person, from: today) else {
                return false
            }

            let daysUntil = calendar.dateComponents([.day], from: today, to: nextBirthday).day ?? 0
            return daysUntil >= 0 && daysUntil <= 7
        }.count
    }

    private var totalGiftIdeas: Int {
        giftIdeas.count
    }

    private func nextBirthday(for person: PersonRef, from today: Date) -> Date? {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: today)

        var components = calendar.dateComponents([.month, .day], from: person.birthday)
        components.year = currentYear

        guard var birthday = calendar.date(from: components) else {
            return nil
        }

        if birthday < today {
            components.year = currentYear + 1
            birthday = calendar.date(from: components) ?? birthday
        }

        return birthday
    }

    @ViewBuilder
    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppColor.textPrimary)

            Text(label)
                .font(.caption)
                .foregroundColor(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppColor.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }
}
