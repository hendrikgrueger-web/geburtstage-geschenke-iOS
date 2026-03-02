import SwiftUI
import SwiftData

struct GiftHistoryRow: View {
    let history: GiftHistory
    let onShare: (() -> Void)?
    let onReuseAsIdea: (() -> Void)?

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
                .background(AppColor.secondary.opacity(0.2))
                .foregroundColor(AppColor.secondary)
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                Text(history.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Text(history.category)
                        .font(.caption)
                        .foregroundColor(AppColor.textSecondary)

                    if history.budget > 0 {
                        Text("• \(Int(history.budget))€")
                            .font(.caption)
                            .foregroundColor(AppColor.textSecondary)
                    }
                }

                if !history.note.isEmpty {
                    Text(history.note)
                        .font(.caption2)
                        .foregroundColor(AppColor.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                if let onReuseAsIdea = onReuseAsIdea {
                    Button {
                        onReuseAsIdea()
                        HapticFeedback.light()
                    } label: {
                        Image(systemName: "lightbulb")
                            .foregroundColor(AppColor.primary.opacity(0.6))
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }

                if let onShare = onShare {
                    Button {
                        onShare()
                        HapticFeedback.light()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(AppColor.textSecondary.opacity(0.6))
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(history.title), \(history.category), \(history.year)")
        .accessibilityHint("Geschenk vermerkt im Jahr \(history.year)")
    }
}
