import SwiftUI
import SwiftData

struct NochOhneGeschenkSection: View {
    @Query private var people: [PersonRef]
    @Query private var giftIdeas: [GiftIdea]

    var body: some View {
        if !personsWithoutGift.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Noch ohne Geschenk")
                    .font(.headline)
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(personsWithoutGift) { person in
                            NavigationLink(value: person) {
                                giftReminderCard(for: person)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 8)
        }
    }

    private var personsWithoutGift: [PersonRef] {
        let today = Calendar.current.startOfDay(for: Date())
        let maxDays = AppConfig.GiftReminder.lookAheadDays

        return people.compactMap { person -> (PersonRef, Int)? in
            guard let days = BirthdayCalculator.daysUntilBirthday(for: person.birthday, from: today),
                  days > 0, days <= maxDays else {
                return nil
            }

            let hasGift = giftIdeas.contains { idea in
                idea.personId == person.id &&
                (idea.status == .planned || idea.status == .purchased || idea.status == .given)
            }

            return hasGift ? nil : (person, days)
        }
        .sorted { $0.1 < $1.1 }
        .prefix(AppConfig.GiftReminder.maxDisplay)
        .map { $0.0 }
    }

    private func giftReminderCard(for person: PersonRef) -> some View {
        VStack(spacing: 8) {
            CompactPersonAvatar(person: person, size: 44)

            Text(person.displayName.components(separatedBy: " ").first ?? person.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)

            if let days = BirthdayCalculator.daysUntilBirthday(for: person.birthday) {
                Text("In \(days) T.")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(badgeColor(for: days), in: Capsule())
            }
        }
        .frame(width: 80)
        .padding(.vertical, 10)
        .background(AppColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(person.displayName), noch ohne Geschenk")
    }

    private func badgeColor(for days: Int) -> Color {
        if days <= 7 { return AppColor.error }
        if days <= 14 { return AppColor.warning }
        return AppColor.birthdayUpcoming
    }
}
