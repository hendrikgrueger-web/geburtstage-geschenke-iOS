import SwiftUI

struct BudgetRangeView: View {
    let budgetRange: BudgetRange
    @State private var animateBar = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Range Title
            HStack {
                Text(budgetRange.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColor.textPrimary)

                Spacer()

                // Budget summary
                Text(budgetRange.max == 0 ? "\(budgetRange.min)€+" : "\(Int(budgetRange.min))€ - \(Int(budgetRange.max))€")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(budgetColor)
            }

            // Animated Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppColor.separator.opacity(0.3))
                        .frame(height: 8)

                    // Progress bar with animation
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    budgetColor.opacity(0.6),
                                    budgetColor
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 8)
                        .frame(width: geometry.size.width * CGFloat(barProgress))
                        .offset(x: animateBar ? 0 : -geometry.size.width)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateBar)
                }
            }
            .frame(height: 8)
        }
        .padding(.vertical, 4)
        .onAppear {
            // Trigger animation on appear
            withAnimation {
                animateBar = true
            }
        }
        .id(budgetRange) // Trigger animation when budget changes
    }

    private var barProgress: Double {
        switch budgetRange {
        case .low:
            return 0.25
        case .medium:
            return 0.5
        case .high:
            return 0.75
        case .premium:
            return 1.0
        }
    }

    private var budgetColor: Color {
        switch budgetRange {
        case .low:
            return AppColor.success
        case .medium:
            return AppColor.primary
        case .high:
            return AppColor.accent
        case .premium:
            return Color(red: 0.8, green: 0.4, blue: 0.8) // Purple
        }
    }
}

// Alternative Compact View for Row Selection
struct BudgetRangeCompactView: View {
    let budgetRange: BudgetRange
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Color indicator
            Circle()
                .fill(budgetColor)
                .frame(width: 8, height: 8)

            // Range text
            Text(budgetRange.rawValue)
                .font(.subheadline)
                .foregroundColor(isSelected ? AppColor.primary : AppColor.textPrimary)

            Spacer()

            // Selection checkmark
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppColor.primary)
                    .font(.title3)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? AppColor.primary.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? AppColor.primary : Color.clear, lineWidth: 1.5)
        )
        .contentShape(Rectangle())
    }

    private var budgetColor: Color {
        switch budgetRange {
        case .low:
            return AppColor.success
        case .medium:
            return AppColor.primary
        case .high:
            return AppColor.accent
        case .premium:
            return Color(red: 0.8, green: 0.4, blue: 0.8)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        Text("Budget Ranges")
            .font(.headline)
            .padding()

        VStack(spacing: 12) {
            BudgetRangeView(budgetRange: .low)
            BudgetRangeView(budgetRange: .medium)
            BudgetRangeView(budgetRange: .high)
            BudgetRangeView(budgetRange: .premium)
        }
        .padding()
    }
    .background(AppColor.background)
}
