import SwiftUI
import StoreKit

/// Paywall-View für das Premium-Abo.
///
/// ## Darstellung
/// Zeigt Premium-Features, Preisvergleich (Monatlich vs. Jährlich) und Kauf-Buttons.
/// Nutzt native StoreKit 2 UI-Patterns für HIG-konforme Darstellung.
///
/// ## Verwendung
/// ```swift
/// .sheet(isPresented: $showingPaywall) {
///     PaywallView()
/// }
/// ```
///
/// ## Premium-Features (kommuniziert dem User)
/// - Unbegrenzte Personen (statt 5)
/// - KI-Geschenkvorschläge via Cloud
/// - KI-Geburtstagsnachrichten
/// - Birthday Widget
/// - Unbegrenzte Erinnerungen
struct PaywallView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProduct: Product?
    @State private var introOfferEligible: [String: Bool] = [:]
    @State private var showingError = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    featuresSection
                    productsSection
                    footerSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Schließen") {
                        dismiss()
                    }
                }
            }
            .alert("Fehler", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                if let error = subscriptionManager.lastError {
                    Text(error.localizedDescription)
                }
            }
            .onChange(of: subscriptionManager.lastError?.id) { _, newID in
                showingError = newID != nil
            }
            .task {
                // Intro-Offer-Eligibility für alle Produkte prüfen
                for product in subscriptionManager.products {
                    let eligible = await subscriptionManager.isEligibleForIntroOffer(product: product)
                    introOfferEligible[product.id] = eligible
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundStyle(.linearGradient(
                    colors: [.orange, .yellow],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            Text("AI Presents Premium")
                .font(.title.bold())

            Text("Bessere Geschenke. Weniger Stress.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(spacing: 0) {
            featureRow(
                icon: "person.3.fill",
                color: .blue,
                title: "Unbegrenzte Kontakte",
                subtitle: "Statt nur \(SubscriptionManager.freePersonLimit) Personen"
            )

            Divider().padding(.leading, 52)

            featureRow(
                icon: "sparkles",
                color: .orange,
                title: "KI-Geschenkvorschläge",
                subtitle: "Personalisiert via Cloud-KI"
            )

            Divider().padding(.leading, 52)

            featureRow(
                icon: "text.quote",
                color: .purple,
                title: "KI-Geburtstagsnachrichten",
                subtitle: "Herzliche Texte per Knopfdruck"
            )

            Divider().padding(.leading, 52)

            featureRow(
                icon: "square.grid.2x2.fill",
                color: .green,
                title: "Birthday Widget",
                subtitle: "Geburtstage auf dem Homescreen"
            )

            Divider().padding(.leading, 52)

            featureRow(
                icon: "bell.badge.fill",
                color: .red,
                title: "Unbegrenzte Erinnerungen",
                subtitle: "Nie wieder einen Geburtstag vergessen"
            )
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func featureRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.gradient)
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Products

    private var productsSection: some View {
        VStack(spacing: 12) {
            if subscriptionManager.products.isEmpty {
                ProgressView("Lade Preise…")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ForEach(subscriptionManager.products, id: \.id) { product in
                    productCard(product)
                }

                purchaseButton

                restoreButton
            }
        }
    }

    private func productCard(_ product: Product) -> some View {
        let isSelected = selectedProduct?.id == product.id || (selectedProduct == nil && isYearlyProduct(product))
        let isYearly = isYearlyProduct(product)

        return Button {
            selectedProduct = product
            HapticFeedback.selectionChanged()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(isYearly ? "Jährlich" : "Monatlich")
                            .font(.headline)

                        if isYearly {
                            Text("SPAR-TIPP")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }

                    if let introOffer = product.subscription?.introductoryOffer,
                       introOffer.paymentMode == .freeTrial,
                       introOfferEligible[product.id] == true {
                        Text("\(introOffer.period.value) Tage kostenlos testen")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.title3.bold())
                    Text(isYearly ? "pro Jahr" : "pro Monat")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if isYearly, let monthlyEquivalent = yearlyMonthlyEquivalent(product) {
                        Text("= \(monthlyEquivalent)/Monat")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var purchaseButton: some View {
        Button {
            guard let product = selectedProduct ?? yearlyProduct else { return }
            Task {
                await subscriptionManager.purchase(product)
                if subscriptionManager.isPremium {
                    dismiss()
                }
            }
        } label: {
            if subscriptionManager.isPurchasing {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            } else {
                Text(purchaseButtonText)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(subscriptionManager.isPurchasing)
    }

    private var restoreButton: some View {
        Button("Käufe wiederherstellen") {
            Task {
                await subscriptionManager.restorePurchases()
                if subscriptionManager.isPremium {
                    dismiss()
                }
            }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 8) {
            Text("Das Abo verlängert sich automatisch. Du kannst jederzeit in den iOS-Einstellungen kündigen.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                if let privacyURL = URL(string: "https://github.com/harryhirsch1878/ai-presents-app-ios/blob/main/Docs/DSGVO-AI.md") {
                    Link("Datenschutz", destination: privacyURL)
                        .font(.caption2)
                }

                if let eulaURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                    Link("Nutzungsbedingungen", destination: eulaURL)
                        .font(.caption2)
                }
            }
            .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private var yearlyProduct: Product? {
        subscriptionManager.products.first { isYearlyProduct($0) }
    }

    private func isYearlyProduct(_ product: Product) -> Bool {
        product.id == SubscriptionProduct.yearly.rawValue
    }

    private static let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        return f
    }()

    private func yearlyMonthlyEquivalent(_ product: Product) -> String? {
        let monthlyPrice = product.price / 12
        Self.currencyFormatter.locale = product.priceFormatStyle.locale
        return Self.currencyFormatter.string(from: monthlyPrice as NSDecimalNumber)
    }

    private var purchaseButtonText: String {
        let product = selectedProduct ?? yearlyProduct
        if let product,
           let intro = product.subscription?.introductoryOffer,
           intro.paymentMode == .freeTrial,
           introOfferEligible[product.id] == true {
            return "Kostenlos testen"
        }
        return "Jetzt abonnieren"
    }
}

// MARK: - Paywall Trigger (Convenience)

/// View-Extension für einfaches Paywall-Triggering.
///
/// ```swift
/// .paywallSheet(isPresented: $showPaywall)
/// ```
extension View {
    func paywallSheet(isPresented: Binding<Bool>) -> some View {
        sheet(isPresented: isPresented) {
            PaywallView()
        }
    }
}
