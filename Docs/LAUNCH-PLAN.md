# Launch-Plan — ai Presents (iOS)

> Erstellt: 2026-03-04 | Status: In Vorbereitung

---

## Zusammenfassung

ai Presents ist eine iOS-App für Geburtstags- und Geschenkeverwaltung mit KI-gestützten Geschenkvorschlägen. Ziel: App Store Launch bis **September/Oktober 2026** (vor der Weihnachts-Geschenke-Saison).

---

## Phase 1: Code-Qualität & Bug-Fixes (Woche 1-2)

### Erledigt (2026-03-04)

- [x] **WARN-6:** "Apple Intelligence"-Falschaussage aus UI entfernt → jetzt korrekt "Cloud-KI via OpenRouter"
- [x] **CRIT-3:** `fatalError` durch In-Memory-Fallback + `ContentUnavailableView` ersetzt
- [x] **WARN-2:** `PersonRef.birthYearKnown` Property — Alter wird nur bei bekanntem Geburtsjahr im KI-Prompt verwendet
- [x] **WARN-10:** Kontakt-Import von Main Thread in `nonisolated` Background-Methode verschoben
- [x] **INFO-3:** Zodiac-Emoji-Bug (`"♈ Widder"` → `personalityHint` matchte nie) behoben mit `normalizedZodiac()`

### Noch offen

| # | Priorität | Aufgabe | Skill |
|---|-----------|---------|-------|
| 1 | High | `CloudKitContainer` dead code entfernen oder korrekt anbinden | — |
| 2 | High | `BirthdayCalculator` und `BirthdayDateHelper` zu einer Klasse konsolidieren | — |
| 3 | Medium | `ReminderManager` Doppel-Instanz in SettingsView fixen | — |
| 4 | Medium | `PersonDetailView` aufteilen (1041 Zeilen → Extracted Sub-Views) | `/ui-review` |
| 5 | Medium | `TimelineView` doppelte `@State`-Variable (`showingAddGiftIdeaFor`/`quickAddPerson`) vereinen | — |
| 6 | Medium | `GiftTransitionService` Schaltjahr-Bug (29.02. wird übersprungen) fixen | — |
| 7 | Low | `AppConfig.currentEnvironment` dead code entfernen | — |
| 8 | Low | `SettingsView.birthdayText` redundanter Branch entfernen | — |
| 9 | Low | Widget-Update bei PersonDetailView-Edits triggern | — |

---

## Phase 2: Monetarisierung mit StoreKit 2 (Woche 2-4) — IMPLEMENTIERT

### Strategie: Freemium + Subscription

| Tier | Features | Preis |
|------|----------|-------|
| **Free** | 5 Personen, manuelle Geschenkideen, Basic Timeline | Kostenlos |
| **Premium Monatlich** | Unbegrenzt Personen, KI-Vorschläge, Cloud Sync, Widget, Custom Reminders | €4,99/Monat |
| **Premium Jährlich** | Alles von Monatlich | €29,99/Jahr (50% Rabatt) |
| **Free Trial** | 14 Tage volles Premium | — |

### Warum nicht 6 Monate kostenlos?

- Apple **erlaubt** bis zu 1 Jahr Free Trial — technisch möglich
- **Nicht empfohlen:** Conversion-Fenster sind Tag 1-7 und Tag 30+ — dazwischen passiert wenig
- Nach 6 Monaten haben Nutzer die App vergessen
- 14-30 Tage = Sweet Spot für Habit-Formation

### Warum nicht Amazon Affiliate Links?

- Apple erlaubt externe Links **nur eingeschränkt** (außerhalb USA fast verboten)
- 3-5% Provision = minimaler Revenue
- App Store Review-Risiko (Guideline 3.1.1)
- **Alternative:** Web-Version mit Affiliate-Links, In-App nur als Safari-Redirect

### Implementation — Erledigt (2026-03-04)

| Aufgabe | Status | Datei(en) |
|---------|--------|-----------|
| SubscriptionManager Service | Done | `Services/SubscriptionManager.swift` |
| PaywallView (Features, Preise, Kauf) | Done | `Views/Subscription/PaywallView.swift` |
| PremiumBadge + premiumRequired-Modifier | Done | `Views/Subscription/PremiumBadge.swift` |
| Free-Tier-Limit (5 Personen) | Done | `ContactsImportView.swift` |
| KI-Features Premium-Gate | Done | `PersonDetailView.swift` |
| Abo-Section in Settings | Done | `SettingsView.swift` |
| Restore Purchases | Done | `SubscriptionManager.swift` + `SettingsView.swift` |
| Transaction.updates Listener | Done | `SubscriptionManager.swift` |
| EnvironmentObject-Integration | Done | `aiPresentsApp.swift` |
| Entitlements (StoreKit Config) | Done | `App/aiPresentsApp.entitlements` |

### Noch offen (Phase 2)

| Aufgabe | Skill | Details |
|---------|-------|---------|
| StoreKit Configuration File in Xcode erstellen | — | Produkte lokal zum Testen definieren |
| App Store Connect: Products anlegen | — | Product IDs, Preise, Free Trial konfigurieren |
| App Store Server Notifications | `/monetization` | Server-to-Server Updates (optional) |

### Apple Small Business Program

- **15% statt 30%** Provision bei <$1M/Jahr Umsatz
- Anmeldung: [developer.apple.com/programs/small-business](https://developer.apple.com/programs/small-business)

---

## Phase 3: Lokalisierung (Woche 3-4)

### Sprach-Strategie: Gestaffelter Launch

| Phase | Sprachen | Begründung |
|-------|----------|------------|
| **Launch** | DE + EN | Heimatmarkt + größtes iOS-Publikum |
| **+2-3 Wochen** | ES | Zweitgrößte Sprache, +73% Impressions |
| **Optional** | FR, IT, PT-BR | Nur bei Traction |

### Implementation

| Aufgabe | Skill | Details |
|---------|-------|---------|
| String Catalogs einrichten | `/localization-setup` | Xcode String Catalogs (`.xcstrings`) |
| UI-Strings extrahieren | `/localization-setup` | Alle hardcodierten Strings → `LocalizedStringKey` |
| EN-Übersetzung | — | KI-Translation + Native Review |
| ES-Übersetzung | — | KI-Translation + Native Review |
| App Store Metadaten lokalisieren | `/app-description-writer` | Titel, Subtitle, Beschreibung, Keywords |
| Layout-Test DE vs EN | `/snapshot-test-setup` | Deutsche Texte ~30% länger |

### Wichtig

- Deutsche Texte sind **~30% länger** als Englisch → SwiftUI-Layout muss flexibel sein
- `DateFormatter.locale` bereits korrekt gesetzt (`de_DE`)
- Zodiac-Zeichen bleiben als Unicode-Symbole (sprachunabhängig)

---

## Phase 4: Testing & Qualität (Woche 4-5)

| Aufgabe | Skill | Details |
|---------|-------|---------|
| Unit-Tests für `BirthdayDateHelper` | `/tdd-feature` | Schaltjahr, Grenzfälle, Altersberechnung |
| Unit-Tests für `AIService` | `/tdd-feature` | Prompt-Generierung, Demo-Fallback, Error-Handling |
| Snapshot-Tests für Hauptviews | `/snapshot-test-setup` | Timeline, PersonDetail, AIGiftSuggestions |
| Integration-Test: Kontakt-Import | `/integration-test-scaffold` | Mock `CNContactStore` |
| Performance-Profiling | `/profiling` | Launch-Time, Memory-Leaks, UI-Freeze |
| SwiftUI Debug | `/swiftui-debugging` | View-Re-Renders, Body-Evaluations |
| Accessibility-Audit | `/ui-review` | VoiceOver, Dynamic Type, Kontraste |
| Security-Review | `/security` | API-Key-Handling, Keychain, Privacy Manifest |
| Privacy Manifest erstellen | `/privacy-manifests` | iOS 17+ Pflicht für App Store |

---

## Phase 5: App Store Vorbereitung (Woche 5-6)

### App Store Listing

| Element | Inhalt | Skill |
|---------|--------|-------|
| **App Name** (30 Zeichen) | ai Presents | — |
| **Subtitle** (30 Zeichen) | Geschenke & Geburtstage planen | `/keyword-optimizer` |
| **Keywords** (100 Zeichen) | birthday reminder,gift planner,gift idea,geschenk planer,geburtstag | `/keyword-optimizer` |
| **Beschreibung** | Emotional → Features → CTA | `/app-description-writer` |
| **What's New** | Release Notes für v1.0 | `/app-description-writer` |
| **Screenshots** | 5-6 pro Gerätegröße | `/screenshot-planner` |
| **App Preview Video** | 30s — Timeline → KI → Reminder → Widget | `/screenshot-planner` |
| **App Icon** | Aktuelles Icon prüfen/optimieren | — |
| **Privacy Policy URL** | DSGVO-konforme Datenschutzerklärung | `/privacy-policy` |

### Pre-Submission Checklist

| Aufgabe | Skill |
|---------|-------|
| App Review Guidelines Compliance-Check | `/rejection-handler` |
| Privacy Manifest validieren | `/privacy-manifests` |
| App Store Connect Setup | — |
| Subscription Products anlegen | — |
| In-App Purchase Review Screenshot | — |
| Testflight-Build hochladen | — |
| Export Compliance (Encryption) | — |
| Content Rating (Age Rating) | — |

---

## Phase 6: TestFlight Beta (Woche 6-7)

| Aufgabe | Skill | Details |
|---------|-------|---------|
| Beta-Strategie planen | `/beta-testing` | Tester-Rekrutierung, Feedback-Kanäle |
| Interne Tester (max. 25) | — | Team, Freunde, Familie |
| Externe Tester (max. 10.000) | — | Beta-Link verbreiten |
| Feedback-Formular einrichten | — | In-App oder TestFlight-Feedback |
| Crash-Monitoring | `/error-monitoring` | Crashlytics oder Sentry |
| Analytics einrichten | `/analytics-setup` | Event-Tracking (KI-Nutzung, Conversions) |
| 2-3 Beta-Iterationen | — | Feedback einarbeiten, Bugs fixen |

---

## Phase 7: Launch & Marketing (Woche 7-8)

### Launch-Timing

**Empfehlung: September/Oktober 2026** (vor Weihnachts-Geschenke-Saison)

### Marketing-Strategie

| Kanal | Aufgabe | Skill |
|-------|---------|-------|
| App Store | ASO optimieren, Screenshots, Preview Video | `/marketing-strategy` |
| App Store Featuring | Nomination einreichen | `/featuring-nomination` |
| Apple Search Ads | Kampagnen-Setup, Budget €50-100/Monat Start | `/apple-search-ads` |
| Product Hunt | Launch-Post vorbereiten | — |
| Reddit | r/iOS, r/productivity, r/gifts Posts | — |
| Social Media | Instagram/TikTok: App-Demo-Videos | — |
| Presse | Deutsche Tech-Blogs kontaktieren | — |
| Review-Prompt | In-App nach 3. KI-Vorschlag | `/review-prompt` |

### App Store In-App Events

| Event | Zeitraum | Skill |
|-------|----------|-------|
| "Weihnachtsgeschenke planen" | November-Dezember | `/in-app-events` |
| "Valentinstag-Ideen" | Januar-Februar | `/in-app-events` |
| "Muttertag-Special" | April-Mai | `/in-app-events` |

---

## Phase 8: Post-Launch & Growth (laufend)

| Aufgabe | Skill | Details |
|---------|-------|---------|
| Analytics auswerten | `/analytics-interpretation` | Retention, Conversion, Feature-Nutzung |
| A/B-Tests Paywall | `/feature-flags` | Verschiedene Trial-Längen testen |
| Review-Monitoring | `/review-response-writer` | Auf App Store Reviews reagieren |
| Feature-Erweiterungen | `/prd-generator` | Basierend auf Feedback |
| Siri/Shortcuts Integration | `/app-intents` | "Hey Siri, wer hat diese Woche Geburtstag?" |
| Live Activities | `/live-activity-generator` | Countdown zum nächsten Geburtstag |
| Competitive Analysis | `/competitive-analysis` | Wettbewerber beobachten |

---

## Revenue-Prognose (konservativ)

| Szenario | Downloads/Monat | Conversion | MRR | ARR |
|----------|----------------|------------|-----|-----|
| **Start (Monat 1-3)** | 500 | 3% | €75 | €900 |
| **Wachstum (Monat 4-6)** | 1.000 | 5% | €250 | €3.000 |
| **Etabliert (Monat 7-12)** | 2.000 | 7% | €700 | €8.400 |
| **Optimistisch (Jahr 2)** | 5.000 | 8% | €2.000 | €24.000 |

*Annahme: €4,99/Monat, 15% Apple-Provision (Small Business Program), 40% Jahresabo-Anteil*

---

## Wichtige Ressourcen

| Ressource | URL/Pfad |
|-----------|----------|
| App Store Review Guidelines | developer.apple.com/app-store/review/guidelines/ |
| StoreKit 2 Dokumentation | developer.apple.com/documentation/storekit |
| App Store Connect | appstoreconnect.apple.com |
| Small Business Program | developer.apple.com/programs/small-business |
| Apple Search Ads | searchads.apple.com |
| Privacy Manifest | developer.apple.com/documentation/bundleresources/privacy_manifest_files |
| DSGVO-Doku (intern) | `Docs/DSGVO-AI.md` |
| Apple Platform Skills | `.claude/skills/` (148 Skills, 23 Kategorien) |

---

## Skills-Referenz für jede Phase

```
Phase 1 (Code):     /ui-review, /coding-best-practices, /concurrency-patterns
Phase 2 (Monetize):  /monetization, /paywall-generator, /settings-screen
Phase 3 (L10n):      /localization-setup, /app-description-writer
Phase 4 (Testing):   /tdd-feature, /snapshot-test-setup, /profiling, /security
Phase 5 (ASO):       /keyword-optimizer, /screenshot-planner, /rejection-handler, /privacy-manifests
Phase 6 (Beta):      /beta-testing, /error-monitoring, /analytics-setup
Phase 7 (Launch):    /marketing-strategy, /featuring-nomination, /apple-search-ads, /in-app-events
Phase 8 (Growth):    /analytics-interpretation, /app-intents, /live-activity-generator, /competitive-analysis
```
