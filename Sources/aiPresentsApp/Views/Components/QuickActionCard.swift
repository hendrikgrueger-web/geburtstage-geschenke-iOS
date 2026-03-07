import SwiftUI

/// A reusable quick action card with icon, title, subtitle, and accessibility support
struct QuickActionCard: View {
    // MARK: - Types
    enum CardStyle {
        case primary
        case secondary
        case success
        case warning
        case info

        var backgroundColor: Color {
            switch self {
            case .primary: return AppColor.primary.opacity(0.15)
            case .secondary: return AppColor.secondary.opacity(0.15)
            case .success: return AppColor.success.opacity(0.15)
            case .warning: return .orange.opacity(0.15)
            case .info: return .blue.opacity(0.15)
            }
        }

        var iconColor: Color {
            switch self {
            case .primary: return AppColor.primary
            case .secondary: return AppColor.secondary
            case .success: return AppColor.success
            case .warning: return .orange
            case .info: return .blue
            }
        }
    }

    // MARK: - Properties
    let style: CardStyle
    let icon: String
    let title: String
    let subtitle: String?
    let action: (() -> Void)?
    let isDisabled: Bool
    let showChevron: Bool

    // MARK: - Initializer
    init(
        style: CardStyle = .primary,
        icon: String,
        title: String,
        subtitle: String? = nil,
        action: (() -> Void)? = nil,
        isDisabled: Bool = false,
        showChevron: Bool = true
    ) {
        self.style = style
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.isDisabled = isDisabled
        self.showChevron = showChevron
    }

    // MARK: - Body
    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action?()
        }) {
            HStack(spacing: 16) {
                // Icon
                iconView

                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Chevron (if action exists)
                if showChevron && action != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(style.backgroundColor)
            .clipShape(.rect(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(style.iconColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled || action == nil)
        .opacity(isDisabled ? 0.5 : 1.0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title + (subtitle.map { ", \($0)" } ?? ""))
        .accessibilityHint(action != nil ? "Doppeltippen zum Öffnen" : "")
        .accessibilityAddTraits(action != nil ? [.isButton] : [])
    }

    // MARK: - Subviews
    private var iconView: some View {
        ZStack {
            Circle()
                .fill(style.iconColor.opacity(0.2))
                .frame(width: 44, height: 44)

            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(style.iconColor)
        }
    }
}

// MARK: - Quick Action Grid

struct QuickActionGrid: View {
    let actions: [QuickActionCard]
    let columns: Int

    init(actions: [QuickActionCard], columns: Int = 2) {
        self.actions = actions
        self.columns = columns
    }

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columns),
            spacing: 12
        ) {
            ForEach(Array(actions.enumerated()), id: \.offset) { _, action in
                action
            }
        }
    }
}

// MARK: - Predefined Quick Actions

extension QuickActionCard {
    static func addPerson(action: @escaping () -> Void) -> QuickActionCard {
        QuickActionCard(
            style: .primary,
            icon: "person.badge.plus",
            title: "Kontakt hinzufügen",
            subtitle: "Neue Person importieren",
            action: action
        )
    }

    static func importContacts(action: @escaping () -> Void) -> QuickActionCard {
        QuickActionCard(
            style: .secondary,
            icon: "square.and.arrow.down.on.square",
            title: "Kontakte importieren",
            subtitle: "Aus Adressbuch",
            action: action
        )
    }

    static func addGiftIdea(action: @escaping () -> Void) -> QuickActionCard {
        QuickActionCard(
            style: .success,
            icon: "gift.fill",
            title: "Idee hinzufügen",
            subtitle: "Neue Geschenkidee",
            action: action
        )
    }

    static func aiSuggestions(action: @escaping () -> Void, isDisabled: Bool = false) -> QuickActionCard {
        QuickActionCard(
            style: .info,
            icon: "sparkles",
            title: "KI-Vorschläge",
            subtitle: "Intelligente Ideen",
            action: action,
            isDisabled: isDisabled
        )
    }

    static func share(action: @escaping () -> Void) -> QuickActionCard {
        QuickActionCard(
            style: .info,
            icon: "square.and.arrow.up",
            title: "Teilen",
            subtitle: "Mit anderen teilen",
            action: action
        )
    }

    static func exportCSV(action: @escaping () -> Void) -> QuickActionCard {
        QuickActionCard(
            style: .primary,
            icon: "doc.text",
            title: "Exportieren",
            subtitle: "Als CSV speichern",
            action: action
        )
    }

    static func settings(action: @escaping () -> Void) -> QuickActionCard {
        QuickActionCard(
            style: .warning,
            icon: "gearshape",
            title: "Einstellungen",
            subtitle: "App konfigurieren",
            action: action
        )
    }

    static func statistics(count: Int, action: (() -> Void)? = nil) -> QuickActionCard {
        QuickActionCard(
            style: .primary,
            icon: "chart.bar",
            title: "\(count) Ideen",
            subtitle: "Geschenkideen gesamt",
            action: action
        )
    }
}

// MARK: - Stat Card (for dashboard-style views)

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color
    let trend: String?

    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String,
        color: Color = .blue,
        trend: String? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.trend = trend
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)

                Spacer()

                if let trend = trend {
                    Text(trend)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColor.success)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColor.success.opacity(0.15))
                        .clipShape(.rect(cornerRadius: 8))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary.opacity(0.8))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(.rect(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
        .accessibilityValue(subtitle ?? "")
    }
}

// MARK: - Preview

#Preview("Quick Action Cards") {
    ScrollView {
        VStack(spacing: 20) {
            Text("Quick Actions")
                .font(.headline)
                .padding(.horizontal)

            QuickActionGrid(
                actions: [
                    .addPerson(action: {}),
                    .importContacts(action: {}),
                    .addGiftIdea(action: {}),
                    .aiSuggestions(action: {}),
                    .share(action: {}),
                    .exportCSV(action: {})
                ]
            )
            .padding(.horizontal)

            Divider()
                .padding(.vertical)

            VStack(spacing: 12) {
                QuickActionCard(
                    style: .primary,
                    icon: "person.badge.plus",
                    title: "Kontakt hinzufügen",
                    subtitle: "Neue Person importieren",
                    action: {}
                )

                QuickActionCard(
                    style: .warning,
                    icon: "exclamationmark.triangle",
                    title: "Wichtige Aktion",
                    subtitle: "Bitte beachten",
                    action: {}
                )

                QuickActionCard(
                    style: .info,
                    icon: "info.circle",
                    title: "Info",
                    subtitle: "Informationen anzeigen",
                    action: nil
                )
            }
            .padding(.horizontal)

            Divider()
                .padding(.vertical)

            VStack(spacing: 20) {
                Text("Statistics")
                    .font(.headline)

                HStack(spacing: 12) {
                    StatCard(
                        title: "Kontakte",
                        value: "24",
                        subtitle: "+3 diese Woche",
                        icon: "person.2",
                        color: .blue,
                        trend: "+12%"
                    )

                    StatCard(
                        title: "Ideen",
                        value: "156",
                        subtitle: "Geschenkideen gesamt",
                        icon: "lightbulb",
                        color: .orange
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    .background(Color(.systemGroupedBackground))
}
