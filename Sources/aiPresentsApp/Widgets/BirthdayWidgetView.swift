import SwiftUI
import SwiftData

struct UpcomingBirthdayHero: View {
    @Query private var allPeople: [PersonRef]

    private var upcomingBirthdays: [PersonRef] {
        let today = Calendar.current.startOfDay(for: Date())
        return allPeople.compactMap { person -> (PersonRef, Int)? in
            guard let days = BirthdayCalculator.daysUntilBirthday(for: person.birthday, from: today),
                  days >= 0 else { return nil }
            return (person, days)
        }
        .sorted { $0.1 < $1.1 }
        .prefix(3)
        .map { $0.0 }
    }

    var body: some View {
        if upcomingBirthdays.isEmpty {
            emptyState
        } else {
            VStack(spacing: 10) {
                ForEach(upcomingBirthdays) { person in
                    NavigationLink(value: person) {
                        birthdayCard(for: person)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func birthdayCard(for person: PersonRef) -> some View {
        HStack(spacing: 12) {
            PersonAvatar(person: person, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(person.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColor.textPrimary)

                Text(birthdayInfo(for: person))
                    .font(.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }

            Spacer()

            HStack(spacing: 8) {
                if let giftCount = person.giftIdeas?.count, giftCount > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption2)
                        Text("\(giftCount)")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(AppColor.accent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(AppColor.accent.opacity(0.12), in: Capsule())
                }

                BirthdayCountdownBadge(daysUntil: daysUntilBirthday(for: person))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppColor.gradientForRelation(person.relation).opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func daysUntilBirthday(for person: PersonRef) -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        return BirthdayCalculator.daysUntilBirthday(for: person.birthday, from: today) ?? 0
    }

    private func birthdayInfo(for person: PersonRef) -> String {
        let today = Calendar.current.startOfDay(for: Date())
        guard let age = BirthdayCalculator.age(for: person.birthday, on: today) else {
            return ""
        }
        let daysUntil = daysUntilBirthday(for: person)

        if daysUntil == 0 {
            return String(localized: "Heute wird \(age)!")
        } else if daysUntil == 1 {
            return String(localized: "Morgen wird \(age)")
        } else {
            return String(localized: "In \(daysUntil) Tagen wird \(age)")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "gift")
                .font(.system(size: 32))
                .foregroundStyle(AppColor.textSecondary.opacity(0.4))
            Text("Keine Geburtstage")
                .font(.subheadline)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

#Preview {
    UpcomingBirthdayHero()
        .modelContainer(for: [PersonRef.self, GiftIdea.self, GiftHistory.self, ReminderRule.self], inMemory: true)
        .padding()
}
