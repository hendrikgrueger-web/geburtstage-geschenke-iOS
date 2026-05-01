# Swift-Patterns & Konventionen — ai-presents-app-ios

## SwiftData Models

- `PersonRef` erwartet `contactIdentifier:` als required Parameter
- `PersonRef.skipGift: Bool = false` — "Kein Geschenk nötig" pro Person
- `PersonRef.hobbies: [String] = []` — max. 10, fließt in KI-Prompt ein
- `PersonRef.relation: String` — 8 vordefinierte Optionen + custom + "Sonstige"-Fallback
- `PersonRef.birthYearKnown: Bool = true` — false wenn Geburtsjahr unbekannt; KI lässt Alter dann weg
- `GiftIdea` Init-Reihenfolge: `status` VOR `tags`
- `GiftStatus` ist `CaseIterable` + `Codable`
- `GiftHistory.direction: String = "given"` — "given" oder "received"; String für Migration
- `GiftDirection` enum: `.given`/`.received`, ist `Sendable` + `Codable` + `CaseIterable`
- `ModelConfiguration` positional: `ModelConfiguration("name", ...)` (kein `identifier:` Label)
- CloudKit-disabled: `cloudKitDatabase: .none` (nicht `nil`)

### RelationOptions (enum)

- `RelationOptions.predefined` — 8 vordefinierte + "Sonstige": Partner/in, Mutter, Vater, Schwester, Bruder, Freund/in, Kollege/in, Kind
- `RelationOptions.custom` — UserDefaults key: `"customRelationTypes"`
- `RelationOptions.all` — `predefined.filter { != "Sonstige" } + custom + ["Sonstige"]`
- `RelationOptions.addCustom(_:)` — dedupliziert + getrimmt
- `RelationOptions.removeCustom(_:)` — entfernt; wenn selektiert → Fallback auf "Sonstige"
- `RelationOptions.localizedDisplayName(for:)` — lokalisiert vordefinierte, custom unverändert

### Löschen aller Daten (kein `deleteContainer()`)

```swift
try context.delete(model: SuggestionFeedback.self)
try context.delete(model: ReminderRule.self)
try context.delete(model: GiftHistory.self)
try context.delete(model: GiftIdea.self)
try context.delete(model: PersonRef.self)
```

## SwiftUI Views

- Computed properties: **`some View`** (nie bare `View`)
- Funktions-Returns: **`-> some View`** (nie `-> View`)
- `Section("title") { } footer: { }` UNGÜLTIG → `Section { } header: { Text("title") } footer: { }`
- `.symbolEffect`: Verschiedene Typen nicht in Ternary mischen → `.symbolEffect(.bounce, isActive: condition)`
- Alert `message:` Closures IMMER einen View liefern — Logic in computed property auslagern
- `.sheet()` NICHT an Sub-Views in List/Section → immer auf Top-Level `body`

## iOS 26 Design-Compliance (Pflicht)

- `.foregroundStyle()` statt `.foregroundColor()` (deprecated seit iOS 17)
- `.clipShape(.rect(cornerRadius:))` statt `.cornerRadius()` (deprecated seit iOS 17)
- AppColor-Tokens: `AppColor.accent` statt `.orange`, `AppColor.danger` statt `.red`, `AppColor.success` statt `.green`
- Widget-Target: `UIColor.systemXxx` und `Color.accentColor` (kein AppColor-Zugriff im Widget)
- **Liquid Glass:** `GlassEffectContainer`, `.glassEffect()` für iOS 26+
- **SF Symbols 7:** Immer neueste Varianten verwenden
- **Semantic Colors:** `.primary`, `.secondary`, `.tertiary`, `.placeholder`

## Swift 6 Concurrency

- Tasks mit SwiftData-Models: `let p = person` lokale Kopie vor Task, dann `Task { @MainActor in ... }`
- `ContactsService` ist `@MainActor` — `fetchContactData()` ist `nonisolated` für Background
- `BirthdayCalculator.cache` braucht `nonisolated(unsafe)` (mutable static state)
- `ReminderManager` ist `@MainActor` — via `.environmentObject()` von App-Root, NIE neue Instanz in Views
- `AIConsentManager` ist `@MainActor` — `AIService.isAvailable` ist daher `@MainActor`

## iPad-Patterns

- **NavigationSplitView** in ContentView — `selectedPerson: PersonRef?` als `@State` in ContentView, `@Binding` in TimelineView
- **Kein `.navigationDestination`** — Detail direkt in der detail-Spalte
- **UIActivityViewController iPad-Fix:** `popoverPresentationController.sourceView/sourceRect` MUSS gesetzt werden (sonst Crash)
- **ShareSheetView:** `popoverPresentationController.permittedArrowDirections = .any`
- **Sheet-Detents:** `.presentationDetents([.medium, .large])` auf allen Add/Edit-Sheets
- **Hover-Effekte:** `.hoverEffect(.highlight)` auf Rows; `.hoverEffect(.lift)` auf SmartSearchBar
- **Keyboard Shortcuts:** Cmd+, (Settings), Cmd+N (Kontakte), Cmd+I (Neue Idee), Cmd+F (AI-Chat)
- **UIRequiresFullScreen: false** — erlaubt Split View + Slide Over

## XcodeGen configFiles Pattern

- `configFiles` **MUSS auf Target-Ebene stehen** (Geschwister von `settings:`, nicht Kind)
- Falsch: `settings: { configFiles: { ... } }`
- Richtig: Target-Definition mit `settings: { ... }` UND `configFiles: { ... }` nebeneinander
- Sonst: `Secrets.xcconfig` nicht eingebunden → `AI_PROXY_SECRET` leer

## FormState Naming

- `FormState` in `FormState.swift` = ObservableObject-Version (für FormField, FormSubmitButton)
- `AppFormState` in `FormValidator.swift` = @Observable-Version (für Sheet-Views)

## AppLogger Kategorien

```swift
AppLogger.ui.debug("...")
AppLogger.data.info("...")
AppLogger.forms.error("...", error: error)
AppLogger.reminder.warning("...")
AppLogger.notifications.info("...")
```

## Lokalisierung (i18n)

**Sprachen:** Deutsch (Development Language) + Englisch
**Technik:** Swift String Catalogs (.xcstrings)

**Pflicht-Regeln:**
1. Alle neuen Strings MÜSSEN zweisprachig sein (DE + EN)
2. Niemals `Locale(identifier: "de_DE")` hardcoden → immer `Locale.current`
3. SwiftUI `Text("...")` → automatisch `LocalizedStringKey`, kein Wrapping nötig
4. Programmatische Strings → `String(localized: "Deutscher Text")`
5. KI-Prompts → `String(localized: "...", table: "AIContent")`
6. Enum Display-Werte: `localizedName` computed property nutzen, NICHT `rawValue`

**String Catalog Dateien:**

| Datei | Zweck | Target |
|-------|-------|--------|
| `Sources/aiPresentsApp/Localizable.xcstrings` | UI-Strings | aiPresentsApp |
| `Sources/aiPresentsApp/AIContent.xcstrings` | KI-Prompts | aiPresentsApp |
| `App/InfoPlist.xcstrings` | Usage Descriptions | aiPresentsApp |
| `Sources/BirthdayWidget/Localizable.xcstrings` | Widget UI-Strings | BirthdayWidgetExtension |
| `Sources/BirthdayWidget/InfoPlist.xcstrings` | Widget Display Name | BirthdayWidgetExtension |

**Bekannte Einschränkung:** RelationOptions-Werte sind deutsch in der DB gespeichert — Display-Layer lokalisiert Vordefinierte via `localizedDisplayName()`, custom-Typen as-is.

**Enum-Pattern:**
```swift
enum GiftDirection {
    case given, received
    var localizedName: String {
        switch self {
        case .given: String(localized: "Verschenkt")
        case .received: String(localized: "Erhalten")
        }
    }
}
```

## AIService API

```swift
// Verfügbarkeit
AIService.isAPIKeyConfigured  // nonisolated
await AIService.isAvailable   // @MainActor

// Aufrufe
let suggestions = try await AIService.shared.generateGiftIdeas(for: person, ...)
let message = try await AIService.shared.generateBirthdayMessage(for: person, ...)

// AIConsentManager
AIConsentManager.shared.consentGiven
AIConsentManager.shared.aiEnabled
AIConsentManager.shared.canUseAI  // consentGiven && aiEnabled && isAPIKeyConfigured
AIConsentManager.shared.giveConsent()
AIConsentManager.shared.revokeConsent()

// AppConfig.AI
AppConfig.AI.proxySecret        // aus Info.plist (AIProxySecret)
AppConfig.AI.isAPIKeyConfigured
AppConfig.AI.model              // "google/gemini-3.1-flash-lite-preview"
AppConfig.AI.openRouterBaseURL  // https://ai-presents-proxy.hendrikgrueger.workers.dev
```
