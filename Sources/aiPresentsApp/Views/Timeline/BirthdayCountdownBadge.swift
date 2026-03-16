import SwiftUI

struct BirthdayCountdownBadge: View {
    let daysUntil: Int
    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                if daysUntil == 0 {
                    Text("🎉")
                        .font(.title3)
                        .scaleEffect(isAnimating ? 1.3 : 1.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.4).repeatForever(autoreverses: true), value: isAnimating)
                } else {
                    Text(countdownText)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
            }

            if daysUntil > 0 {
                Text(daysUntil == 1 ? String(localized: "Tag") : String(localized: "Tage"))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.9))
            } else {
                Text("Heute")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(badgeGradient)
        .clipShape(.rect(cornerRadius: 14))
        .shadow(color: badgeColor.opacity(0.3), radius: 4, x: 0, y: 2)
        .scaleEffect(pulseScale)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .onAppear {
            if daysUntil == 0 {
                isAnimating = true
            } else if daysUntil <= 2 {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseScale = 1.05
                }
            }
        }
    }

    private var accessibilityLabel: String {
        if daysUntil == 0 {
            return String(localized: "Geburtstag heute")
        } else if daysUntil == 1 {
            return String(localized: "Geburtstag morgen")
        } else {
            return String(localized: "Geburtstag in \(daysUntil) Tagen")
        }
    }

    private var countdownText: String {
        "\(daysUntil)"
    }

    private var badgeColor: Color {
        if daysUntil == 0 {
            return AppColor.birthdayToday
        } else if daysUntil <= 2 {
            return AppColor.birthdaySoon
        } else if daysUntil <= 7 {
            return AppColor.accent
        } else {
            return AppColor.birthdayUpcoming
        }
    }

    private var badgeGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                badgeColor,
                badgeColor.opacity(0.85)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview("Today") {
    BirthdayCountdownBadge(daysUntil: 0)
        .padding()
        .background(AppColor.background)
}

#Preview("Tomorrow") {
    BirthdayCountdownBadge(daysUntil: 1)
        .padding()
        .background(AppColor.background)
}

#Preview("2 Days") {
    BirthdayCountdownBadge(daysUntil: 2)
        .padding()
        .background(AppColor.background)
}

#Preview("7 Days") {
    BirthdayCountdownBadge(daysUntil: 7)
        .padding()
        .background(AppColor.background)
}

#Preview("14 Days") {
    BirthdayCountdownBadge(daysUntil: 14)
        .padding()
        .background(AppColor.background)
}
