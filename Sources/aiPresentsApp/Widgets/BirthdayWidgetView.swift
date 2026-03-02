import SwiftUI
import SwiftData

struct BirthdayWidgetView: View {
    @Query private var people: [PersonRef]
    @State private var selectedIndex = 0

    private var upcomingBirthdays: [PersonRef] {
        let today = Calendar.current.startOfDay(for: Date())

        return people.compactMap { person -> (PersonRef, Date)? in
            guard let nextBirthday = BirthdayCalculator.nextBirthday(for: person.birthday, from: today) else {
                return nil
            }

            guard let daysUntil = BirthdayCalculator.daysUntilBirthday(for: person.birthday, from: today) else {
                return nil
            }

            if daysUntil >= 0 && daysUntil <= 14 {
                return (person, nextBirthday)
            }
            return nil
        }
        .sorted { $0.1 < $1.1 }
        .prefix(3)
        .map { $0.0 }
    }

    var body: some View {
        VStack(spacing: 16) {
            if upcomingBirthdays.isEmpty {
                emptyWidgetState
            } else {
                TabView(selection: $selectedIndex) {
                    ForEach(Array(upcomingBirthdays.enumerated()), id: \.offset) { index, person in
                        birthdayCard(for: person)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 120)

                if upcomingBirthdays.count > 1 {
                    HStack(spacing: 4) {
                        ForEach(0..<upcomingBirthdays.count, id: \.self) { index in
                            Circle()
                                .fill(index == selectedIndex ? AppColor.primary : Color.gray.opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                    }
                    .transition(.opacity)
                }
            }
        }
        .padding()
        .background(AppColor.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    private func birthdayCard(for person: PersonRef) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                PersonAvatar(person: person, size: 50)

                VStack(alignment: .leading, spacing: 4) {
                    Text(person.displayName)
                        .font(.headline)
                        .foregroundColor(AppColor.textPrimary)

                    Text(birthdayInfo(for: person))
                        .font(.subheadline)
                        .foregroundColor(AppColor.textSecondary)
                }

                Spacer()

                BirthdayCountdownBadge(daysUntil: daysUntilBirthday(for: person))
            }

            if let giftCount = person.giftIdeas?.count, giftCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundColor(AppColor.accent)
                    Text("\(giftCount) Idee\(giftCount == 1 ? "" : "n")")
                        .font(.caption)
                        .foregroundColor(AppColor.textSecondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.gradientForRelation(person.relation).opacity(0.1))
        .cornerRadius(12)
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
            return "🎉 Heute wird \(age)!"
        } else if daysUntil == 1 {
            return "Morgen wird \(age)"
        } else {
            return "In \(daysUntil) Tagen wird \(age)"
        }
    }

    private var emptyWidgetState: some View {
        VStack(spacing: 12) {
            Image(systemName: "gift")
                .font(.system(size: 40))
                .foregroundColor(AppColor.textSecondary.opacity(0.4))
                .symbolEffect(
                    AccessibilityConfiguration.isReducedMotionEnabled ? .pulse : .bounce,
                    options: .repeating,
                    isActive: true
                )

            Text("Keine Geburtstage")
                .font(.subheadline)
                .foregroundColor(AppColor.textSecondary)

            Text("in den nächsten 14 Tagen")
                .font(.caption)
                .foregroundColor(AppColor.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    BirthdayWidgetView()
        .modelContainer(for: [PersonRef.self, GiftIdea.self, GiftHistory.self, ReminderRule.self], inMemory: true)
        .frame(width: 340, height: 200)
        .padding()
}
