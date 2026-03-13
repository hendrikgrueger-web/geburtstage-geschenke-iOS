# Subscription & Monetization Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Freemium-Monetarisierung mit 3-Monats-Trial, danach Read-Only. Drei Kauf-Optionen: Monatsabo €2,90, Jahresabo €19,90, Lifetime €29,90.

**Architecture:** SubscriptionManager (ObservableObject, @MainActor) verwaltet StoreKit 2 Produkte, Transaktionen und lokale Trial-Logik. PaywallView zeigt die drei Optionen. Ein `.premiumGate()` ViewModifier blockt alle Bearbeitungs-Aktionen nach Trial-Ablauf und zeigt stattdessen die Paywall.

**Tech Stack:** Swift 6, StoreKit 2, SwiftUI, SwiftData (iOS 26+)

---

## File Structure

### New Files

| File | Responsibility |
|------|---------------|
| `Sources/aiPresentsApp/Services/SubscriptionManager.swift` | StoreKit 2 Product/Transaction Management + lokale Trial-Logik |
| `Sources/aiPresentsApp/Views/Subscription/PaywallView.swift` | Paywall-UI mit 3 Preisoptionen + Trial-Status |
| `Sources/aiPresentsApp/Views/Subscription/PremiumGateModifier.swift` | ViewModifier der Bearbeitungs-Buttons bei abgelaufenem Trial deaktiviert |
| `Sources/aiPresentsApp/Views/Subscription/ReadOnlyBanner.swift` | Banner "Trial abgelaufen" für Timeline/Detail-Views |
| `App/Products.storekit` | StoreKit Configuration File für lokales Testen |

### Modified Files

| File | Changes |
|------|---------|
| `Sources/aiPresentsApp/aiPresentsApp.swift` | SubscriptionManager als .environmentObject + Transaction-Listener |
| `App/aiPresentsApp.entitlements` | In-App-Purchase Entitlement hinzufügen |
| `project.yml` | StoreKit Capability + StoreKit Config Referenz |
| `Sources/aiPresentsApp/Views/Settings/SettingsView.swift` | Abo-Status-Section + Paywall-Button + Restore |
| `Sources/aiPresentsApp/Views/Timeline/TimelineView.swift` | ReadOnlyBanner + Premium-Gates auf Add/Edit-Aktionen |
| `Sources/aiPresentsApp/Views/Person/PersonDetailView.swift` | Premium-Gates auf alle Bearbeitungs-Aktionen |
| `Sources/aiPresentsApp/Views/Person/ContactsImportView.swift` | Premium-Gate auf Import-Button |
| `Sources/aiPresentsApp/Localizable.xcstrings` | Neue Strings (DE + EN) |

---

## Task 1: Project Configuration & Entitlements

**Files:**
- Modify: `App/aiPresentsApp.entitlements`
- Modify: `project.yml`
- Create: `App/Products.storekit`

- [ ] **Step 1: Add In-App Purchase entitlement**

In `App/aiPresentsApp.entitlements`, add the IAP entitlement:

```xml
<key>com.apple.developer.in-app-payments</key>
<array>
    <string>merchant.com.hendrikgrueger.birthdays-presents-ai</string>
</array>
```

- [ ] **Step 2: Update project.yml — add StoreKit capability**

In `project.yml` under the `aiPresentsApp` target's `settings`, add:

```yaml
capabilities:
  - In-App Purchase
```

And add the StoreKit configuration file reference under `scheme` or as a resource.

- [ ] **Step 3: Create StoreKit Configuration file**

Create `App/Products.storekit` with three products for local testing:

```json
{
  "identifier": "com.hendrikgrueger.birthdays-presents-ai.products",
  "products": [
    {
      "displayPrice": "2.90",
      "familyShareable": false,
      "internalID": "monthly_sub",
      "localizations": [
        { "locale": "de", "displayName": "Premium Monatlich", "description": "Voller Zugriff auf alle Features" },
        { "locale": "en", "displayName": "Premium Monthly", "description": "Full access to all features" }
      ],
      "productID": "com.hendrikgrueger.birthdays-presents-ai.monthly",
      "referenceName": "Premium Monthly",
      "subscriptionGroupID": "premium_group",
      "type": "RecurringSubscription",
      "subscriptionPeriod": "P1M"
    },
    {
      "displayPrice": "19.90",
      "familyShareable": false,
      "internalID": "yearly_sub",
      "localizations": [
        { "locale": "de", "displayName": "Premium Jährlich", "description": "Voller Zugriff — 43% günstiger" },
        { "locale": "en", "displayName": "Premium Yearly", "description": "Full access — 43% savings" }
      ],
      "productID": "com.hendrikgrueger.birthdays-presents-ai.yearly",
      "referenceName": "Premium Yearly",
      "subscriptionGroupID": "premium_group",
      "type": "RecurringSubscription",
      "subscriptionPeriod": "P1Y"
    },
    {
      "displayPrice": "29.90",
      "familyShareable": false,
      "internalID": "lifetime",
      "localizations": [
        { "locale": "de", "displayName": "Premium Lifetime", "description": "Einmal kaufen, für immer nutzen" },
        { "locale": "en", "displayName": "Premium Lifetime", "description": "Buy once, use forever" }
      ],
      "productID": "com.hendrikgrueger.birthdays-presents-ai.lifetime",
      "referenceName": "Premium Lifetime",
      "type": "NonConsumable"
    }
  ],
  "settings": {
    "_applicationInternalID": "6760319397",
    "_developerTeamID": "CU87QNNB3N"
  },
  "subscriptionGroups": [
    {
      "id": "premium_group",
      "localizations": [
        { "locale": "de", "displayName": "Premium", "description": "Premium-Abo" },
        { "locale": "en", "displayName": "Premium", "description": "Premium subscription" }
      ],
      "name": "Premium",
      "subscriptions": ["monthly_sub", "yearly_sub"]
    }
  ],
  "version": { "major": 3, "minor": 0 }
}
```

- [ ] **Step 4: Run xcodegen and verify build**

```bash
cd "/Users/hendrik.grueger/Coding/1_privat/Apple Apps/ai-presents-app-ios" && xcodegen generate
xcodebuild -project ai-presents-app-ios.xcodeproj -scheme aiPresentsApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: Build succeeds.

- [ ] **Step 5: Commit**

```bash
git add App/aiPresentsApp.entitlements App/Products.storekit project.yml
git commit -m "chore: StoreKit 2 Projekt-Konfiguration (Entitlements, Products.storekit)"
```

---

## Task 2: SubscriptionManager Service

**Files:**
- Create: `Sources/aiPresentsApp/Services/SubscriptionManager.swift`

- [ ] **Step 1: Create SubscriptionManager**

```swift
import StoreKit
import SwiftUI

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

    // MARK: - Trial

    private static let trialStartKey = "subscriptionTrialStartDate"
    private static let trialDurationMonths = 3

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

    var isSubscribed: Bool {
        !purchasedProductIDs.isEmpty
    }

    var hasFullAccess: Bool {
        isSubscribed || isInTrial
    }

    // MARK: - Init

    private var transactionListener: Task<Void, Never>?

    init() {
        startTrialIfNeeded()
        transactionListener = listenForTransactions()
        Task { await updatePurchasedProducts() }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Trial

    func startTrialIfNeeded() {
        if UserDefaults.standard.object(forKey: Self.trialStartKey) == nil {
            UserDefaults.standard.set(Date(), forKey: Self.trialStartKey)
            AppLogger.data.info("Trial gestartet")
        }
    }

    // MARK: - Products

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

    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updatePurchasedProducts()
            AppLogger.data.info("Kauf erfolgreich: \(product.id)")
            return transaction
        case .userCancelled:
            return nil
        case .pending:
            return nil
        @unknown default:
            return nil
        }
    }

    // MARK: - Restore

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

    func updatePurchasedProducts() async {
        var purchased: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                purchased.insert(transaction.productID)
            }
        }
        purchasedProductIDs = purchased
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if let transaction = try? self?.checkVerified(result) {
                    await transaction.finish()
                    await self?.updatePurchasedProducts()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    enum StoreError: Error {
        case failedVerification
    }
}
```

- [ ] **Step 2: Run xcodegen + build**

```bash
cd "/Users/hendrik.grueger/Coding/1_privat/Apple Apps/ai-presents-app-ios" && xcodegen generate
xcodebuild -project ai-presents-app-ios.xcodeproj -scheme aiPresentsApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add Sources/aiPresentsApp/Services/SubscriptionManager.swift
git commit -m "feat: SubscriptionManager mit StoreKit 2, Trial-Logik und Transaction-Listener"
```

---

## Task 3: PaywallView

**Files:**
- Create: `Sources/aiPresentsApp/Views/Subscription/PaywallView.swift`

- [ ] **Step 1: Create PaywallView**

Design: Apple HIG-konform, drei Karten (Monthly hervorgehoben als "Beliebt", Yearly als "Bester Preis", Lifetime als "Einmalig"). Trial-Status oben. Restore-Button unten.

```swift
import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    if subscriptionManager.isInTrial {
                        trialBanner
                    }
                    productsSection
                    restoreSection
                    legalSection
                }
                .padding()
            }
            .navigationTitle(String(localized: "Premium"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Schließen")) { dismiss() }
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppColor.accent)
            Text("Alle Features freischalten")
                .font(.title2.bold())
            Text("Unbegrenzter Zugriff auf KI-Vorschläge, Geschenkeverwaltung und mehr.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Trial Banner

    private var trialBanner: some View {
        HStack {
            Image(systemName: "clock.fill")
            Text("Noch \(subscriptionManager.trialDaysRemaining) Tage kostenlos testen")
                .font(.subheadline.bold())
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppColor.accent.opacity(0.15))
        .clipShape(.rect(cornerRadius: 12))
    }

    // MARK: - Products

    private var productsSection: some View {
        VStack(spacing: 12) {
            if subscriptionManager.isLoading {
                ProgressView()
            } else if subscriptionManager.products.isEmpty {
                Text("Produkte werden geladen…")
                    .foregroundStyle(.secondary)
                    .task { await subscriptionManager.loadProducts() }
            } else {
                ForEach(subscriptionManager.products, id: \.id) { product in
                    ProductCard(
                        product: product,
                        isPurchasing: isPurchasing,
                        badge: badgeFor(product),
                        onPurchase: { purchaseProduct(product) }
                    )
                }
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(AppColor.danger)
            }
        }
    }

    // MARK: - Restore

    private var restoreSection: some View {
        Button(String(localized: "Käufe wiederherstellen")) {
            Task { await subscriptionManager.restorePurchases() }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }

    // MARK: - Legal

    private var legalSection: some View {
        VStack(spacing: 4) {
            Text("Das Abo verlängert sich automatisch. Jederzeit kündbar.")
            Text("[Datenschutz](https://hendrikgrueger-web.github.io/geburtstage-geschenke-iOS/) · [AGB](https://www.apple.com/legal/internet-services/itunes/dev/stdeula/)")
        }
        .font(.caption2)
        .foregroundStyle(.tertiary)
        .multilineTextAlignment(.center)
    }

    // MARK: - Helpers

    private func badgeFor(_ product: Product) -> String? {
        switch product.id {
        case SubscriptionManager.ProductID.yearly.rawValue:
            return String(localized: "Bester Preis")
        case SubscriptionManager.ProductID.lifetime.rawValue:
            return String(localized: "Einmalig")
        default:
            return nil
        }
    }

    private func purchaseProduct(_ product: Product) {
        isPurchasing = true
        errorMessage = nil
        Task {
            do {
                let transaction = try await subscriptionManager.purchase(product)
                if transaction != nil {
                    dismiss()
                }
            } catch {
                errorMessage = String(localized: "Kauf fehlgeschlagen. Bitte versuche es erneut.")
                AppLogger.data.error("Kauf-Fehler: \(error)")
            }
            isPurchasing = false
        }
    }
}

// MARK: - Product Card

private struct ProductCard: View {
    let product: Product
    let isPurchasing: Bool
    let badge: String?
    let onPurchase: () -> Void

    var body: some View {
        Button(action: onPurchase) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(product.displayName)
                            .font(.headline)
                        if let badge {
                            Text(badge)
                                .font(.caption2.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(AppColor.accent)
                                .foregroundStyle(.white)
                                .clipShape(.capsule)
                        }
                    }
                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.title3.bold())
                    .foregroundStyle(AppColor.accent)
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(badge != nil ? AppColor.accent : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(isPurchasing)
    }
}
```

- [ ] **Step 2: Run xcodegen + build**

```bash
xcodegen generate && xcodebuild -project ai-presents-app-ios.xcodeproj -scheme aiPresentsApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

- [ ] **Step 3: Commit**

```bash
git add Sources/aiPresentsApp/Views/Subscription/PaywallView.swift
git commit -m "feat: PaywallView mit 3 Preisoptionen, Trial-Banner und Restore"
```

---

## Task 4: PremiumGateModifier & ReadOnlyBanner

**Files:**
- Create: `Sources/aiPresentsApp/Views/Subscription/PremiumGateModifier.swift`
- Create: `Sources/aiPresentsApp/Views/Subscription/ReadOnlyBanner.swift`

- [ ] **Step 1: Create PremiumGateModifier**

Ein ViewModifier, der Buttons/Actions mit Paywall-Sheet umleitet wenn kein Vollzugriff:

```swift
import SwiftUI

struct PremiumGateModifier: ViewModifier {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
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
                    .environmentObject(subscriptionManager)
            }
    }
}

extension View {
    func premiumGate() -> some View {
        modifier(PremiumGateModifier())
    }
}
```

- [ ] **Step 2: Create ReadOnlyBanner**

Banner das oben in Timeline/Detail-Views angezeigt wird wenn Trial abgelaufen:

```swift
import SwiftUI

struct ReadOnlyBanner: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var showingPaywall = false

    var body: some View {
        if !subscriptionManager.hasFullAccess {
            Button {
                showingPaywall = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
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
                    .environmentObject(subscriptionManager)
            }
        } else if subscriptionManager.isInTrial {
            HStack(spacing: 8) {
                Image(systemName: "clock.fill")
                Text("Noch \(subscriptionManager.trialDaysRemaining) Tage kostenlos")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal)
        }
    }
}
```

- [ ] **Step 3: Run xcodegen + build**

- [ ] **Step 4: Commit**

```bash
git add Sources/aiPresentsApp/Views/Subscription/PremiumGateModifier.swift Sources/aiPresentsApp/Views/Subscription/ReadOnlyBanner.swift
git commit -m "feat: PremiumGateModifier (Read-Only) und ReadOnlyBanner"
```

---

## Task 5: App Entry Point Integration

**Files:**
- Modify: `Sources/aiPresentsApp/aiPresentsApp.swift`

- [ ] **Step 1: Add SubscriptionManager as @StateObject and environmentObject**

In `aiPresentsApp.swift`:

1. Add `@StateObject private var subscriptionManager = SubscriptionManager()` alongside the existing `reminderManager`
2. Add `.environmentObject(subscriptionManager)` to the ContentView, alongside the existing `.environmentObject(reminderManager)`

- [ ] **Step 2: Build and verify**

- [ ] **Step 3: Commit**

```bash
git add Sources/aiPresentsApp/aiPresentsApp.swift
git commit -m "feat: SubscriptionManager als EnvironmentObject in App-Root"
```

---

## Task 6: Premium-Gating in TimelineView

**Files:**
- Modify: `Sources/aiPresentsApp/Views/Timeline/TimelineView.swift`

- [ ] **Step 1: Add ReadOnlyBanner**

Add `ReadOnlyBanner()` at the top of the Timeline list (before the birthday rows).

- [ ] **Step 2: Gate "Add" actions**

Apply `.premiumGate()` to these elements:
- **Line ~102-106:** NavigationLink to ContactsImportView → wrap with `.premiumGate()`
- **Line ~247-249:** Quick-Add callback in BirthdayRow → check `subscriptionManager.hasFullAccess` before setting `showingAddGiftIdeaFor`
- **Line ~259-263:** Context menu "Idee hinzufügen" → add `.premiumGate()` or check before action
- **Line ~274-280:** Context menu "Erste Idee planen" → check before action
- **Line ~38-48:** Swipe action skipGift toggle → check before action
- **Line ~315:** Smart Search Bar (AI Chat) → check before opening AIChatView

Pattern for button-based gates:

```swift
Button { ... } label: { ... }
    .disabled(!subscriptionManager.hasFullAccess)
```

For context menu items, add a conditional check:

```swift
Button {
    if subscriptionManager.hasFullAccess {
        // original action
    } else {
        showingPaywall = true
    }
} label: { ... }
```

Add `@EnvironmentObject private var subscriptionManager: SubscriptionManager` and `@State private var showingPaywall = false` to TimelineView. Add `.sheet(isPresented: $showingPaywall) { PaywallView() }` on the top-level body.

- [ ] **Step 3: Build and verify**

- [ ] **Step 4: Commit**

```bash
git add Sources/aiPresentsApp/Views/Timeline/TimelineView.swift
git commit -m "feat: Premium-Gating in TimelineView — Read-Only nach Trial"
```

---

## Task 7: Premium-Gating in PersonDetailView

**Files:**
- Modify: `Sources/aiPresentsApp/Views/Person/PersonDetailView.swift`

- [ ] **Step 1: Add ReadOnlyBanner and SubscriptionManager**

Add `@EnvironmentObject private var subscriptionManager: SubscriptionManager` to PersonDetailView.

- [ ] **Step 2: Gate all edit actions**

Gate these 15 entry points (check `hasFullAccess` or use `.premiumGate()`):

| Line | Action | Gating |
|------|--------|--------|
| ~121-127 | skipGift Toggle | `.disabled(!hasFullAccess)` |
| ~106-118 | Relation Picker tap | check before opening |
| ~152, 224, 499 | Add Gift Idea (+) | check before `showingAddGiftIdea = true` |
| ~160 | Edit Gift Idea (tap) | check before `showingEditGiftIdea = idea` |
| ~176 | Advance Gift Status (swipe) | check before advancing |
| ~307, 343 | Add Gift History (+) | check before opening |
| ~315, 369 | Edit Gift History (tap) | check before opening |
| ~323 | Copy to Gift Idea (swipe) | check before creating |
| ~331, 377 | Delete (swipe) | keep enabled (deleting in Read-Only is OK) |
| ~438 | KI-Vorschläge Button | check before opening |
| ~442 | Geburtstagsnachricht Button | check before opening |
| ~455-462 | Remove Person | keep enabled |
| ~467 | Edit Person (toolbar) | check before opening |

**Note:** Löschen und Entfernen bleiben erlaubt — Read-Only bezieht sich auf Erstellen/Bearbeiten, nicht Aufräumen.

Add `@State private var showingPaywall = false` and `.sheet` for PaywallView on top-level body.

- [ ] **Step 3: Build and verify**

- [ ] **Step 4: Commit**

```bash
git add Sources/aiPresentsApp/Views/Person/PersonDetailView.swift
git commit -m "feat: Premium-Gating in PersonDetailView — 15 Bearbeitungs-Aktionen"
```

---

## Task 8: Premium-Gating in ContactsImportView

**Files:**
- Modify: `Sources/aiPresentsApp/Views/Person/ContactsImportView.swift`

- [ ] **Step 1: Gate import actions**

Add `@EnvironmentObject private var subscriptionManager: SubscriptionManager`.

Gate:
- "Kontakte importieren" button (~line 38, 123)
- "Mit Beispieldaten starten" button (~line 54, 166)

Show PaywallView sheet when tapped without access.

- [ ] **Step 2: Build and commit**

```bash
git add Sources/aiPresentsApp/Views/Person/ContactsImportView.swift
git commit -m "feat: Premium-Gating auf Kontakt-Import"
```

---

## Task 9: Settings Integration

**Files:**
- Modify: `Sources/aiPresentsApp/Views/Settings/SettingsView.swift`

- [ ] **Step 1: Add Abo-Status Section**

Add a new Section at the TOP of the Settings list:

```swift
Section {
    if subscriptionManager.isSubscribed {
        Label(String(localized: "Premium aktiv"), systemImage: "crown.fill")
            .foregroundStyle(AppColor.accent)
    } else if subscriptionManager.isInTrial {
        Button {
            showingPaywall = true
        } label: {
            HStack {
                Label("Testphase", systemImage: "clock.fill")
                Spacer()
                Text("Noch \(subscriptionManager.trialDaysRemaining) Tage")
                    .foregroundStyle(.secondary)
            }
        }
    } else {
        Button {
            showingPaywall = true
        } label: {
            Label(String(localized: "Premium freischalten"), systemImage: "crown")
                .foregroundStyle(AppColor.accent)
        }
    }

    Button(String(localized: "Käufe wiederherstellen")) {
        Task { await subscriptionManager.restorePurchases() }
    }
} header: {
    Text("Abo")
}
```

Add `@EnvironmentObject private var subscriptionManager: SubscriptionManager`, `@State private var showingPaywall = false`, and `.sheet(isPresented: $showingPaywall) { PaywallView() }`.

- [ ] **Step 2: Build and commit**

```bash
git add Sources/aiPresentsApp/Views/Settings/SettingsView.swift
git commit -m "feat: Abo-Status und Paywall in Settings"
```

---

## Task 10: Localization

**Files:**
- Modify: `Sources/aiPresentsApp/Localizable.xcstrings`

- [ ] **Step 1: Add all new strings**

Neue Strings die in den Views verwendet werden (SwiftUI-Texts mit String-Literalen werden automatisch als `LocalizedStringKey` extrahiert). Manuell zu ergänzen:

| Deutsch | English |
|---------|---------|
| Premium | Premium |
| Alle Features freischalten | Unlock all features |
| Schließen | Close |
| Noch %lld Tage kostenlos testen | %lld days free trial remaining |
| Noch %lld Tage kostenlos | %lld days free remaining |
| Bester Preis | Best value |
| Einmalig | One-time |
| Käufe wiederherstellen | Restore purchases |
| Kauf fehlgeschlagen. Bitte versuche es erneut. | Purchase failed. Please try again. |
| Testphase abgelaufen | Trial expired |
| Upgrade für vollen Zugriff | Upgrade for full access |
| Testphase | Trial period |
| Premium aktiv | Premium active |
| Premium freischalten | Unlock Premium |
| Abo | Subscription |

**Methode:** Build in Xcode → String Catalog wird automatisch mit neuen Keys aktualisiert → dann EN-Übersetzungen manuell eintragen.

- [ ] **Step 2: Commit**

```bash
git add Sources/aiPresentsApp/Localizable.xcstrings
git commit -m "i18n: Subscription-Strings (DE + EN)"
```

---

## Task 11: Build, Test & Final Commit

- [ ] **Step 1: Full build**

```bash
xcodebuild -project ai-presents-app-ios.xcodeproj -scheme aiPresentsApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: 0 errors, 0 new warnings.

- [ ] **Step 2: Run existing tests**

```bash
xcodebuild -project ai-presents-app-ios.xcodeproj -scheme aiPresentsAppTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

Expected: All existing tests pass (no regressions).

- [ ] **Step 3: Verify in Simulator**

1. App starten → Trial-Banner in Timeline sichtbar ("Noch X Tage kostenlos")
2. Settings öffnen → Abo-Section mit Trial-Status sichtbar
3. Alle Bearbeitungs-Aktionen funktionieren (Trial aktiv)
4. UserDefaults Trial-Datum auf 4 Monate zurück setzen → App neu starten
5. ReadOnlyBanner erscheint → Bearbeitungs-Buttons deaktiviert
6. Tap auf Banner → PaywallView öffnet sich
7. Produkte werden geladen (StoreKit Testing in Xcode)

- [ ] **Step 4: Push**

```bash
git push origin main
```

---

## Post-Implementation: App Store Connect

Diese Schritte müssen MANUELL in App Store Connect gemacht werden (nach Review-Approval):

1. **Products anlegen:** In-App Purchases → 3 Produkte erstellen mit den Product IDs
2. **Preise setzen:** €2,90 (Monthly), €19,90 (Yearly), €29,90 (Lifetime)
3. **Subscription Group:** "Premium" erstellen, Monthly + Yearly zuordnen
4. **Free Trial:** NICHT als App Store Introductory Offer (Trial ist lokal in der App)
5. **Review Screenshots:** Für jedes IAP-Produkt ein Screenshot der PaywallView

---

## Nicht im Scope (bewusst ausgeklammert)

- Keine App Store Introductory Offers (Trial ist lokal)
- Keine Promotional Offers
- Keine Family Sharing (kann später ergänzt werden)
- Keine Server-seitige Receipt-Validierung (für Solo-App nicht nötig)
- Keine Paywall-A/B-Tests
- LAUNCH-PLAN.md wird NICHT aktualisiert (separater Task)
