---
title: "fix: E2E-Bericht 2026-05-01 — Locale-Year + KI-Datum + Suchleiste"
type: fix
status: active
date: 2026-05-01
origin: docs/E2E-TESTBERICHT-2026-05-01.md
---

# fix: E2E-Bericht 2026-05-01 — Locale-Year + KI-Datum + Suchleiste

## Summary

Drei umsetzbare Fixes aus dem Cowork-E2E-Testlauf gegen Build 1.0.7 (138): Locale-Bug bei Jahreszahlen in der Geschenk-Historie (`Text("\(history.year)")` triggert SwiftUI's `LocalizedStringKey` → de-Locale macht „2.025"), fehlendes Heute-Datum im KI-System-Prompt (LLM halluziniert absolute Daten), und ein UX-Entscheidungspunkt bei der Such-/KI-Leiste. Plus ein Bibliotheks-Update am E2E-Testplan, weil drei vermeintliche Findings (TC-08 Tonalität, TC-12 App-Lock, TC-16 Paywall) bei Code-Validierung kein App-Bug sind, sondern Testplan voraus / conditional UI / bewusst deaktiviert.

Ziel: Mit Wave 2 von v1.0.7 zusammen submitten — kein eigener Versions-Bump, kein zusätzlicher Apple-Review-Zyklus. Build-Nummer hochziehen, Fixes mitnehmen.

---

## Problem Frame

Die Cowork-Session hat im Wesentlichen die Reife der App bestätigt (13/17 ✅, 0 Failures), aber drei substanzielle Auffälligkeiten gemeldet. Bei Code-Validierung blieben **zwei echte Bugs** und **eine UX-Entscheidung**:

1. **TC-05 Locale 2.025:** Jeder User mit deutscher Locale sieht „2.025" / „2.024" auf jeder Person-Detail-Seite mit Historie. Visuell auffällig, wirkt wie ein Tippfehler. Kleiner Code-Change, hoher visueller Impact.
2. **TC-07 KI-Datum halluziniert:** Der Chat sagt „in 7 Tagen, also am 20. Mai" obwohl korrekt 8. Mai. Risiko, dass User sich falschen Tag merkt. Vertrauensschaden bei einer App, deren Hauptversprechen Erinnerungen sind.
3. **TC-09 Suchleiste:** Lupen-Icon (genauer: `sparkle.magnifyingglass`) suggeriert Volltextsuche, aber jeder Tap öffnet KI-Chat. Kein App-Bug, aber UX-Erwartungsbruch.

Drei weitere Findings bei Code-Check als nicht-bugs entlarvt (TC-08 Tonalität-Picker nie gebaut, TC-12 App-Lock conditional auf FaceID-Enroll, TC-16 Paywall bewusst v1-deaktiviert) — die gehören in den Testplan zurück, nicht in den Code.

---

## Requirements

- R1. „2025" / „2024" als Jahres-Plakette in Geschenk-Historie, ohne Tausenderpunkt, in allen Locales.
- R2. KI-Chat (TC-07) und KI-Geschenkvorschläge nennen nur korrekte absolute Daten oder bleiben bei relativen Angaben („in 7 Tagen", „nächste Woche"). Heutiges Datum muss zuverlässig im System-Prompt liegen.
- R3. UX-Entscheidung zur Such-/KI-Leiste umgesetzt (entweder Icon/Placeholder schärfen oder echten Listen-Filter einbauen).
- R4. E2E-Testplan reflektiert tatsächlichen App-Stand (TC-08, TC-12, TC-16 als Tester-Hinweise oder „deferred" markiert).
- R5. Alle Fixes laufen unter v1.0.7 — Build-Nummer 138 → 139, Version bleibt 1.0.7. Mitsubmit als Wave 2.

---

## Scope Boundaries

- **Drin:** Locale-Year-Fix · Datum-Injection in KI-Prompts · Such-/KI-Leiste-Entscheidung umsetzen · Testplan-Update für nicht-bugs.
- **Raus:** App-Lock-Feature ausbauen (existiert bereits conditional, kein Handlungsbedarf). Tonalität-Picker für Geburtstagsnachricht (Test-Plan war voraus, Feature ist nicht geplant). Paywall-Reaktivierung (eigener Plan, ASC-Metadata-heavy). Sheet-Header „Idee bearbeit…"-Truncation (kosmetisch, niedrig, separat falls nötig).

### Deferred to Follow-Up Work

- Sheet-Header-Truncation TC-04: Falls reproduzierbar auf älteren iPhones, eigenes Mini-Issue in v1.0.8.

---

## Context & Research

### Relevant Code and Patterns

- `Sources/aiPresentsApp/Views/Gift/GiftHistoryRow.swift:19` — `Text("\(history.year)")` ist die Bug-Stelle. Lösung: `Text(verbatim: "\(history.year)")` oder `Text(String(history.year))`.
- `Sources/aiPresentsApp/Views/Gift/GiftHistoryRow.swift:96` — Accessibility-Label nutzt `\(history.year)` ebenfalls; in `String(localized:)`-Kontext aber unkritisch (ResultBuilder, kein Format).
- `Sources/aiPresentsApp/ViewModels/AIChatViewModel.swift:168 buildSystemPrompt()` — System-Prompt-Builder. Datum-Injection als erste Zeile nach den Regeln einfügen, lokalisiert.
- `Sources/aiPresentsApp/Services/AIService.swift:247` und `:313` — zwei weitere Stellen mit `systemPrompt` (KI-Geschenkvorschläge + Geburtstagsnachricht). Beide checken, ob sie ebenfalls Datums-Anker brauchen.
- `Sources/aiPresentsApp/Views/Timeline/TimelineView.swift:424 smartSearchBar` + `:430 sparkle.magnifyingglass` — Suchleiste; bisher reiner KI-Trigger.
- `Sources/aiPresentsApp/Views/AI/ChatInputBar.swift:36` — Placeholder „Suche oder frag die KI…" lebt hier; bei UX-Entscheidung mit anpassen.

### Institutional Learnings

- `Memory: feedback_extreme_testing.md` — Latte ist 1148-Tests-Baseline. Jeder neue Code-Pfad bekommt Edge-Case-Tests inkl. Locale-Varianten (de-DE, fr-FR, en-US).
- SwiftUI-Fallstrick: `Text("\(int)")` formatiert Integers via `LocalizedStringKey` mit dem aktiven NumberFormatter. Für nicht-numerische Integer-Anzeigen (Jahre, IDs, Counter ohne Tausender-Sinn) immer `Text(verbatim:)` oder `Text(String(int))`.

### External References

- Apple HIG „Search Field": Lupe = Filterung der sichtbaren Liste; KI/Sparkles = Generative Eingabe. Mischformen sollten unterschiedliche Glyphs nutzen.

---

## Key Technical Decisions

- **Year-Format:** `Text(verbatim: "\(history.year)")`. Minimaler Diff, klare Intent-Aussage, kein neuer Formatter nötig. Alternativen `String(history.year)` oder `history.year.formatted(.number.grouping(.never))` funktionieren ebenfalls — `verbatim` ist am direktesten.
- **Datum im System-Prompt:** Lokalisierte Klartext-Zeile als allererste Zeile nach den Regeln, plus ISO-String als Anker für die Maschine. Beispiel-Format DE: `Heute ist Freitag, der 1. Mai 2026 (2026-05-01).`. Aufgenommen in alle vier Sprachen (de/en/fr/es), parallele Strings.
- **Such-/KI-Leiste:** Variante **A** — Placeholder + Icon präzisieren statt Listen-Filter zu bauen. Konkret: Icon bleibt `sparkle.magnifyingglass` (Sparkle-Punkt ist da), Placeholder wird **„Frag die KI nach Geschenken oder Daten…"** statt „Suche oder frag die KI…". Erwartung Suche → entfernt. Begründung: Existierender Beziehungs-Filter (Toolbar) deckt Listen-Filter ab; ein zweiter Filter über das Eingabefeld würde redundant. Wenn später echte Volltextsuche gewünscht wird, eigenes Plan-Item.

  *Alternative verworfen:* Zwei separate Eingaben (Filter + KI). Mehr UI-Fläche, mehr Onboarding-Friction. Nicht v1.0.7-tauglich.

---

## Open Questions

### Resolved During Planning

- *Welche Version trägt die Fixes?* → v1.0.7 Wave 2, Build 139. 1.0.6 ist im Apple-Review, 1.0.7-Wave-1 ist nur lokal committed (nicht submitted). Kein zusätzlicher Review-Zyklus.
- *App-Lock TC-12 ausbauen?* → Nein. `AppLockManager` ist da, Section ist conditional. Kein Code-Change, nur Testplan-Hinweis.
- *Paywall TC-16?* → Nein. v1-Launch hat alle Features gratis (CLAUDE.md). Eigener Plan irgendwann.
- *Tonalität-Picker TC-08?* → Nein. Aktuelles Sheet liefert sehr gute Default-Variante. Test-Plan veraltet, kürzen.

### Deferred to Implementation

- Genauer Wortlaut der lokalisierten Datum-Zeile (de/en/fr/es) — entstehen beim Code-Touch, nicht hier vorher.
- Ob `AIService.swift:247/313` (Vorschläge + Geburtstagsnachricht) auch Datum brauchen — beim Touch entscheiden, wahrscheinlich nur Birthday-Message profitiert vom Heute-Anker für Meilenstein-Logik.

---

## Implementation Units

- U1. **Year-Format-Fix in GiftHistoryRow**

**Goal:** Jahresanzeige in Geschenk-Historie ohne Tausenderpunkt in allen Locales.

**Requirements:** R1

**Dependencies:** keine

**Files:**
- Modify: `Sources/aiPresentsApp/Views/Gift/GiftHistoryRow.swift`
- Test: `Tests/aiPresentsAppTests/GiftHistoryRowTests.swift` (anlegen falls nicht vorhanden) oder erweitern bestehender Snapshot-/View-Test

**Approach:**
- Zeile 19: `Text("\(history.year)")` → `Text(verbatim: "\(history.year)")`.
- Greppen nach weiteren `Text("\(...year)")`-Pattern in `Views/` und ggf. parallel anpassen (z.B. PersonDetailGiftHistorySection-String-Builder hat dasselbe Risiko in copy/share-Context — dort ist es im `String(localized:)` aber ResultBuilder, kein Format-Trigger; nur prüfen).

**Patterns to follow:**
- Bestehende `Text(verbatim:)`-Aufrufe in der Codebase als Referenz, falls vorhanden.

**Test scenarios:**
- Happy path: GiftHistory mit `year = 2025` rendert „2025" (nicht „2.025"), unabhängig von `Locale.current` (mindestens de_DE und en_US in Test setzen).
- Edge case: `year = 1999` und `year = 2030` ebenso ohne Tausenderpunkt.
- Edge case: Locale fr_FR (französische Locale formatiert Tausenderpunkt als schmales Leerzeichen) — Output bleibt „2025".

**Verification:**
- Snapshot oder Text-Equality-Assertion grün.
- Visueller Smoke im iPhone-17-Simulator: Jahres-Plakette zeigt „2025" / „2024".

---

- U2. **Heute-Datum im KI-System-Prompt**

**Goal:** KI nennt nur korrekte absolute Daten oder bleibt bei relativen Angaben — Halluzination wie „20. Mai" verhindern.

**Requirements:** R2

**Dependencies:** keine

**Files:**
- Modify: `Sources/aiPresentsApp/ViewModels/AIChatViewModel.swift` (Funktion `buildLocalizedRules` ab Zeile 205, vier Sprach-Strings ab `case "de":` etc.)
- Modify (prüfen, ggf. kleiner Touch): `Sources/aiPresentsApp/Services/AIService.swift:247` und `:313` — Birthday-Message-Prompt profitiert vom Heute-Anker, Suggestions-Prompt eher nicht (Vorschläge sind zeitlich neutral).
- Test: `Tests/aiPresentsAppTests/AIChatViewModelTests.swift` (System-Prompt-Builder ist über `systemPromptForTesting()` schon zugänglich, siehe Zeile 613).

**Approach:**
- Direkt vor der `REGELN`/`RULES`-Zeile eine Datum-Zeile einfügen. Bauen via `DateFormatter` mit `dateStyle = .full` für die Klartext-Variante und ISO-String separat:
  - DE: `"Heute ist \(klartextDatum) (\(isoDatum)). Antworte nur mit konkreten Daten, wenn du sie aus diesem Datum sicher ableiten kannst — sonst bleibe bei relativen Angaben (\"in X Tagen\")."`
  - EN/FR/ES: parallele Strings, gleiche Schutz-Klausel.
- ISO-Datum berechnen mit `Date()` + `ISO8601DateFormatter` (nur Datum, ohne Zeit).
- Klartext mit `Locale.current` formatieren, damit Wochentag/Monat zur Sprache passen.
- Cache-Invalidation: System-Prompt ist gecacht (`cachedSystemPrompt` Zeile 30) — Cache wird heute nur bei Datenänderungen invalidiert. Heute-Datum altert nach Mitternacht, daher beim Build den **letzten Bau-Tag** mit speichern und beim nächsten `currentSystemPrompt`-Aufruf auf Tageswechsel prüfen, sonst rebuild.

**Patterns to follow:**
- Datums-Formatter-Pattern aus `FormatterHelper.shortLogDateFormatter` (Zeile 508) — analoge `currentDateForPrompt`-Variante anlegen.

**Test scenarios:**
- Happy path: System-Prompt enthält ISO-Datum von `Date()` und Klartext-Wochentag in DE.
- Happy path: System-Prompt-Bau in en/fr/es ergibt jeweils sprachpassende Klartext-Datums-Zeile.
- Edge case: Cache wird bei Tageswechsel verworfen (Test mit injiziertem `currentDate`-Provider, sonst Datum-Mock per `Date`-Override-Hilfe).
- Edge case: Cache wird bei Datenänderungen UND Tageswechsel invalidiert (zusammen, nicht getrennt).
- Integration: Real-Call-Test (geskippt ohne `AI_PROXY_SECRET`, sonst Frage „Wer hat in 7 Tagen Geburtstag?" — Antwort enthält **kein** Datum mehr als +7 Tage von `Date()`, oder enthält das korrekte +7-Tages-Datum). Diese Integration ist optional/manuell.

**Verification:**
- Test grün, manueller Smoke im Simulator: dieselbe Frage wie im Cowork-Lauf liefert korrektes Datum oder bleibt rein relativ.

---

- U3. **Such-/KI-Leiste UX-Refresh**

**Goal:** Erwartungsbruch entfernen — Leiste signalisiert klar „KI", nicht „Suche".

**Requirements:** R3

**Dependencies:** keine

**Files:**
- Modify: `Sources/aiPresentsApp/Views/AI/ChatInputBar.swift` (Zeile 36, Placeholder)
- Modify (falls eigene Strings): `Sources/aiPresentsApp/Views/Timeline/TimelineView.swift:434`
- Modify: Localizable.xcstrings (de/en/fr/es) — neuer Placeholder
- Test: bestehender ViewInspector- oder Snapshot-Test der TimelineView, falls vorhanden; sonst manueller Smoke

**Approach:**
- Placeholder DE: `"Frag die KI nach Geschenken oder Daten…"` (analog en/fr/es).
- Icon `sparkle.magnifyingglass` bleibt — Sparkle-Punkt ist da, das ist der KI-Hinweis.
- Optional Mikro-Tweak: Icon-Tint auf `AppColor.accent` (lila/pink) setzen, falls noch grau — verstärkt KI-Affordance ohne neuen Glyph.

**Patterns to follow:**
- Bestehende Placeholder-Strings in Localizable.xcstrings (Stil und Punktation).

**Test scenarios:**
- *Test expectation: minimal — String-Existenz + Locale-Roundtrip.* Pure UI-Copy-Änderung, kein Verhaltens-Bug.
- Happy path: Localizable.xcstrings hat den neuen Key in allen 4 Sprachen (DE/EN/FR/ES), kein Locale-Fallback auf Default-Sprache.

**Verification:**
- Visueller Smoke im Simulator: Leiste zeigt neuen Text, Icon-Tint stimmt, Tap öffnet weiterhin den Chat.

---

- U4. **E2E-Testplan-Update für Nicht-Bugs**

**Goal:** Test-Plan reflektiert tatsächlichen App-Stand. Künftige Cowork-Läufe melden die drei Punkte nicht erneut.

**Requirements:** R4

**Dependencies:** keine

**Files:**
- Modify: `docs/E2E-TESTPLAN-CLAUDE-COWORK.md`

**Approach:**
- TC-08 (Tonalität-Picker): Passus mit „Tonalität wählen" entfernen, Notiz „Sheet generiert eine herzliche Default-Variante; Tonalität-Auswahl ist nicht implementiert."
- TC-12 (App-Lock): Hinweis-Block ergänzen: „Section ist conditional auf `LAContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics)` — im Sim ohne FaceID-Enroll **erwartet unsichtbar**. Vor Test im Sim: `Features → Face ID → Enrolled` aktivieren."
- TC-16 (Paywall): Hinweis-Block: „Paywall ist im v1-Launch bewusst deaktiviert (alle Features gratis). Test gilt erst ab Version mit aktiver Subscription, vor v1.1.x überspringen."
- TC-04 (Sheet-Header): Niedrig-Prio-Notiz unter „Bekannte offene Punkte" ergänzen.

**Patterns to follow:**
- Bestehender Stil im Testplan (Tabelle „Bekannte Einschränkungen für Computer Use" in Section 1).

**Test scenarios:**
- *Test expectation: none — reine Doku-Änderung.*

**Verification:**
- Re-Read: Section 5 „Bekannte offene Punkte" enthält die drei Hinweise.

---

- U5. **Build-Bump 1.0.7 (138) → 1.0.7 (139) + WHATS-NEW-Update**

**Goal:** Wave 2 als neuer TestFlight-Build, App-Store-Release-Notes ergänzt.

**Requirements:** R5

**Dependencies:** U1, U2, U3 (U4 ist Doku, kann parallel)

**Files:**
- Modify: `project.yml` (CFBundleVersion 138 → 139, beide Targets: App + Widget)
- Re-Generate: `xcodegen generate` → Info.plist-Files mit-committen
- Modify: `docs/WHATS-NEW-1.0.7.md` (kleiner Punkt: „Geschenk-Historie zeigt Jahre wieder ohne Tausenderpunkt. KI-Chat kennt das aktuelle Datum und nennt korrekte Termine. Such-/KI-Leiste signalisiert klarer, dass sie zur KI führt." in DE/EN/FR/ES)

**Approach:**
- `project.yml` editieren, `xcodegen generate` laufen lassen.
- Lokaler `xcodebuild build` als Sanity-Check.
- Commit + push → Xcode Cloud TestFlight-Workflow läuft automatisch.
- App-Store-Build-Workflow erst nach Wave-2-Smoke-Test triggern.

**Patterns to follow:**
- `Apple Apps/CLAUDE.md` „App-Store-Release: kompletter Auto-Pfad" — Schritte 1–13.

**Test scenarios:**
- *Test expectation: none — Build/Release-Step.*

**Verification:**
- TestFlight-Build SUCCEEDED (`asc xcode-cloud build-runs --workflow-id FAF5B5BC-AC5C-45CC-AE14-F82C1136A295`).
- WHATS-NEW-1.0.7.md enthält neuen Bullet in 4 Sprachen.

---

## System-Wide Impact

- **Interaction graph:** U2 berührt KI-Pfad — `AIChatViewModel.buildSystemPrompt` wird von Chat + Suggestions + Birthday-Message indirekt erreicht. Beim Refactoring prüfen, ob Cache-Invalidierung an Tageswechsel die anderen Pfade nicht stört.
- **Error propagation:** Keine. Reine View-/Prompt-Änderungen.
- **State lifecycle risks:** Cache-Invalidation für Tageswechsel ist neu — Test braucht injizierbaren `currentDate`-Provider, sonst nicht deterministisch.
- **API surface parity:** `Text(verbatim:)`-Pattern dokumentieren in `docs/swift-patterns.md`, damit das nicht in zukünftigen Views erneut auftritt.
- **Integration coverage:** Real-Call-Test gegen Worker (mit Secret) ist optional — die Test-Suite bleibt ohne grün.
- **Unchanged invariants:** DSGVO-Pfade unverändert. Worker-Proxy unverändert (Datum kommt clientseitig in den Prompt). Keine neuen Daten in Übertragung.

---

## Risks & Dependencies

| Risk | Mitigation |
|------|------------|
| `Text(verbatim:)` schaltet Lokalisierung aus — bei reinen Zahlen-Anzeigen ist das gewollt, aber Pattern darf nicht versehentlich auf lokalisierte Strings angewendet werden. | Code-Review-Checkpoint: nur auf `\(int)` und ähnlichen Locale-neutralen Werten. Pattern-Doku in `docs/swift-patterns.md` ergänzen. |
| Cache-Invalidation bei Tageswechsel könnte zu zusätzlichen Prompt-Rebuilds führen, falls jemand nachts chattet. | Akzeptabel — Rebuild ist billig (in-memory String-Building). Alternativ Tageswechsel-Check nur wenn Cache älter als X Stunden. |
| `xcodebuild` schlägt nach `xcodegen generate` fehl, weil neue Test-Datei (`GiftHistoryRowTests.swift`) im project.yml nicht gepflegt ist. | Nach `xcodegen generate` lokaler Build sofort testen, bevor commit. |
| Wave-2-Submit kollidiert mit 1.0.6-Review (WAITING_FOR_REVIEW). | 1.0.6 ist gerade in Review, 1.0.7 darf parallel als Draft + Build-Upload existieren. Submit erst nach 1.0.6-Approve oder explizit als Replacement. |

---

## Documentation / Operational Notes

- `docs/swift-patterns.md` Eintrag „SwiftUI: `Text("\(int)")` und Locale-Tausenderpunkt" ergänzen — Memory-Lesson für künftige Code-Reviews.
- `docs/E2E-TESTPLAN-CLAUDE-COWORK.md` Abschnitt 5 (Bekannte offene Punkte) erweitern (siehe U4).
- Nach Submit Memory-Eintrag aktualisieren: aktuelle App-Store-Submission auf 1.0.7 (139) hochziehen.

---

## Sources & References

- **Origin-Bericht:** `docs/E2E-TESTBERICHT-2026-05-01.md`
- **E2E-Testplan:** `docs/E2E-TESTPLAN-CLAUDE-COWORK.md`
- **Bestehender 1.0.7-Plan:** `docs/plans/2026-05-01-001-feat-review-improvements-v107-plan.md` (Wave 1 schon geshipped — Wave 2 = dieser Plan)
- **Notion-Spiegel des Berichts:** https://app.notion.com/p/3534172cb88681469913efe66efa6687
- **Code-Stellen:**
  - `Sources/aiPresentsApp/Views/Gift/GiftHistoryRow.swift:19`
  - `Sources/aiPresentsApp/ViewModels/AIChatViewModel.swift:168` und `:205`
  - `Sources/aiPresentsApp/Views/Timeline/TimelineView.swift:424` und `:430`
  - `Sources/aiPresentsApp/Views/AI/ChatInputBar.swift:36`
  - `Sources/aiPresentsApp/Views/Settings/SettingsView.swift:192` (App-Lock conditional, kein Touch)
