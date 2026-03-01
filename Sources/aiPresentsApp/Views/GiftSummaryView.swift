import SwiftUI
import SwiftData

struct GiftSummaryView: View {
    @Query private var giftIdeas: [GiftIdea]
    let person: PersonRef

    private var personGiftIdeas: [GiftIdea] {
        giftIdeas.filter { $0.personId == person.id }
    }

    private var statusBreakdown: [GiftStatus: Int] {
        var breakdown: [GiftStatus: Int] = [:]
        for idea in personGiftIdeas {
            breakdown[idea.status, default: 0] += 1
        }
        return breakdown
    }

    var body: some View {
        if personGiftIdeas.isEmpty {
            emptyState
        } else {
            summaryContent
        }
    }

    private var emptyState: some View {
        HStack {
            Image(systemName: "lightbulb")
                .foregroundColor(AppColor.textSecondary.opacity(0.5))
            Text("Noch keine Ideen")
                .font(.caption)
                .foregroundColor(AppColor.textSecondary)
            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var summaryContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Progress overview
            progressOverview

            // Status breakdown
            statusBreakdownView
        }
        .padding(.vertical, 4)
    }

    private var progressOverview: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Geschenk-Status")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(AppColor.textSecondary)

            GeometryReader { geometry in
                HStack(spacing: 2) {
                    ForEach([GiftStatus.idea, .planned, .purchased, .given], id: \.self) { status in
                        Rectangle()
                            .fill(status.color)
                            .frame(width: geometry.size.width * CGFloat(breakdownPercentage(for: status)))
                            .frame(height: 6)
                    }
                }
                .cornerRadius(3)
            }
            .frame(height: 6)
        }
    }

    private var statusBreakdownView: some View {
        HStack {
            ForEach([GiftStatus.idea, .planned, .purchased, .given], id: \.self) { status in
                statusChip(status: status, count: statusBreakdown[status, default: 0])
            }
            Spacer()
        }
    }

    @ViewBuilder
    private func statusChip(status: GiftStatus, count: Int) -> some View {
        if count > 0 {
            HStack(spacing: 4) {
                Image(systemName: status.icon)
                    .font(.caption2)
                Text("\(count)")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .foregroundColor(status.color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(status.color.opacity(0.15))
            .cornerRadius(6)
        }
    }

    private func breakdownPercentage(for status: GiftStatus) -> Double {
        guard personGiftIdeas.count > 0 else { return 0 }
        let count = statusBreakdown[status, default: 0]
        return Double(count) / Double(personGiftIdeas.count)
    }
}
