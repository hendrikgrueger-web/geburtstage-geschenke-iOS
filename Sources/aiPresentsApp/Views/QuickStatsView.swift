import SwiftUI
import SwiftData

struct QuickStatsView: View {
    @Query private var people: [PersonRef]
    @Query private var giftIdeas: [GiftIdea]

    var body: some View {
        HStack(spacing: 12) {
            statCard(
                icon: "person.2.fill",
                value: "\(people.count)",
                label: "Kontakte",
                color: AppColor.primary
            )

            statCard(
                icon: "bell.fill",
                value: upcomingBirthdaysCount > 0 ? "\(upcomingBirthdaysCount)" : "Keine",
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
        .onTapGesture {
            HapticFeedback.light()
        }
    }

    private var upcomingBirthdaysCount: Int {
        let today = Calendar.current.startOfDay(for: Date())

        return people.filter { person in
            guard let daysUntil = BirthdayCalculator.daysUntilBirthday(for: person.birthday, from: today) else {
                return false
            }
            return daysUntil >= 0 && daysUntil <= 7
        }.count
    }

    private var totalGiftIdeas: Int {
        giftIdeas.count
    }

    // Get the next upcoming birthday with countdown
    private var nextBirthdayInfo: (person: PersonRef, daysUntil: Int)? {
        let today = Calendar.current.startOfDay(for: Date())

        let sorted = people.compactMap { person -> (PersonRef, Int)? in
            guard let daysUntil = BirthdayCalculator.daysUntilBirthday(for: person.birthday, from: today) else {
                return nil
            }
            if daysUntil >= 0 && daysUntil <= 30 {
                return (person, daysUntil)
            }
            return nil
        }.sorted { $0.1 < $1.1 }

        return sorted.first
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
