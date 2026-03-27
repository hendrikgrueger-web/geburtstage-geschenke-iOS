---
title: "refactor: Code Review Cleanup — Stabilität, Performance, Vereinfachung"
type: refactor
status: active
date: 2026-03-27
---

# refactor: Code Review Cleanup — Stabilität, Performance, Vereinfachung

## Overview

Umsetzung der Findings aus dem Deep Code Review vom 27.03.2026. Fokus auf drei Säulen: (1) Korrektheit fixen, (2) unnötige Komplexität entfernen, (3) Performance-Hotspots adressieren.

## Problem Frame

Die App ist live im App Store (v1.0.2). Der Code funktioniert, hat aber durch die KI-generierte Entstehung und schnelle Feature-Entwicklung technische Schulden angesammelt: duplizierter Code, Overengineering, veraltete Referenzen und Performance-Schwächen die bei wachsender Nutzerzahl auffallen werden.

## Requirements Trace

- R1. Keine funktionalen Regressionen — alle bestehenden Features müssen weiterhin funktionieren
- R2. Build muss ohne Warnings durchlaufen (Xcode 26)
- R3. Jedes Unit muss einzeln committbar sein (atomare Änderungen)

## Scope Boundaries

- NICHT: Neue Features, UI-Redesign, Architektur-Umbau
- NICHT: Test-Coverage erhöhen (separater Plan)
- NICHT: SubscriptionManager/Paywall aktivieren
- NUR: Bestehenden Code verbessern ohne Verhaltensänderung

## Key Technical Decisions

- **SampleDataService bleibt im Haupttarget** aber wird komplett hinter `#if DEBUG` gesetzt: Xcode-Cloud-Builds sind Release-Builds, dort wird der Code automatisch ausgeschlossen. Kein separates Target nötig.
- **AIService Refactoring konservativ**: Shared helper extrahieren, aber die zwei öffentlichen Methoden (`callOpenRouter`, `callOpenRouterChat`) bleiben separat weil sie unterschiedliche Response-Typen liefern.
- **ValidationHelper/FormState nicht anfassen**: Funktioniert, ist nur Overengineering. Aufwand-Nutzen-Verhältnis zu schlecht für reinen Cleanup.

## Implementation Units

### Phase 1: Quick Wins (je 5-15 min, keine Risiken)

- [x] **Unit 1: App-Name in AI-Prompts fixen**

**Goal:** Alle Referenzen auf "AI Präsente" / "AI Présents" durch den neuen lokalisierten App-Namen ersetzen.

**Requirements:** R1

**Dependencies:** Keine

**Files:**
- Modify: `Sources/aiPresentsApp/ViewModels/AIChatViewModel.swift` (Zeilen ~249, ~269, ~293, ~317)

**Approach:**
- DE: "Geschenke AI", EN: "Gifts AI", FR: "Cadeaux AI", ES: "Regalos AI"
- Nur die String-Literale in `buildLocalizedRules()` ändern

**Test scenarios:**
- Build kompiliert
- System-Prompt enthält korrekten App-Namen (via `systemPromptForTesting()`)

**Verification:**
- Grep nach "AI Präsente" und "AI Présents" liefert 0 Treffer in Sources/

---

- [x] **Unit 2: SampleDataService hinter #if DEBUG**

**Goal:** 1.444 LOC Demo-Daten aus Release-Builds ausschließen.

**Requirements:** R1, R3

**Dependencies:** Keine

**Files:**
- Modify: `Sources/aiPresentsApp/Services/SampleDataService.swift`

**Approach:**
- Gesamten Inhalt der Datei in `#if DEBUG ... #endif` wrappen
- In `aiPresentsApp.swift` ist der Aufruf bereits hinter `#if DEBUG` — prüfen ob alle Aufrufe geschützt sind

**Test scenarios:**
- Release-Build kompiliert ohne SampleDataService-Symbole
- Debug-Build funktioniert weiterhin mit Sample-Daten

**Verification:**
- Build succeeds in Debug und Release

---

- [x] **Unit 3: Dead Code entfernen — ContactsService ObservableObject**

**Goal:** Ungenutztes `ObservableObject`-Protokoll von `ContactsService` entfernen.

**Requirements:** R3

**Dependencies:** Keine

**Files:**
- Modify: `Sources/aiPresentsApp/Services/ContactsService.swift`

**Approach:**
- `ObservableObject` aus der Klassendeklaration entfernen
- Grep sicherstellen, dass nirgendwo `@ObservedObject`/`@StateObject` für ContactsService genutzt wird

**Verification:**
- Build succeeds, keine `ObservedObject`-Nutzung von ContactsService gefunden

---

- [x] **Unit 4: Fehlende Lokalisierung in ContentView fixen**

**Goal:** Hardkodierte deutsche Strings in `ContentView.emptyDetailView` lokalisieren.

**Requirements:** R1

**Dependencies:** Keine

**Files:**
- Modify: `Sources/aiPresentsApp/Views/ContentView.swift` (Zeilen ~82-89)

**Approach:**
- `"Keine Person ausgewählt"` und den Beschreibungstext durch `String(localized:)` ersetzen — SwiftUI `Text("...")` ist bereits automatisch `LocalizedStringKey`, nur prüfen ob die Strings im Catalog sind

**Verification:**
- Strings erscheinen in `Localizable.xcstrings` nach Build

---

### Phase 2: Code-Qualität (je 15-30 min)

- [ ] **Unit 5: AIService HTTP-Duplizierung reduzieren**

**Goal:** Gemeinsame HTTP-Request-Logik in eine private Helper-Methode extrahieren.

**Requirements:** R1, R3

**Dependencies:** Keine

**Files:**
- Modify: `Sources/aiPresentsApp/Services/AIService.swift`

**Approach:**
- Private Methode `makeProxyRequest(body:)` extrahieren die URLRequest baut, Header setzt, Secret validiert
- `callOpenRouter()` und `callOpenRouterChat()` nutzen den shared Helper
- Response-Decoding bleibt in den jeweiligen Methoden (unterschiedliche Typen)
- Timeout-Wert (15s) als Konstante

**Patterns to follow:**
- Bestehender `AIService`-Stil: `struct` mit `static let shared`

**Test scenarios:**
- Gift Ideas generieren funktioniert (manuell oder via Test)
- Chat-Funktion funktioniert
- Fehlerbehandlung (kein Secret, HTTP-Fehler) unverändert

**Verification:**
- Keine duplizierte URLRequest-Erstellung mehr
- Build succeeds, bestehende AIServiceTests passieren

---

- [ ] **Unit 6: Künstlichen Sleep in refreshTimeline entfernen**

**Goal:** Unnötige 500ms-Verzögerung beim Pull-to-Refresh entfernen.

**Requirements:** R1

**Dependencies:** Keine

**Files:**
- Modify: `Sources/aiPresentsApp/Views/Timeline/TimelineView.swift` (Zeile ~297)

**Approach:**
- `try? await Task.sleep(nanoseconds: 500_000_000)` entfernen
- SwiftUI `.refreshable` hat eigene Animation, kein künstlicher Delay nötig

**Verification:**
- Pull-to-Refresh funktioniert flüssig ohne Delay

---

### Phase 3: Performance (je 20-40 min)

- [ ] **Unit 7: filteredBirthdays-Berechnung cachen**

**Goal:** Wiederholte Sortierung bei jedem View-Render vermeiden.

**Requirements:** R1

**Dependencies:** Keine

**Files:**
- Modify: `Sources/aiPresentsApp/Views/Timeline/TimelineView.swift`

**Approach:**
- Computed property `filteredBirthdays` durch `@State` oder Memo-Pattern ersetzen
- Alternativ: Da `@Query` bereits die Daten cached, reicht es evtl. die Sortierung in den `@Query`-SortDescriptor zu verlagern. SwiftData `@Query` unterstützt keine berechneten Sortierungen (nächster Geburtstag), daher bleibt computed property — aber mit stabilem Cache über `people.hashValue` + `filterRelation`.
- Pragmatischste Lösung: In der Praxis ist die Sortierung für <500 Kontakte kein messbares Problem. Nur fixen wenn Profiling es zeigt. **Defer to implementation.**

**Test scenarios:**
- Timeline zeigt korrekte Reihenfolge
- Filter funktioniert weiterhin

**Verification:**
- Keine sichtbare Regression bei Sortierung/Filterung

---

## Deferred to Implementation

- **ValidationHelper/FormState Vereinfachung**: Funktioniert, Overengineering ist kein Bug. Bei nächster Änderung an Formularen mitbereinigen.
- **AppLogger Vereinfachung (340 LOC)**: Niedrige Priorität, funktioniert zuverlässig.
- **ReminderManager Singleton entfernen**: Würde Architektur-Umbau erfordern, zu riskant für reinen Cleanup.
- **Zentraler Widget-Refresh Observer**: Gute Idee, aber neues Feature, nicht Refactor.
- **BirthdayCalculator Thread-Safety**: Nur theoretisches Risiko, in der Praxis wird der Cache nur vom MainActor genutzt.

## System-Wide Impact

- **Kein API-Surface-Change**: Alle Änderungen sind intern
- **AI-Prompts**: Unit 1 ändert die System-Prompts — KI-Antworten könnten minimal anders ausfallen (nur App-Name-Referenz)
- **Release-Build-Size**: Unit 2 spart ~1.444 LOC im Release-Binary

## Risks & Dependencies

- **Unit 5 (AIService Refactoring)** ist das einzige Unit mit echtem Regressionsrisiko — nach dem Refactoring manuell testen (Gift Ideas + Chat)
- Alle anderen Units sind minimal-invasiv

## Sources & References

- Code Review vom 27.03.2026 (diese Session)
- Bestehende Code-Patterns in `Sources/aiPresentsApp/Services/`
