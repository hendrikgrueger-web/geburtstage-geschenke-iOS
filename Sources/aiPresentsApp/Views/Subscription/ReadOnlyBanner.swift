import SwiftUI

/// Banner-Komponente, die den Status der Trial oder des Upgrades anzeigt.
///
/// - Zeigt "Testphase abgelaufen" mit Lock-Icon und CTA, wenn Trial vorbei und nicht abonniert
/// - Zeigt "Noch X Tage kostenlos", wenn Trial läuft
/// - Verborgen, wenn `hasFullAccess` true ist
struct ReadOnlyBanner: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @State private var showingPaywall = false

    var body: some View {
        if !subscriptionManager.hasFullAccess {
            Button {
                showingPaywall = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.subheadline)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Testphase abgelaufen")
                            .font(.subheadline.bold())
                        Text("Upgrade für vollen Zugriff")
                            .font(.caption)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundStyle(.white)
                .padding()
                .background(AppColor.accent.gradient)
                .clipShape(.rect(cornerRadius: 12))
            }
            .padding(.horizontal)
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
                    .environment(subscriptionManager)
            }
        } else if subscriptionManager.isInTrial {
            HStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .foregroundStyle(AppColor.accent)
                Text("Noch \(subscriptionManager.trialDaysRemaining) Tage kostenlos")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal)
        }
    }
}

#Preview("Trial active") {
    VStack {
        ReadOnlyBanner()
        Spacer()
    }
    .environment(SubscriptionManager())
}

#Preview("Trial expired") {
    VStack {
        ReadOnlyBanner()
        Spacer()
    }
    .environment({
        let manager = SubscriptionManager()
        UserDefaults.standard.set(Date().addingTimeInterval(-120 * 86400), forKey: "subscriptionTrialStartDate")
        return manager
    }())
}
