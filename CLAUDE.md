# CLAUDE.md — ai-presents-app-ios

## Projekt-Übersicht

iOS-App für Geburtstags- und Geschenkeverwaltung mit KI-Geschenkvorschlägen.
Repo: `hendrikgrueger-web/geburtstage-geschenke-iOS` | Branch: `main`

## PFLICHT: Skills vor jeder Aktion

Passenden Skill aufrufen — **kein Code ohne Skill-Check**.
Checkliste in `Apple Apps/CLAUDE.md` → "PFLICHT: Skills vor jeder Aktion prüfen".

## Tech Stack

- **Swift 6.0**, SwiftUI, SwiftData, MVVM, iCloud Sync (CloudKit)
- **KI:** OpenRouter → Google Gemini 3.1 Flash Lite (opt-in, DSGVO-konform, anonymisiert)
- **Widget:** WidgetKit (Medium + Large) mit Deep-Linking
- **Aktueller Build:** v1.0.7 (169) APPROVED 2026-05-02 (Submission `f21d073c-c47e-4be6-ac43-a1ac8d40549f`) · v1.0.6 (160) APPROVED 2026-05-01 (Submission `70920239-e2b1-4bc4-9d98-edc0c9edb866`)
- **Min:** iOS 26+ | iPhone + iPad
- **iPad:** NavigationSplitView, alle 4 Orientierungen
- **Tests:** 1294 Tests (Stand 2026-05-01), 0 Failures — extreme Coverage Pflicht (Memory: `feedback_extreme_testing.md`)

## Build

```bash
# iPhone
xcodebuild -project ai-presents-app-ios.xcodeproj -scheme aiPresentsApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
# iPad
xcodebuild -project ai-presents-app-ios.xcodeproj -scheme aiPresentsApp \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' build
```

## Identifier & Team

| Was | Wert |
|-----|------|
| App Bundle ID | `com.hendrikgrueger.birthdays-presents-ai` |
| Widget Bundle ID | `com.hendrikgrueger.birthdays-presents-ai.widget` |
| App Group | `group.com.hendrikgrueger.birthdays-presents-ai` |
| ASC App-ID | `6760319397` |
| Team | Grüpi GmbH `CU87QNNB3N` |
| App Store URL | https://apps.apple.com/us/app/birthday-calendar-gifts/id6760319397|

## App Store Status

- **Version 1.0.7:** APPROVED 2026-05-02 (Build 169) — Release pending publication
- **Version 1.0.6:** APPROVED 2026-05-01 (Build 160) — Release pending publication
- **Version 1.0.3:** READY_FOR_SALE seit 2026-04-04 (Submission `e58abf8f-…`)
- **Version 1.0:** READY_FOR_SALE — live seit 2026-03-24
- **Offen (MANUELL in ASC-Browser):**
  1. Subscriptions "Premium Jährlich" + "Premium Monatlich" → Review einreichen
  2. Lifetime IAP Metadata vervollständigen + einreichen
  3. Terms of Use Link → erst für Version 1.1

### Lessons Learned aus Mai-Releases (1.0.5 → 1.0.7)

- **2026-05-01 13:41/13:54:** Builds 154 + 155 (Version 1.0.5) verworfen mit `ITMS-90186` (Train 1.0.5 closed) + `ITMS-90062` (CFBundleShortVersionString muss höher sein als bereits approved 1.0.5). Ursache: Version-String wurde nicht hochgezählt, nachdem 1.0.5 bereits approved war.
- **Regel:** Vor jedem Push auf `main` prüfen, ob die **letzte approved Version** auf ASC schon dem `CFBundleShortVersionString` in `project.yml` entspricht — wenn ja: Version vorher hochzählen. Build-Number-Pflicht ist in `MEMORY/feedback_build-number-increment.md` dokumentiert; Version-String-Pflicht hier ergänzen.
- Nach den Failures war die Build-Sequenz 157 → 159 → 160 (1.0.6, approved) → 161 → 162 → 163 → 166 → 167 → 169 (1.0.7, approved).

## Xcode Cloud (CI/CD)

| Workflow | ID | Trigger | Distribution |
|----------|----|---------|--------------|
| Deploy to Testflight V2 | `FAF5B5BC-AC5C-45CC-AE14-F82C1136A295` | Push `main` | `INTERNAL_ONLY` |
| App Store Build | `27f2efdf-ce6e-4c74-846f-3eb002c39ef5` | Manuell | `APP_STORE_ELIGIBLE` |

**WICHTIG:** Nur "App Store Build" kann an App Store Versionen angehängt werden — "Deploy to Testflight V2" erstellt `INTERNAL_ONLY` Builds.

```bash
# TestFlight: git push origin main → automatisch
# App Store Build manuell:
asc xcode-cloud run --workflow-id 27f2efdf-ce6e-4c74-846f-3eb002c39ef5 --branch main
```

- `ci_scripts/ci_post_clone.sh` generiert `Secrets.xcconfig` aus `$AI_PROXY_SECRET`
- GitHub Actions: `.github/workflows/test.yml` (Build + SwiftLint bei Push/PR)

## Cloudflare Worker Proxy (KI)

**Secret lokal:** `App/Secrets.xcconfig` (git-ignored, NICHT committen)
```
AI_PROXY_SECRET = <dein-app-secret>
```
Template: `App/Secrets.xcconfig.example`
Live: `ai-presents-proxy.hendrikgrueger.workers.dev`

```bash
# Worker deployen:
cd Proxy && npm install
wrangler secret put OPENROUTER_API_KEY
wrangler secret put APP_SECRET   # muss mit Secrets.xcconfig übereinstimmen
wrangler deploy
```

## TestFlight Gruppen

- **Intern:** `Testgrupp Geschenke-App Hendrik` — gruepigmbh@gmail.com, s.mause83@gmail.com, stephaniegrueger@gmail.com
- **Extern `Familie-extern`:** hendrik187, maik.vonangern, j.mastroianni, mail@kurtpetzuch, b00mi, bergen.inga, sophia.grueger, jhgrueger, stephaniegrueger
- **Extern `Externe-Tester`:** mail@kurtpetzuch, b00mi, bergen.inga

## Kritische Swift-Konventionen (Schnellreferenz)

→ Vollständig in `docs/swift-patterns.md`

- `.sheet()` NICHT an Sub-Views in List/Section — immer Top-Level `body`
- `Section("title") { } footer: { }` UNGÜLTIG → `Section { } header: { } footer: { }`
- `GiftIdea` Init: `status` VOR `tags`
- `configFiles` auf Target-Ebene in project.yml (nicht unter `settings:`)
- Keine hardcodierten Farben — immer `AppColor.accent/danger/success`
- `.foregroundStyle()` statt `.foregroundColor()` | `.clipShape(.rect)` statt `.cornerRadius()`
- `ReminderManager`/`AIConsentManager` sind `@MainActor` — NIE neue Instanz in Views
- **`Text("\(int)")` triggert Locale-Tausenderpunkt** (de_DE → "2.025"). Für reine Zahlen wie Jahre, IDs: `Text(verbatim: String(int))` oder `Text(String(int))` (siehe Locale-Falle in `docs/swift-patterns.md`)

## DSGVO — KI

- Consent v2 erforderlich; v1-Nutzer müssen bei Chat erneut zustimmen
- **Übertragen:** Vorname, Altersgruppe, Relation, Sternzeichen, Hobbies, Budget
- **NIE übertragen:** Nachname, Geburtsdatum, exaktes Alter, Notizen, Telefon
- Vollständige Doku: `docs/DSGVO-AI.md`

## Backlog

1. **Custom RelationOptions iCloud-Sync** — UserDefaults nicht synced; bei Geräte-Sync gehen custom-Typen verloren
2. **Relation-DB-Migration** — Vordefinierte Typen deutsch in DB; spätere Migration für englische Keys
3. **Doppelter Loading/Error-State in AI-Sheets** — Shared Components extrahieren (niedrige Prio)
4. **TypingIndicator Avatar** — View auslagern

**Technische Schulden:** `ReminderManager.swift:11` — `nonisolated(unsafe)` Warning auf NSLock (unvermeidbar)

## Docs-Referenz

Volle Übersicht: `docs/README.md` — der zentrale Doku-Index.

| Datei | Inhalt |
|-------|--------|
| `docs/README.md` | **Doku-Index — hier starten** |
| `docs/swift-patterns.md` | Swift-Konventionen, SwiftData, SwiftUI, Concurrency, Lokalisierung, Locale-Falle, AIService-API |
| `docs/architektur-details.md` | Projektstruktur, KI-Chat-Flow, Widget, UI-Architektur, Komponenten |
| `docs/DSGVO-AI.md` | Vollständige DSGVO-Dokumentation |
| `docs/LAUNCH-PLAN.md` | Launch-Plan, 8 Phasen, Revenue-Prognose |
| `docs/E2E-TESTPLAN-CLAUDE-COWORK.md` | E2E-Testplan für Cowork (Computer Use im Simulator) |
| `docs/plans/` | Strukturierte Implementierungspläne |
| `_Archiv/2026-03-historisch/` | Pre-Launch-Material aus März 2026 |
| `Apple Apps/CLAUDE.md` | Skill-Checkliste, ASC CLI, Release-Notes-Regeln |
