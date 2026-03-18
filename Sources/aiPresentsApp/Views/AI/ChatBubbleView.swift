import SwiftUI

/// Chat-Bubble für User- und Assistant-Nachrichten.
struct ChatBubbleView: View {
    let message: ChatMessage
    let clarifyOptions: [PersonRef]
    let onActionTap: ((ChatAction) -> Void)?
    let onClarifyTap: ((PersonRef) -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == .assistant {
                assistantAvatar
            } else {
                Spacer(minLength: 48)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 6) {
                messageBubble

                // Action-Button unter Assistant-Bubble
                if let action = message.action, action.type == .createGiftIdea {
                    actionButton(action: action)
                }
                if let action = message.action, action.type == .openSuggestions {
                    actionButton(action: action)
                }
                // Personen-Karten: tippbare Karten für alle erwähnten Personen
                if !clarifyOptions.isEmpty {
                    VStack(spacing: 6) {
                        ForEach(clarifyOptions, id: \.id) { person in
                            Button {
                                onClarifyTap?(person)
                            } label: {
                                HStack(spacing: 8) {
                                    PersonAvatar(person: person, size: 28)
                                    Text(person.displayName)
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                    Text(person.relation)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(AppColor.secondary.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            if message.role == .user {
                // Kein Avatar für User
            } else {
                Spacer(minLength: 48)
            }
        }
        .padding(.horizontal, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Subviews

    /// Nachrichten-Bubble: User = Liquid Glass (iOS 26), Assistant = System-Hintergrund
    @ViewBuilder
    private var messageBubble: some View {
        if message.role == .user {
            Text(message.content)
                .font(.body)
                .foregroundStyle(AppColor.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 18))
        } else {
            Text(message.content)
                .font(.body)
                .foregroundStyle(AppColor.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }

    private var assistantAvatar: some View {
        ZStack {
            Circle()
                .fill(AppColor.secondary.opacity(0.15))
                .frame(width: 32, height: 32)
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColor.secondary)
        }
    }

    private func actionButton(action: ChatAction) -> some View {
        Button {
            onActionTap?(action)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: actionIcon(for: action.type))
                    .font(.caption)
                Text(actionLabel(for: action.type))
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AppColor.secondary.opacity(0.12))
            .foregroundStyle(AppColor.secondary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func actionIcon(for type: ChatAction.ActionType) -> String {
        switch type {
        case .createGiftIdea: return "plus.circle.fill"
        case .openSuggestions: return "sparkles"
        default: return "arrow.right.circle"
        }
    }

    private func actionLabel(for type: ChatAction.ActionType) -> String {
        switch type {
        case .createGiftIdea: return String(localized: "Als Geschenkidee speichern")
        case .openSuggestions: return String(localized: "KI-Vorschläge öffnen")
        default: return String(localized: "Aktion ausführen")
        }
    }

    private var accessibilityDescription: String {
        let roleLabel = message.role == .user ? String(localized: "Du") : String(localized: "KI-Assistent")
        return "\(roleLabel): \(message.content)"
    }
}

// MARK: - Typing Indicator

/// Animierte Punkte während die KI antwortet.
struct TypingIndicatorView: View {
    @State private var animating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            ZStack {
                Circle()
                    .fill(AppColor.secondary.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColor.secondary)
            }

            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(reduceMotion ? 1.0 : (animating ? 1.0 : 0.5))
                        .opacity(reduceMotion ? 1.0 : (animating ? 1.0 : 0.4))
                        .animation(
                            reduceMotion ? nil : .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: animating
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18))

            Spacer(minLength: 48)
        }
        .padding(.horizontal, 12)
        .onAppear { animating = true }
        .accessibilityLabel(String(localized: "KI denkt nach..."))
    }
}
