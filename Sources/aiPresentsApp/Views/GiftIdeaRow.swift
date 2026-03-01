import SwiftUI

struct GiftIdeaRow: View {
    let idea: GiftIdea

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(idea.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                if !idea.link.isEmpty {
                    Link(destination: URL(string: idea.link) ?? URL(string: "https://")!) {
                        Image(systemName: "link.circle.fill")
                            .font(.caption)
                            .foregroundColor(AppColor.primary)
                    }
                }

                statusBadge
            }

            if !idea.note.isEmpty {
                Text(idea.note)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            if idea.budgetMax > 0 {
                HStack {
                    budgetString
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    if idea.budgetMin > 0 && idea.budgetMax > idea.budgetMin {
                        budgetBar
                    }
                }
            }

            if !idea.tags.isEmpty {
                tagsView
            }
        }
        .padding(.vertical, 2)
    }

    private var statusBadge: some View {
        Text(statusText)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(4)
    }

    private var statusText: String {
        switch idea.status {
        case .idea: return "Idee"
        case .planned: return "Geplant"
        case .purchased: return "Gekauft"
        case .given: return "Verschenkt"
        }
    }

    private var statusColor: Color {
        switch idea.status {
        case .idea: return .blue
        case .planned: return .orange
        case .purchased: return .green
        case .given: return .gray
        }
    }

    private var budgetString: String {
        if idea.budgetMin == idea.budgetMax {
            return String(format: "%.0f €", idea.budgetMin)
        } else if idea.budgetMin == 0 {
            return String(format: "bis %.0f €", idea.budgetMax)
        } else {
            return String(format: "%.0f - %.0f €", idea.budgetMin, idea.budgetMax)
        }
    }

    private var budgetBar: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                // Min marker
                Rectangle()
                    .fill(AppColor.primary.opacity(0.6))
                    .frame(width: 2)
                    .frame(height: 8)

                // Budget range
                Rectangle()
                    .fill(budgetGradient)
                    .frame(width: geometry.size.width - 4)
                    .frame(height: 6)
                    .cornerRadius(2)

                // Max marker
                Rectangle()
                    .fill(AppColor.accent.opacity(0.8))
                    .frame(width: 2)
                    .frame(height: 8)
            }
        }
        .frame(width: 80, height: 10)
    }

    private var budgetGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                AppColor.primary.opacity(0.4),
                AppColor.secondary.opacity(0.4)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var tagsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(idea.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                }
            }
        }
    }
}
