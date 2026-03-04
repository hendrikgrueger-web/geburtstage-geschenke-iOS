import SwiftUI

/// Kompaktes Premium-Status-Badge für die UI.
///
/// ## Verwendung
/// ```swift
/// PremiumBadge()                     // Standard (klein, inline)
/// PremiumBadge(style: .prominent)    // Auffälliger (für Settings)
/// ```
struct PremiumBadge: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    enum Style { case compact, prominent }
    var style: Style = .compact

    var body: some View {
        if subscriptionManager.isPremium {
            premiumLabel
        } else {
            freeLabel
        }
    }

    private var premiumLabel: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(style == .compact ? .caption2 : .caption)
            Text("Premium")
                .font(style == .compact ? .caption2.bold() : .caption.bold())
        }
        .foregroundStyle(.white)
        .padding(.horizontal, style == .compact ? 6 : 10)
        .padding(.vertical, style == .compact ? 2 : 4)
        .background(
            LinearGradient(
                colors: [.orange, .yellow],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(Capsule())
    }

    private var freeLabel: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill")
                .font(style == .compact ? .caption2 : .caption)
            Text("Free")
                .font(style == .compact ? .caption2.bold() : .caption.bold())
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, style == .compact ? 6 : 10)
        .padding(.vertical, style == .compact ? 2 : 4)
        .background(Color.secondary.opacity(0.15))
        .clipShape(Capsule())
    }
}

/// View-Modifier der eine View mit Premium-Overlay versieht wenn nicht Premium.
///
/// ## Verwendung
/// ```swift
/// AIGiftSuggestionsButton()
///     .premiumRequired(action: { showPaywall = true })
/// ```
struct PremiumRequiredModifier: ViewModifier {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    let action: () -> Void

    func body(content: Content) -> some View {
        if subscriptionManager.isPremium {
            content
        } else {
            Button {
                action()
                HapticFeedback.medium()
            } label: {
                content
                    .overlay(alignment: .topTrailing) {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .padding(4)
                            .background(Color.orange)
                            .clipShape(Circle())
                            .offset(x: 4, y: -4)
                    }
            }
        }
    }
}

extension View {
    /// Versieht eine View mit einem Lock-Icon und öffnet die Paywall bei Tap.
    func premiumRequired(action: @escaping () -> Void) -> some View {
        modifier(PremiumRequiredModifier(action: action))
    }
}
