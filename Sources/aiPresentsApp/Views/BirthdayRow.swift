import SwiftUI

struct BirthdayRow: View {
    let person: PersonRef

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [.blue, .purple]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 50, height: 50)
                .overlay {
                    Text(String(person.displayName.prefix(1)))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(person.displayName)
                    .font(.headline)

                Text(birthdayInfo)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let giftCount = person.giftIdeas?.count, giftCount > 0 {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }

    private var birthdayInfo: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let birthdayThisYear = calendar.date(bySetting: .year, value: calendar.component(.year, from: today), of: person.birthday) ?? person.birthday
        let age = calendar.dateComponents([.year], from: person.birthday, to: birthdayThisYear).year ?? 0

        if calendar.isDateInToday(birthdayThisYear) {
            return "Heute wird \(age)!"
        } else {
            let days = calendar.dateComponents([.day], from: today, to: birthdayThisYear).day ?? 0
            if days == 0 {
                return "Wird \(age)"
            } else if days == 1 {
                return "Morgen wird \(age)"
            } else {
                return "In \(days) Tagen wird \(age)"
            }
        }
    }
}
