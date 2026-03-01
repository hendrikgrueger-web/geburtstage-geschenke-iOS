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
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(giftCount)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Ideen")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding(.vertical, 4)
    }

    private var birthdayInfo: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let birthdayThisYear = calendar.date(bySetting: .year, value: calendar.component(.year, from: today), of: person.birthday) ?? person.birthday
        let age = calendar.dateComponents([.year], from: person.birthday, to: birthdayThisYear).year ?? 0

        let daysUntil = calendar.dateComponents([.day], from: today, to: birthdayThisYear).day ?? 0

        if daysUntil == 0 {
            return "Heute wird \(age)!"
        } else if daysUntil == 1 {
            return "Morgen wird \(age)"
        } else if daysUntil == -1 {
            return "Gestern wurde \(age)"
        } else if daysUntil < -1 {
            return "Vor \(-daysUntil) Tagen wurde \(age)"
        } else if daysUntil == 365 {
            return "Nächstes Jahr wird \(age + 1)"
        } else {
            return "In \(daysUntil) Tagen wird \(age)"
        }
    }
}
