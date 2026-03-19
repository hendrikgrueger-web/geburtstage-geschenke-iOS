import SwiftUI
import SwiftData

struct GiftHistoryRow: View {
    let history: GiftHistory
    let onShare: (() -> Void)?
    let onReuseAsIdea: (() -> Void)?
    @State private var isPressed = false

    init(history: GiftHistory, onShare: (() -> Void)? = nil, onReuseAsIdea: (() -> Void)? = nil) {
        self.history = history
        self.onShare = onShare
        self.onReuseAsIdea = onReuseAsIdea
    }

    var body: some View {
        HStack(spacing: 12) {
            // Year badge
            Text("\(history.year)")
                .font(.caption)
                .fontWeight(.bold)
                .frame(width: 50, height: 50)
                .background(yearBadgeColor.opacity(0.2))
                .foregroundStyle(yearBadgeColor)
                .clipShape(.rect(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(history.title)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    // Richtungs-Icon: arrow.up.right = von uns verschenkt, arrow.down.left = von Person erhalten
                    Image(systemName: history.giftDirection == .received ? "arrow.down.left" : "arrow.up.right")
                        .font(.caption2)
                        .foregroundStyle(history.giftDirection == .received ? AppColor.accent : AppColor.textSecondary)
                }

                HStack(spacing: 8) {
                    Text(history.category)
                        .font(.caption)
                        .foregroundStyle(AppColor.textSecondary)

                    if history.budget > 0 {
                        Text("• \(CurrencyManager.shared.formatAmount(history.budget))")
                            .font(.caption)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }

                if !history.note.isEmpty {
                    Text(history.note)
                        .font(.caption2)
                        .foregroundStyle(AppColor.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            HStack(spacing: 12) {
                if let onReuseAsIdea = onReuseAsIdea {
                    Button {
                        onReuseAsIdea()
                        HapticFeedback.light()
                    } label: {
                        Image(systemName: "lightbulb")
                            .foregroundStyle(AppColor.primary.opacity(0.6))
                            .font(.caption)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    .pressable()
                    .accessibilityLabel(String(localized: "Als neue Idee verwenden"))
                }

                if let onShare = onShare {
                    Button {
                        onShare()
                        HapticFeedback.light()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(AppColor.textSecondary.opacity(0.6))
                            .font(.caption)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    .pressable()
                    .accessibilityLabel(String(localized: "Teilen"))
                }
            }
        }
        .padding(.vertical, 2)
        .hoverEffect(.highlight)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "\(history.giftDirection == .given ? String(localized: "Verschenkt") : String(localized: "Erhalten")): \(history.title), \(history.category), \(history.year)"))
    }

    private var yearBadgeColor: Color {
        let yearsSince = Calendar.current.component(.year, from: Date()) - history.year
        if yearsSince == 0 {
            return AppColor.accent
        } else if yearsSince == 1 {
            return AppColor.secondary
        } else if yearsSince <= 3 {
            return AppColor.primary
        } else {
            return AppColor.textSecondary
        }
    }
}
