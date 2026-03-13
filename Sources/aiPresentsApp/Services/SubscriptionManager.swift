import StoreKit
import SwiftUI

/// Verwaltet StoreKit 2 Käufe, Abonnements und den 3-Monats-Trial.
@MainActor
final class SubscriptionManager: ObservableObject {

    // MARK: - Product IDs

    enum ProductID: String, CaseIterable {
        case monthly  = "com.hendrikgrueger.birthdays-presents-ai.monthly"
        case yearly   = "com.hendrikgrueger.birthdays-presents-ai.yearly"
        case lifetime = "com.hendrikgrueger.birthdays-presents-ai.lifetime"
    }

    // MARK: - Published State

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoading = false

    // MARK: - Trial Constants

    private static let trialStartKey = "subscriptionTrialStartDate"
    private static let trialDurationMonths = 3

    // MARK: - Trial Properties

    var trialStartDate: Date? {
        UserDefaults.standard.object(forKey: Self.trialStartKey) as? Date
    }

    var trialEndDate: Date {
        guard let start = trialStartDate else { return .distantPast }
        return Calendar.current.date(byAdding: .month, value: Self.trialDurationMonths, to: start) ?? .distantPast
    }

    var isInTrial: Bool {
        guard !isSubscribed else { return false }
        guard trialStartDate != nil else { return false }
        return Date() < trialEndDate
    }

    var trialDaysRemaining: Int {
        guard isInTrial else { return 0 }
        return max(0, Calendar.current.dateComponents([.day], from: Date(), to: trialEndDate).day ?? 0)
    }

    // MARK: - Access

    /// Nutzer hat ein aktives Abonnement oder Lifetime-Kauf.
    var isSubscribed: Bool { !purchasedProductIDs.isEmpty }

    /// Nutzer hat vollen Zugriff (Abo oder Trial aktiv).
    var hasFullAccess: Bool { isSubscribed || isInTrial }

    // MARK: - Transaction Listener

    private var transactionListener: Task<Void, Never>?

    // MARK: - Init / Deinit

    init() {
        startTrialIfNeeded()
        transactionListener = listenForTransactions()
        Task { await updatePurchasedProducts() }
    }

    deinit { transactionListener?.cancel() }

    // MARK: - Trial

    /// Startet den Trial beim ersten App-Start, falls noch nicht gestartet.
    func startTrialIfNeeded() {
        if UserDefaults.standard.object(forKey: Self.trialStartKey) == nil {
            UserDefaults.standard.set(Date(), forKey: Self.trialStartKey)
            AppLogger.data.info("Trial gestartet")
        }
    }

    // MARK: - Products

    /// Lädt alle Produkte vom App Store (oder StoreKit-Konfiguration im Debug).
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: ProductID.allCases.map(\.rawValue))
                .sorted { $0.price < $1.price }
            AppLogger.data.info("Produkte geladen: \(products.count)")
        } catch {
            AppLogger.data.error("Produkte laden fehlgeschlagen: \(error)")
        }
    }

    // MARK: - Purchase

    /// Kauft ein Produkt und gibt die verifizierte Transaktion zurück.
    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updatePurchasedProducts()
            AppLogger.data.info("Kauf erfolgreich: \(product.id)")
            return transaction
        case .userCancelled, .pending:
            return nil
        @unknown default:
            return nil
        }
    }

    // MARK: - Restore

    /// Stellt frühere Käufe wieder her (App Store Sync).
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            AppLogger.data.info("Käufe wiederhergestellt")
        } catch {
            AppLogger.data.error("Wiederherstellen fehlgeschlagen: \(error)")
        }
    }

    // MARK: - Transaction Management

    /// Aktualisiert `purchasedProductIDs` anhand aller aktuellen Berechtigungen.
    func updatePurchasedProducts() async {
        var purchased: Set<String> = []
        for await result in StoreKit.Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                purchased.insert(transaction.productID)
            }
        }
        purchasedProductIDs = purchased
    }

    /// Lauscht auf neue Transaktionen (z.B. nach Abo-Verlängerung im Hintergrund).
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in StoreKit.Transaction.updates {
                if let transaction = try? self?.checkVerified(result) {
                    await transaction.finish()
                    await self?.updatePurchasedProducts()
                }
            }
        }
    }

    /// Prüft die StoreKit-Verifikation und wirft bei Fehlschlag.
    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw StoreError.failedVerification
        case .verified(let safe): return safe
        }
    }

    // MARK: - Errors

    enum StoreError: Error { case failedVerification }
}
