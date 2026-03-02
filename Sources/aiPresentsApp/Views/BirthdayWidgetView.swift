import SwiftUI
import SwiftData

struct BirthdayWidgetView: View {
    @Query private var people: [PersonRef]
    @State private var currentIndex = 0

    private var upcomingBirthdays: [(person: PersonRef, daysUntil: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return people.compactMap { person -> (PersonRef, Int)? in
            guard let nextBirthday = nextBirthday(for: person, from: today) else {
                return nil
            }

            let daysUntil = calendar.dateComponents([.day], from: today, to: nextBirthday).day ?? 0
            return (person, daysUntil)
        }
        .filter { $0.daysUntil >= 0 && $0.daysUntil <= 30 }
        .sorted { $0.daysUntil < $1.daysUntil }
    }

    var body: some View {
        Group {
            if upcomingBirthdays.isEmpty {
                emptyWidgetView
            } else {
                TabView(selection: $currentIndex) {
                    ForEach(Array(upcomingBirthdays.enumerated()), id: \.offset) { index, birthday in
                        birthdayCard(for: birthday.person, daysUntil: birthday.daysUntil)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: upcomingBirthdays.count > 1 ? .automatic : .never))
                .frame(height: 120)
            }
        }
    }

    @ViewBuilder
    private func birthdayCard(for person: PersonRef, daysUntil: Int) -> some View {
        HStack(spacing: 16) {
            PersonAvatar(person: person, size: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(person.displayName)
                    .font(.headline)
                    .foregroundColor(AppColor.textPrimary)
                    .lineLimit(1)

                Text(person.relation)
                    .font(.subheadline)
                    .foregroundColor(AppColor.textSecondary)

                Spacer()

                countdownBadge(daysUntil: daysUntil)
            }

            Spacer()
        }
        .padding(16)
        .background(AppColor.gradientForRelation(person.relation))
        .cornerRadius(16)
        .shadow(color: AppColor.primary.opacity(0.2), radius: 8, x: 0, y: 4)
    }

    @ViewBuilder
    private func countdownBadge(daysUntil: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: birthdayIcon(daysUntil: daysUntil))
                .font(.caption)

            Text(countdownText(daysUntil: daysUntil))
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            birthdayColor(daysUntil: daysUntil)
                .opacity(0.2)
        )
        .foregroundColor(birthdayColor(daysUntil: daysUntil))
        .cornerRadius(12)
    }

    private var emptyWidgetView: some View {
        VStack(spacing: 12) {
            Image(systemName: "giftcard")
                .font(.system(size: 40))
                .foregroundColor(AppColor.textSecondary.opacity(0.5))

            Text("Keine Geburtstage")
                .font(.subheadline)
                .foregroundColor(AppColor.textSecondary)

            Text("in den nächsten 30 Tagen")
                .font(.caption)
                .foregroundColor(AppColor.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(AppColor.cardBackground)
        .cornerRadius(16)
    }

    private func birthdayIcon(daysUntil: Int) -> String {
        switch daysUntil {
        case 0:
            return "party.popper.fill"
        case 1:
            return "calendar.badge.exclamationmark"
        case 2...7:
            return "calendar.badge.clock"
        default:
            return "calendar"
        }
    }

    private func birthdayColor(daysUntil: Int) -> Color {
        switch daysUntil {
        case 0:
            return AppColor.birthdayToday
        case 1...7:
            return AppColor.birthdaySoon
        default:
            return AppColor.birthdayUpcoming
        }
    }

    private func countdownText(daysUntil: Int) -> String {
        switch daysUntil {
        case 0:
            return "Heute! 🎉"
        case 1:
            return "Morgen"
        case 2...7:
            return "In \(daysUntil) Tagen"
        default:
            return "\(daysUntil) Tage"
        }
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
}
