import Foundation
import StoreKit

// MARK: - Product Konfiguration

/// Zentrale Definition aller Subscription-Product-IDs.
///
/// ## Product-IDs in App Store Connect
/// Subscription Group: "AI Presents Premium"
/// - Monthly: `com.harryhirsch1878.aipresents.premium.monthly` (4,99 EUR)
/// - Yearly:  `com.harryhirsch1878.aipresents.premium.yearly`  (29,99 EUR, 14-Tage Free Trial)
enum SubscriptionProduct: String, CaseIterable {
    case monthly = "com.harryhirsch1878.aipresents.premium.monthly"
    case yearly  = "com.harryhirsch1878.aipresents.premium.yearly"

    /// Subscription Group ID (aus App Store Connect).
    static let groupID = "premium"

    /// Alle Product-IDs als Set (für `Product.products(for:)`).
    static var allIDs: Set<String> {
        Set(allCases.map(\.rawValue))
    }
}

// MARK: - SubscriptionManager

/// Verwaltet den gesamten StoreKit 2 Subscription-Lifecycle.
///
/// ## Verantwortlichkeiten
/// - Produkte laden (`Product.products(for:)`)
/// - Käufe durchführen (`Product.purchase()`)
/// - Aktive Berechtigungen prüfen (`Transaction.currentEntitlements`)
/// - Auf externe Transaktions-Updates reagieren (`Transaction.updates`)
/// - Restore Purchases
///
/// ## Verwendung
/// ```swift
/// // In App-Root (z.B. aiPresentsApp.swift):
/// @StateObject private var subscriptionManager = SubscriptionManager()
/// // ...
/// .environmentObject(subscriptionManager)
///
/// // In beliebiger View:
/// @EnvironmentObject private var subscriptionManager: SubscriptionManager
/// if subscriptionManager.isPremium { ... }
/// ```
///
/// ## Premium-Features (Free vs. Premium)
/// | Feature               | Free  | Premium |
/// |-----------------------|-------|---------|
/// | Personen              | 5 max | Unbegrenzt |
/// | KI-Geschenkvorschläge | Demo  | Unbegrenzt |
/// | KI-Geburtstagsnachricht | -   | Unbegrenzt |
/// | Widget                | -     | Ja |
/// | Cloud Sync (iCloud)   | Ja    | Ja |
/// | Custom Reminders      | 1     | Unbegrenzt |
@MainActor
final class SubscriptionManager: ObservableObject {

    // MARK: - Published State

    /// Alle verfügbaren Produkte, sortiert nach Preis (aufsteigend).
    @Published private(set) var products: [Product] = []

    /// IDs aller aktuell aktiven (gekauften/abonnierten) Produkte.
    @Published private(set) var purchasedProductIDs: Set<String> = []

    /// True wenn gerade ein Kauf läuft.
    @Published private(set) var isPurchasing = false

    /// Letzter Fehler (z.B. bei Kauf oder Laden).
    @Published var lastError: SubscriptionError?

    // MARK: - Computed Properties

    /// True wenn der User ein aktives Premium-Abo hat (Monthly oder Yearly).
    var isPremium: Bool {
        !purchasedProductIDs.isDisjoint(with: SubscriptionProduct.allIDs)
    }

    /// Das aktuell aktive Produkt (nil wenn kein Abo).
    var activeProduct: Product? {
        products.first { purchasedProductIDs.contains($0.id) }
    }

    /// Maximale Anzahl Personen im Free-Tier.
    static let freePersonLimit = 5

    /// True wenn der User im Free-Tier weitere Personen hinzufügen kann.
    func canAddPerson(currentCount: Int) -> Bool {
        isPremium || currentCount < Self.freePersonLimit
    }

    // MARK: - Private

    /// Task-Handle für den Transaction.updates-Listener.
    private var transactionListenerTask: Task<Void, Never>?

    // MARK: - Init / Deinit

    init() {
        // Transaction-Updates sofort lauschen (auch für Käufe auf anderen Geräten)
        transactionListenerTask = listenForTransactionUpdates()

        // Produkte und aktuelle Berechtigungen laden
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    // MARK: - Produkte laden

    /// Lädt alle verfügbaren Subscription-Produkte aus dem App Store.
    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: SubscriptionProduct.allIDs)
            // Nach Preis sortieren (Monthly zuerst, dann Yearly)
            products = storeProducts.sorted { $0.price < $1.price }
            AppLogger.data.info("StoreKit: \(storeProducts.count) Produkte geladen")
        } catch {
            AppLogger.data.error("StoreKit: Produkte laden fehlgeschlagen", error: error)
            lastError = .productLoadFailed(error)
        }
    }

    // MARK: - Kauf

    /// Startet den Kaufprozess für ein Produkt.
    ///
    /// - Parameter product: Das zu kaufende `Product`.
    /// - Returns: `true` wenn der Kauf erfolgreich war.
    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updatePurchasedProducts()
                AppLogger.data.info("StoreKit: Kauf erfolgreich — \(product.id)")
                return true

            case .userCancelled:
                AppLogger.data.info("StoreKit: Kauf abgebrochen vom User")
                return false

            case .pending:
                AppLogger.data.info("StoreKit: Kauf ausstehend (z.B. Elternfreigabe)")
                return false

            @unknown default:
                AppLogger.data.warning("StoreKit: Unbekanntes Kauf-Ergebnis")
                return false
            }
        } catch {
            AppLogger.data.error("StoreKit: Kauf fehlgeschlagen", error: error)
            lastError = .purchaseFailed(error)
            return false
        }
    }

    // MARK: - Restore Purchases

    /// Stellt vorherige Käufe wieder her (z.B. nach Neuinstallation).
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            AppLogger.data.info("StoreKit: Käufe wiederhergestellt")
        } catch {
            AppLogger.data.error("StoreKit: Restore fehlgeschlagen", error: error)
            lastError = .restoreFailed(error)
        }
    }

    // MARK: - Berechtigungen prüfen

    /// Prüft alle aktiven Berechtigungen und aktualisiert `purchasedProductIDs`.
    func updatePurchasedProducts() async {
        var activeIDs: Set<String> = []

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                // Nur aktive (nicht abgelaufene/widerrufene) Transaktionen
                if transaction.revocationDate == nil {
                    activeIDs.insert(transaction.productID)
                }
            }
        }

        purchasedProductIDs = activeIDs
        AppLogger.data.debug("StoreKit: Aktive Berechtigungen = \(activeIDs)")
    }

    // MARK: - Transaction Listener

    /// Lauscht auf externe Transaktions-Updates (Käufe auf anderen Geräten, Abo-Verlängerungen, Stornierungen).
    private func listenForTransactionUpdates() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if let transaction = try? self.checkVerified(result) {
                    await transaction.finish()
                    await self.updatePurchasedProducts()
                    AppLogger.data.info("StoreKit: Transaction-Update verarbeitet — \(transaction.productID)")
                }
            }
        }
    }

    // MARK: - Verification

    /// Prüft die kryptographische Signatur einer Transaktion.
    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified(_, let error):
            AppLogger.data.error("StoreKit: Verification fehlgeschlagen — \(error)")
            throw SubscriptionError.verificationFailed(error)
        }
    }

    // MARK: - Intro Offer Eligibility

    /// Prüft ob der User für das Intro-Angebot (Free Trial) berechtigt ist.
    func isEligibleForIntroOffer(product: Product) async -> Bool {
        await product.subscription?.isEligibleForIntroOffer ?? false
    }
}

// MARK: - Fehler

/// Subscription-spezifische Fehler.
enum SubscriptionError: LocalizedError, Identifiable {
    case productLoadFailed(Error)
    case purchaseFailed(Error)
    case restoreFailed(Error)
    case verificationFailed(Error)

    var id: String {
        switch self {
        case .productLoadFailed: return "productLoadFailed"
        case .purchaseFailed: return "purchaseFailed"
        case .restoreFailed: return "restoreFailed"
        case .verificationFailed: return "verificationFailed"
        }
    }

    var errorDescription: String? {
        switch self {
        case .productLoadFailed:
            return "Abo-Produkte konnten nicht geladen werden. Bitte prüfe deine Internetverbindung."
        case .purchaseFailed:
            return "Der Kauf konnte nicht abgeschlossen werden. Bitte versuche es erneut."
        case .restoreFailed:
            return "Käufe konnten nicht wiederhergestellt werden. Bitte versuche es erneut."
        case .verificationFailed:
            return "Die Kaufverifizierung ist fehlgeschlagen."
        }
    }
}
