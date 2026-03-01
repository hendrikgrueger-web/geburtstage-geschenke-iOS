import SwiftUI

struct GiftHistoryRow: View {
    let history: GiftHistory

    var body: some View {
        HStack(spacing: 12) {
            // Year badge
            Text("\(history.year)")
                .font(.caption)
                .fontWeight(.bold)
                .frame(width: 50, height: 50)
                .background(AppColor.secondary.opacity(0.2))
                .foregroundColor(AppColor.secondary)
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                Text(history.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(history.category)
                    .font(.caption)
                    .foregroundColor(AppColor.textSecondary)
            }

            Spacer()

            Image(systemName: "gift.fill")
                .foregroundColor(AppColor.accent.opacity(0.6))
                .font(.caption)
        }
        .padding(.vertical, 2)
    }
}
