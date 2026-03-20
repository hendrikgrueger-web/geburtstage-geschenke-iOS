import SwiftUI

/// ViewModifier, der Premium-Inhalte sperrt, bis das Abo aktiv ist.
///
/// Wenn `hasFullAccess` nicht verfügbar ist, zeigt der Modifier
/// einen transparenten Overlay, der Tap-Ereignisse abfängt und das Paywall-Sheet öffnet.
struct PremiumGateModifier: ViewModifier {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @State private var showingPaywall = false

    func body(content: Content) -> some View {
        content
            .disabled(!subscriptionManager.hasFullAccess)
            .opacity(subscriptionManager.hasFullAccess ? 1.0 : 0.5)
            .overlay {
                if !subscriptionManager.hasFullAccess {
                    Color.clear
                        .contentShape(.rect)
                        .onTapGesture { showingPaywall = true }
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
                    .environment(subscriptionManager)
            }
    }
}

extension View {
    /// Sperrt diese View für Benutzer ohne Full Access.
    ///
    /// **Verwendung:**
    /// ```swift
    /// AIChatView()
    ///     .premiumGate()
    /// ```
    func premiumGate() -> some View {
        modifier(PremiumGateModifier())
    }
}
