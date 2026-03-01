import SwiftUI

struct BirthdayCountdownBadge: View {
    let daysUntil: Int

    var body: some View {
        VStack(spacing: 2) {
            Text(countdownText)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)

            if daysUntil > 0 {
                Text("Tage")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(badgeGradient)
        .cornerRadius(12)
        .shadow(color: badgeColor.opacity(0.3), radius: 4, x: 0, y: 2)
    }

    private var countdownText: String {
        if daysUntil == 0 {
            return "🎉"
        } else if daysUntil == 1 {
            return "1"
        } else if daysUntil < 7 {
            return "\(daysUntil)"
        } else {
            return "\(daysUntil)"
        }
    }

    private var badgeColor: Color {
        if daysUntil == 0 {
            return .pink
        } else if daysUntil <= 2 {
            return .red
        } else if daysUntil <= 7 {
            return AppColor.accent
        } else {
            return AppColor.primary
        }
    }

    private var badgeGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                badgeColor,
                badgeColor.opacity(0.8)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
