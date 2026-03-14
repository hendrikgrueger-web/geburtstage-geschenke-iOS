import StoreKit
import SwiftData
import SwiftUI

/// Paywall-Sheet mit 3 Preisoptionen (Jährlich, Monatlich, Lifetime), Trial-Banner und Restore-Funktion.
struct PaywallView: View {

    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    @Query private var people: [PersonRef]

    @State private var isPurchasing = false
    @State private var errorMessage: String?

    /// Produkte in Wunschreihenfolge: Yearly → Monthly → Lifetime
    private var sortedProducts: [Product] {
        let order: [String] = [
            SubscriptionManager.ProductID.yearly.rawValue,
            SubscriptionManager.ProductID.monthly.rawValue,
            SubscriptionManager.ProductID.lifetime.rawValue,
        ]
        return subscriptionManager.products.sorted { a, b in
            let ai = order.firstIndex(of: a.id) ?? Int.max
            let bi = order.firstIndex(of: b.id) ?? Int.max
            return ai < bi
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    if subscriptionManager.isInTrial {
                        trialBanner
                    }
                    productsSection
                    restoreButton
                    legalSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(AppColor.background)
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title2)
                    }
                    .disabled(isPurchasing)
                }
            }
            .task {
                await subscriptionManager.loadProducts()
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColor.accent.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "crown.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(AppColor.accent)
            }

            if people.count > 0 {
                Text("Du hast \(people.count) Geburtstage gespeichert")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Alle Features freischalten")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
            }

            featureList
        }
        .padding(.top, 8)
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 6) {
            featureRow(icon: "person.crop.circle.badge.plus", text: "Unbegrenzt Kontakte importieren")
            featureRow(icon: "sparkles", text: "KI-Geschenkvorschläge")
            featureRow(icon: "pencil", text: "Geschenkideen bearbeiten & verwalten")
            featureRow(icon: "bell.badge", text: "Smarte Erinnerungen")
            featureRow(icon: "rectangle.on.rectangle", text: "Homescreen Widget")
            featureRow(icon: "message", text: "KI-Geburtstagsnachrichten")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.top, 4)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppColor.success)
                .font(.system(size: 16))
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .font(.system(size: 14))
                .frame(width: 18)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Trial Banner

    private var trialBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "gift.fill")
                .font(.title3)
                .foregroundStyle(AppColor.success)
            VStack(alignment: .leading, spacing: 2) {
                Text("Testphase aktiv")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColor.success)
                Text("Noch \(subscriptionManager.trialDaysRemaining) Tage kostenloser Zugang")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(AppColor.success.opacity(0.1))
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColor.success.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Products

    private var productsSection: some View {
        VStack(spacing: 12) {
            if subscriptionManager.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 160)
            } else if subscriptionManager.products.isEmpty {
                Text("Produkte konnten nicht geladen werden.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .multilineTextAlignment(.center)
            } else {
                ForEach(sortedProducts, id: \.id) { product in
                    ProductCard(
                        product: product,
                        isPurchasing: isPurchasing,
                        onPurchase: { await purchase(product) }
                    )
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(AppColor.danger)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Restore Button

    private var restoreButton: some View {
        Button {
            Task { await subscriptionManager.restorePurchases() }
        } label: {
            Text("Käufe wiederherstellen")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .disabled(isPurchasing)
    }

    // MARK: - Legal

    private var legalSection: some View {
        VStack(spacing: 8) {
            Text("Das Abonnement verlängert sich automatisch, sofern es nicht mindestens 24 Stunden vor Ende des Abrechnungszeitraums gekündigt wird.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            HStack(spacing: 16) {
                Link("Datenschutz", destination: URL(string: "https://hendrikgrueger-web.github.io/geburtstage-geschenke-iOS/")!)
                Text("·")
                    .foregroundStyle(.tertiary)
                Link("AGB", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Purchase Action

    private func purchase(_ product: Product) async {
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }
        do {
            let transaction = try await subscriptionManager.purchase(product)
            if transaction != nil {
                dismiss()
            }
        } catch {
            errorMessage = String(localized: "Kauf fehlgeschlagen. Bitte versuche es erneut.")
            AppLogger.ui.error("Kauf fehlgeschlagen: \(error)")
        }
    }
}

// MARK: - ProductCard (private)

private struct ProductCard: View {

    let product: Product
    let isPurchasing: Bool
    let onPurchase: () async -> Void

    private var badge: String? {
        switch product.id {
        case SubscriptionManager.ProductID.yearly.rawValue:
            return String(localized: "Meistgewählt")
        case SubscriptionManager.ProductID.lifetime.rawValue:
            return String(localized: "Einmalig")
        default:
            return nil
        }
    }

    private var hasBadge: Bool { badge != nil }

    var body: some View {
        Button {
            Task { await onPurchase() }
        } label: {
            cardContent
        }
        .disabled(isPurchasing)
        .buttonStyle(.plain)
    }

    private var cardContent: some View {
        HStack(spacing: 16) {
            productIcon
            productInfo
            Spacer()
            priceInfo
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    hasBadge ? AppColor.accent : Color.clear,
                    lineWidth: hasBadge ? 2 : 0
                )
        )
    }

    private var productIcon: some View {
        ZStack {
            Circle()
                .fill(iconColor.opacity(0.15))
                .frame(width: 44, height: 44)
            Image(systemName: iconName)
                .font(.system(size: 20))
                .foregroundStyle(iconColor)
        }
    }

    private var productInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(product.displayName)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                if let badge {
                    Text(badge)
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppColor.accent)
                        .clipShape(.rect(cornerRadius: 4))
                }
            }
            Text(product.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }

    private var priceInfo: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(product.displayPrice)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
            if product.type == .autoRenewable {
                Text(String(localized: "/ Monat").lowercased())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var iconName: String {
        switch product.id {
        case SubscriptionManager.ProductID.monthly.rawValue:
            return "calendar"
        case SubscriptionManager.ProductID.yearly.rawValue:
            return "star.fill"
        case SubscriptionManager.ProductID.lifetime.rawValue:
            return "infinity"
        default:
            return "crown.fill"
        }
    }

    private var iconColor: Color {
        switch product.id {
        case SubscriptionManager.ProductID.monthly.rawValue:
            return AppColor.primary
        case SubscriptionManager.ProductID.yearly.rawValue:
            return AppColor.accent
        case SubscriptionManager.ProductID.lifetime.rawValue:
            return AppColor.secondary
        default:
            return AppColor.primary
        }
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
        .environmentObject(SubscriptionManager())
}
