# CLAUDE.md — ai-presents-app-ios

## Projekt-Übersicht

iOS-App für Geburtstags- und Geschenkeverwaltung. Generiert von Open Claw (n8n/Telegram Bot), manuell gefixt und weiterentwickelt.

## Tech Stack

- **Swift 6.0**, SwiftUI, SwiftData (iOS 26+)
- **Architektur:** MVVM mit Services
- **Daten:** SwiftData + iCloud Sync (CloudKit)
- **KI:** OpenRouter API → Google Gemini 3.1 Flash Lite (Cloud, opt-in, DSGVO-konform)
- **Widget:** WidgetKit Birthday Widget (Medium + Large) mit Deep-Linking
- **Version:** 0.8.0 (Build 12)
- **Target:** iPhone 17 Pro Simulator / iOS 26+

## Build

```bash
xcodebuild -project ai-presents-app-ios.xcodeproj -scheme aiPresentsApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Projektstruktur

```
Sources/aiPresentsApp/
├── Models/          # SwiftData Models: PersonRef, GiftIdea, GiftHistory, ReminderRule, SuggestionFeedback
├── Services/        # CloudKitContainer, ContactsService, ReminderManager, AIService, AIConsentManager, SampleDataService, WidgetDataService
├── Utilities/       # AppLogger, AppConfig (inkl. AppConfig.AI), FormState, FormValidator, Accessibility, Debouncer, BirthdayCalculator, RelationOptions, GiftDirection
├── Views/
│   ├── Timeline/    # TimelineView (eine chronologische Liste), BirthdayRow (mit Status-Badge), BirthdayCountdownBadge
│   ├── Person/      # PersonDetailView (mit skipGift-Toggle, Hobbies, Received-Gifts), PersonAvatar, AllContactsView, ContactsImportView
│   ├── Gift/        # GiftIdeaRow, GiftHistoryRow, GiftSummaryView, Add/Edit Sheets
│   ├── AI/          # AIGiftSuggestionsSheet (bis 30 Vorschläge sammelbar), AIBirthdayMessageSheet, AIConsentSheet
│   ├── Settings/    # SettingsView (als Sheet via Gear-Icon), ReminderSettingsView, PrivacyView, LegalView, DevSettingsView
│   ├── Onboarding/  # OnboardingView
│   ├── Components/  # Wiederverwendbare UI-Komponenten: HobbiesChipView, RelationPickerView, FlowLayout, etc.
│   └── (Root)       # ContentView (kein TabView), ShareSheetView, LaunchScreen
├── ViewModels/      # AppViewModel, SuggestionQualityViewModel
├── Resources/       # AppColor
├── Widgets/         # BirthdayWidgetView (In-App Hero View)
└── aiPresentsApp.swift  # App Entry Point

Sources/BirthdayWidget/  # WidgetKit Extension (separates Target)
├── BirthdayWidget.swift           # Widget Entry Point + WidgetBundle
├── BirthdayTimelineProvider.swift # TimelineProvider (liest JSON aus App Group)
├── BirthdayWidgetViews.swift      # Views für Medium + Large
└── WidgetSharedTypes.swift        # WidgetBirthdayEntry + WidgetDataReader
```

## KI-Architektur (AIService + AIConsentManager)

**Cloud-basiert via OpenRouter** — erfordert explizite DSGVO-Einwilligung.

| Pfad | Voraussetzung | Daten |
|---|---|---|
| OpenRouter → Google Gemini | API-Key + Einwilligung | Vorname, Alter, Relation, Sternzeichen, Tags, Budget-Rahmen, Geschenktitel |
| Demo-Modus | immer (Fallback) | Vollständig offline, keine KI |

### AIService

```swift
// Verfügbarkeit
AIService.isAPIKeyConfigured  // true wenn API-Key in Info.plist vorhanden (nonisolated)
await AIService.isAvailable   // true wenn Key + Einwilligung (@MainActor)

// Aufrufe
let suggestions = try await AIService.shared.generateGiftIdeas(for: person, ...)
let message = try await AIService.shared.generateBirthdayMessage(for: person, ...)
```

### AIConsentManager

```swift
// DSGVO-Einwilligung verwalten
AIConsentManager.shared.consentGiven    // Bool
AIConsentManager.shared.aiEnabled      // Toggle (Boolean Binding möglich)
AIConsentManager.shared.canUseAI       // consentGiven && aiEnabled && isAPIKeyConfigured
AIConsentManager.shared.giveConsent()
AIConsentManager.shared.revokeConsent()
```

### AppConfig.AI

```swift
AppConfig.AI.openRouterAPIKey     // String aus Info.plist
AppConfig.AI.isAPIKeyConfigured   // Bool
AppConfig.AI.model                // "google/gemini-3.1-flash-lite-preview"
AppConfig.AI.openRouterBaseURL    // "https://openrouter.ai/api/v1/chat/completions"
```

## DSGVO — KI-Features

**Übertragene Daten:** Vorname, Alter (berechnet), Beziehungstyp, Sternzeichen, Hobbies/Interessen, Tags, Budget-Rahmen (Min/Max), Geschenktitel
**NICHT übertragen:** Geburtsdatum, Links, Notizen, Telefonnummer
**Rechtsgrundlage:** Art. 6 Abs. 1 lit. a DSGVO (Einwilligung)
**Auftragsverarbeiter:** OpenRouter Inc. (USA) → Google LLC (USA)
**Drittlandübermittlung:** Standardvertragsklauseln Art. 46 DSGVO
**Vollständige Doku:** `Docs/DSGVO-AI.md`

## Secrets / API-Key

```bash
# App/Secrets.xcconfig (in .gitignore, NICHT committen)
OPENROUTER_API_KEY = sk-or-v1-...

# Template: App/Secrets.xcconfig.example
```

Der Key wird via `project.yml` → `OpenRouterAPIKey` in Info.plist geschrieben und per `Bundle.main.infoDictionary` ausgelesen.

## Wichtige Patterns & Konventionen

### SwiftData Models
- `PersonRef` erwartet `contactIdentifier:` als required Parameter
- `PersonRef.skipGift: Bool = false` — "Kein Geschenk nötig" pro Person
- `PersonRef.hobbies: [String] = []` — dauerhafte Interessen pro Person (max. 10, fließt in KI-Prompt ein)
- `PersonRef.relation: String` — Beziehungstyp (wählbar aus 8 Optionen + Sonstige-Freitext)
- `PersonRef.birthYearKnown: Bool = true` — false wenn Geburtsjahr bei Kontakt-Import unbekannt war; KI-Prompt lässt dann Alter weg
- `GiftIdea` Init-Reihenfolge: `status` VOR `tags`
- `GiftStatus` ist `CaseIterable` + `Codable`
- `GiftHistory.direction: String = "given"` — Richtung: "given" (verschenkt) oder "received" (erhalten); SwiftData speichert als String für Migration
- `GiftDirection` enum: `.given`/`.received`, ist `Sendable` + `Codable` + `CaseIterable` (Utilities, nicht Models)
- `RelationOptions.predefined` — 8 vordefinierte Beziehungstypen + "Sonstige": Partner/in, Mutter, Vater, Schwester, Bruder, Freund/in, Kollege/in, Kind

### ModelConfiguration
- Positional String statt `identifier:` Label: `ModelConfiguration("name", ...)`
- Für CloudKit-disabled: `cloudKitDatabase: .none` (nicht `nil`)

### SwiftUI Views
- Computed properties: **`some View`** (nie bare `View`)
- Funktions-Returns: **`-> some View`** (nie `-> View`)
- `Section("title") { } footer: { }` ist UNGÜLTIG — verwende: `Section { } header: { Text("title") } footer: { }`
- `Section("title") { }` ohne footer/header ist OK
- `.symbolEffect`: Verschiedene Effect-Typen können nicht in Ternary gemischt werden → `.symbolEffect(.bounce, isActive: condition)`
- Alert `message:` Closures müssen IMMER einen View liefern — Logic in computed property auslagern
- `.sheet()` Modifier NICHT an Sub-Views in List/Section anhängen → SwiftUI dismisst sofort bei Re-Render. Immer auf Top-Level `body` hängen.

### Swift 6 Concurrency
- Tasks, die SwiftData-Models senden: `let p = person` lokale Kopie vor Task, dann `Task { @MainActor in ... }`
- `ContactsService` ist `@MainActor` — `fetchContactData()` ist `nonisolated` für Background-Kontakt-Enumeration
- `BirthdayCalculator.cache` braucht `nonisolated(unsafe)` (mutable static state)
- `ReminderManager` ist `@MainActor` — lock Properties brauchen `nonisolated(unsafe)`
- `AIConsentManager` ist `@MainActor` — `AIService.isAvailable` ist daher `@MainActor`

### AppLogger Kategorien
```swift
AppLogger.ui.debug("...")
AppLogger.data.info("...")
AppLogger.forms.error("...", error: error)
AppLogger.reminder.warning("...")
AppLogger.notifications.info("...")
```

### Löschen aller Daten (kein `deleteContainer()`)
```swift
try context.delete(model: SuggestionFeedback.self)
try context.delete(model: ReminderRule.self)
try context.delete(model: GiftHistory.self)
try context.delete(model: GiftIdea.self)
try context.delete(model: PersonRef.self)
```

### FormState Naming
- `FormState` in `FormState.swift` = ObservableObject-Version (für FormField, FormSubmitButton)
- `AppFormState` in `FormValidator.swift` = @Observable-Version (für Sheet-Views)

### UI-Komponenten & Patterns
- **HobbiesChipView:** FlowLayout mit Chips (wie Erinnerungen-Tags). Return-Taste → neuer Chip, ✕-Tap → löschen. Max. 10.
- **RelationPickerView:** Standard Picker (Menu oder Wheel) mit 8 Optionen + "Sonstige"-Freitext. Bestehende Werte außerhalb der Liste → unter "Sonstige" angezeigt.
- **FlowLayout:** Custom Layout für Chip-Anordnung (wrapping, centered, spacing). Wird für Hobbies, Tags und GiftIdea-Chips verwendet.
- **GiftHistoryDirectionSegmented:** Segmented Control ("Verschenkt" / "Erhalten") — bestimmt `GiftHistory.direction`.

## UI-Architektur

- **Kein TabView** — nur ein Screen (TimelineView) mit Settings als Sheet (Gear-Icon links oben)
- **TimelineView:** Stats-Leiste → Suchfeld → chronologische Liste ALLER Geburtstage
- **BirthdayRow:** Avatar, Name, Countdown, Geschenk-Status-Badge (skipGift/gekauft/geplant/Ideen)
- **Swipe-Actions:** Links-Swipe auf BirthdayRow → "Kein Geschenk" Toggle
- **PersonDetailView:** Name + Avatar oben → Relation Picker → Hobbies-Section → skipGift-Toggle → Gift-Ideen-Section → "In früheren Jahren verschenkt"-Section → "Von mir erhalten"-Section → "Aus App entfernen"-Button (mit Confirmation Alert)
- **GiftHistory Add/Edit Sheet:** Oben Segmented Control ("Verschenkt" / "Erhalten") — bestimmt direction. Felder: Titel (Pflicht), Jahr (Pflicht), Kategorie, Wert, Notiz. Link-Feld nur bei "Verschenkt".
- **AIGiftSuggestionsSheet:** "5 weitere generieren" Button, Akkumulation bis max. 30 Vorschläge. KI nutzt Hobbies + Tags im Prompt.

## Widget-Architektur

**Daten-Sharing:** JSON-Snapshot via App Group UserDefaults (kein SwiftData im Widget)
- **App Group:** `group.com.harryhirsch1878.ai-presents-app`
- **URL-Scheme:** `aipresents://person/{UUID}` für Deep-Linking
- **WidgetDataService** schreibt Snapshot bei: App-Start, Hintergrund-Wechsel, Pull-to-Refresh
- **Timeline-Refresh:** Täglich um Mitternacht + App-getriggert via `WidgetCenter.shared.reloadAllTimelines()`
- **Supported Families:** `.systemMedium` (3 Einträge), `.systemLarge` (7 Einträge)
- Shared Types sind im Widget dupliziert (~30 Zeilen), da Widget-Extensions keinen Zugriff auf das App-Target haben

## Design-Prinzip

Wir orientieren uns immer an Apple HIG (Human Interface Guidelines) — natives Design, Standard-Patterns, SF Symbols, System-Farben.

## Subscription-System (StoreKit 2)

**Architektur:** `SubscriptionManager` (@MainActor, ObservableObject) als zentraler Service.

### Product-IDs (App Store Connect)
```
Subscription Group: "AI Presents Premium"
├── com.harryhirsch1878.aipresents.premium.monthly  (4,99 EUR)
└── com.harryhirsch1878.aipresents.premium.yearly   (29,99 EUR, 14-Tage Free Trial)
```

### SubscriptionManager

```swift
// Verfügbarkeit prüfen
subscriptionManager.isPremium                    // Bool — aktives Abo?
subscriptionManager.canAddPerson(currentCount:)  // Bool — Personen-Limit prüfen
subscriptionManager.activeProduct                // Product? — aktives Abo-Produkt

// Kauf
await subscriptionManager.purchase(product)      // Bool — Kauf erfolgreich?
await subscriptionManager.restorePurchases()     // Käufe wiederherstellen
await subscriptionManager.loadProducts()         // Produkte neu laden

// Konstanten
SubscriptionManager.freePersonLimit              // 5 Personen im Free-Tier
SubscriptionProduct.allIDs                       // Set<String> aller Product-IDs
SubscriptionProduct.groupID                      // "premium"
```

### Integration via EnvironmentObject
```swift
// App-Root: aiPresentsApp.swift
@StateObject private var subscriptionManager = SubscriptionManager()
// .environmentObject(subscriptionManager)

// In Views:
@EnvironmentObject private var subscriptionManager: SubscriptionManager
```

### Premium-Gating

| Feature | Free | Premium |
|---------|------|---------|
| Personen | 5 max | Unbegrenzt |
| KI-Geschenkvorschläge | Demo | Unbegrenzt |
| KI-Geburtstagsnachricht | - | Ja |
| Widget | - | Ja |
| Custom Reminders | 1 | Unbegrenzt |
| Cloud Sync (iCloud) | Ja | Ja |

### Views

| View | Datei | Zweck |
|------|-------|-------|
| `PaywallView` | `Views/Subscription/PaywallView.swift` | Paywall mit Features, Preisvergleich, Kauf |
| `PremiumBadge` | `Views/Subscription/PremiumBadge.swift` | Kompaktes Premium/Free-Badge |
| `.paywallSheet(isPresented:)` | Extension auf `View` | Convenience-Modifier für Paywall |
| `.premiumRequired(action:)` | Extension auf `View` | Lock-Icon + Paywall-Trigger |

### Gating-Punkte

- **ContactsImportView:** Import begrenzt auf `freePersonLimit` Personen
- **PersonDetailView:** `handleAIButtonTap()` prüft `isPremium` vor KI-Features
- **SettingsView:** Abo-Section mit Status, Upgrade-Button, Restore

### StoreKit Testing (Xcode)

1. StoreKit Configuration File `App/Products.storekit` in Xcode erstellen
2. Produkte anlegen (Monthly + Yearly, gleiche Subscription Group)
3. Scheme → StoreKit Configuration → `Products.storekit` auswählen
4. Im Simulator: Käufe testen, Renewals simulieren

## App-Start Fehlerbehandlung

- **CloudKit-Fehler:** Automatischer Fallback auf lokalen Store (ohne iCloud Sync)
- **Lokaler Store-Fehler:** In-Memory-Fallback + `ContentUnavailableView` (kein Crash, aber Daten gehen verloren)
- Alle Container-Fehler werden via `AppLogger.data.error()` geloggt

## Bekannte Einschränkungen

- OpenRouter API-Key muss manuell in `App/Secrets.xcconfig` eingetragen werden
- Ohne Key: Demo-Modus (vollständig offline)
- App wurde initial von KI generiert — Code-Qualität variiert

## Launch-Plan

Vollständiger Launch-Plan mit 8 Phasen, Skills-Referenz und Revenue-Prognose: **`Docs/LAUNCH-PLAN.md`**

## GitHub

- Repo: `harryhirsch1878/ai-presents-app-ios`
- Branch: `main`
