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
        } else {
            return "In \(daysUntil) Tagen wird \(age)"
        }
    }
}
