import SwiftUI

struct GiftIdeaRow: View {
    let idea: GiftIdea

    private var linkValidation: (sanitized: String, isValid: Bool) {
        URLValidator.validate(idea.link)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(idea.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                if linkValidation.isValid && !linkValidation.sanitized.isEmpty {
                    Link(destination: URL(string: linkValidation.sanitized)!) {
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
                    Text(budgetString)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(String(localized: "Status: \(statusText). Tap zum Bearbeiten"))
    }

    private var accessibilityLabel: String {
        var label = idea.title
        if !idea.note.isEmpty {
            label += ". " + idea.note
        }
        if idea.budgetMax > 0 {
            label += String(localized: ". Budget: \(budgetString)")
        }
        if !idea.tags.isEmpty {
            label += String(localized: ". Tags: \(idea.tags.joined(separator: ", "))")
        }
        label += String(localized: ". Status: \(statusText)")
        return label
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: idea.status.icon)
                .font(.caption2)
            Text(statusText)
                .font(.caption2)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(idea.status.color.opacity(0.2))
        .foregroundColor(idea.status.color)
        .cornerRadius(4)
    }

    private var statusText: String {
        switch idea.status {
        case .idea: return String(localized: "Idee")
        case .planned: return String(localized: "Geplant")
        case .purchased: return String(localized: "Gekauft")
        case .given: return String(localized: "Verschenkt")
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
            return String(localized: "\(Int(idea.budgetMin)) €")
        } else if idea.budgetMin == 0 {
            return String(localized: "bis \(Int(idea.budgetMax)) €")
        } else {
            return String(localized: "\(Int(idea.budgetMin)) - \(Int(idea.budgetMax)) €")
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
                ForEach(Array(idea.tags.enumerated()), id: \.offset) { index, tag in
                    Text("#\(tag)")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(tagColor(for: index))
                        .foregroundColor(tagTextColor(for: index))
                        .cornerRadius(4)
                }
            }
        }
    }

    private func tagColor(for index: Int) -> Color {
        let colors: [Color] = [
            AppColor.primary.opacity(0.15),
            AppColor.secondary.opacity(0.15),
            AppColor.accent.opacity(0.15),
            AppColor.success.opacity(0.15),
            AppColor.textSecondary.opacity(0.15)
        ]
        return colors[index % colors.count]
    }

    private func tagTextColor(for index: Int) -> Color {
        let colors: [Color] = [
            AppColor.primary,
            AppColor.secondary,
            AppColor.accent,
            AppColor.success,
            AppColor.textSecondary
        ]
        return colors[index % colors.count]
    }
}
