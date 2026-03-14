import StoreKit
import SwiftUI
import UserNotifications
import os

/// Verwaltet StoreKit 2 Käufe, Abonnements und den 3-Monats-Trial.
@MainActor
final class SubscriptionManager: ObservableObject {

    // MARK: - Product IDs

    enum ProductID: String, CaseIterable {
        case monthly  = "com.hendrikgrueger.birthdays.presents.ai.monthly"
        case yearly   = "com.hendrikgrueger.birthdays.presents.ai.yearly"
        case lifetime = "com.hendrikgrueger.birthdays.presents.ai.lifetime"
    }

    // MARK: - Published State

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoading = false

    // MARK: - Trial Constants

    private static let trialStartKey = "subscriptionTrialStartDate"
    private static let trialDurationDays = 14

    // MARK: - Trial Properties

    var trialStartDate: Date? {
        UserDefaults.standard.object(forKey: Self.trialStartKey) as? Date
    }

    var trialEndDate: Date {
        guard let start = trialStartDate else { return .distantPast }
        return Calendar.current.date(byAdding: .day, value: Self.trialDurationDays, to: start) ?? .distantPast
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
        scheduleTrialReminders()
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

    // MARK: - Trial Notifications

    /// Plant Push-Benachrichtigungen für 7 Tage und 1 Tag vor Trial-Ende.
    func scheduleTrialReminders() {
        guard isInTrial else { return }
        let center = UNUserNotificationCenter.current()

        // Bestehende Trial-Notifications entfernen
        center.removePendingNotificationRequests(withIdentifiers: ["trial-7days", "trial-1day"])

        let trialEnd = trialEndDate

        // 7 Tage vorher
        if let sevenDaysBefore = Calendar.current.date(byAdding: .day, value: -7, to: trialEnd),
           sevenDaysBefore > Date() {
            let content = UNMutableNotificationContent()
            content.title = String(localized: "Testzeitraum endet bald")
            content.body = String(localized: "Noch 7 Tage kostenlos. Sichere dir jetzt alle Features!")
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour], from: sevenDaysBefore),
                repeats: false
            )
            center.add(UNNotificationRequest(identifier: "trial-7days", content: content, trigger: trigger))
            AppLogger.notifications.info("Trial-Reminder (7 Tage) geplant: \(sevenDaysBefore)")
        }

        // 1 Tag vorher
        if let oneDayBefore = Calendar.current.date(byAdding: .day, value: -1, to: trialEnd),
           oneDayBefore > Date() {
            let content = UNMutableNotificationContent()
            content.title = String(localized: "Letzter Tag!")
            content.body = String(localized: "Morgen endet dein Testzeitraum. Upgrade für vollen Zugriff!")
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour], from: oneDayBefore),
                repeats: false
            )
            center.add(UNNotificationRequest(identifier: "trial-1day", content: content, trigger: trigger))
            AppLogger.notifications.info("Trial-Reminder (1 Tag) geplant: \(oneDayBefore)")
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

    /// Ist `nonisolated` damit es aus Task.detached aufgerufen werden kann.
    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw StoreError.failedVerification
        case .verified(let safe): return safe
        }
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


    // MARK: - Errors

    enum StoreError: Error { case failedVerification }
}
