import SwiftUI
import SwiftData

struct GiftSummaryView: View {
    @Query private var giftIdeas: [GiftIdea]
    let person: PersonRef
    @State private var animatingBar = false

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
                .foregroundStyle(AppColor.textSecondary.opacity(0.5))
            Text("Noch keine Ideen")
                .font(.caption)
                .foregroundStyle(AppColor.textSecondary)
            Spacer()
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Keine Geschenkideen vorhanden")
    }

    private var summaryContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Progress overview
            progressOverview

            // Status breakdown
            statusBreakdownView
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Geschenk-Status Übersicht")
    }

    private var progressOverview: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Geschenk-Status")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(AppColor.textSecondary)

            GeometryReader { geometry in
                HStack(spacing: 2) {
                    ForEach([GiftStatus.idea, .planned, .purchased, .given], id: \.self) { status in
                        Rectangle()
                            .fill(status.color)
                            .frame(width: geometry.size.width * CGFloat(breakdownPercentage(for: status)) * (animatingBar ? 1.0 : 0.0))
                            .frame(height: 6)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animatingBar)
                    }
                }
                .clipShape(.rect(cornerRadius: 3))
            }
            .frame(height: 6)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animatingBar = true
            }
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
            .foregroundStyle(status.color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(status.color.opacity(0.15))
            .clipShape(.rect(cornerRadius: 6))
            .accessibilityElement(children: .combine)
            .accessibilityLabel(String(localized: "\(statusText(for: status)): \(count)"))
        }
    }

    private func statusText(for status: GiftStatus) -> String {
        switch status {
        case .idea: return String(localized: "Ideen")
        case .planned: return String(localized: "Geplant")
        case .purchased: return String(localized: "Gekauft")
        case .given: return String(localized: "Verschenkt")
        }
    }

    private func breakdownPercentage(for status: GiftStatus) -> Double {
        guard personGiftIdeas.count > 0 else { return 0 }
        let count = statusBreakdown[status, default: 0]
        return Double(count) / Double(personGiftIdeas.count)
    }
}
