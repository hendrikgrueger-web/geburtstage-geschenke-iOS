---
title: "fix: Widget-Countdown immer korrekt — nextBirthdayDate statt daysUntil"
type: fix
status: completed
date: 2026-04-03
---

# fix: Widget-Countdown immer korrekt — nextBirthdayDate statt daysUntil

## Overview

Das Widget zeigt falsche oder keine Daten wenn die App mehr als 7 Tage nicht geöffnet wurde.
Kern-Bug: `WidgetBirthdayEntry.daysUntil` ist ein einmalig berechneter Integer-Snapshot.
Der `BirthdayTimelineProvider` kompensiert zwar per `dayOffset`-Subtraktion, aber nur für 7 Tage.
Danach sind alle adjustierten Werte negativ → werden herausgefiltert → Widget zeigt nichts oder Stale-Daten.

Fix: `nextBirthdayDate: Date` (echtes Geburtstagsdatum) statt `daysUntil: Int` im Snapshot speichern.
Der Provider berechnet `daysUntil` dynamisch für jede Timeline-Position. Timeline auf 30 Tage erweitern.

## Problem Frame

### Bug 1 — Kritisch: `daysUntil` veraltet nach Tagen ohne App-Öffnung

**Ablauf heute:**
1. App wird geöffnet (Tag 0): Anna hat Geburtstag in 3 Tagen → `daysUntil = 3` in JSON eingefroren
2. Tag 1–3: Provider subtrahiert `dayOffset` → Werte 2, 1, 0 — korrekt
3. Tag 4+: `adjusted = 3 - 4 = -1` → Anna wird herausgefiltert — **Widget leer**
4. Tag 7: System ruft `getTimeline()` erneut auf → JSON hat noch immer `daysUntil = 3` → dayOffset=0 → adjusted=3, **aber Geburtstag war schon 4 Tage her** → falsches Datum angezeigt

### Bug 2 — Mittel: `BirthdayCalculator`-Cache nicht gecleared vor Widget-Snapshot

`updateWidgetData()` ruft `makeEntries()` auf, das `BirthdayCalculator` nutzt.
Der Calculator cached Ergebnisse für 5 Minuten (z.B. nach App-Start, nach Mitternacht).
`clearCache()` wird nur beim Pull-to-Refresh aufgerufen, nicht bei anderen Triggern.
→ Kurz nach Mitternacht oder beim Background-Wechsel können veraltete Cache-Werte eingefroren werden.

### Bug 3 — Niedrig: `reloadAllTimelines()` verschwendet WidgetKit-Budget

Aktuell wird `WidgetCenter.shared.reloadAllTimelines()` aufgerufen, obwohl nur ein Widget-Typ
(`kind = "BirthdayWidget"`) existiert. Für zukünftige Widget-Typen würde das deren Budget unnötig belasten.

## Requirements Trace

- R1: Countdown-Werte im Widget müssen exakt korrekt sein, unabhängig davon wie lange die App zuletzt geöffnet war
- R2: Das Widget zeigt mindestens 30 Tage korrekte Daten ohne App-Öffnung
- R3: Widget-Updates dürfen das WidgetKit-Budget nicht unnötig verschwenden (kein `reloadAllTimelines()`)
- R4: `BirthdayCalculator`-Cache wird immer invalidiert bevor Widget-Daten berechnet werden

## Scope Boundaries

- Kein Wechsel auf SwiftData-Direktzugriff im Widget (JSON-in-UserDefaults bleibt — richtig für diese Datenmenge)
- Kein WidgetPushHandler / Server-Push (wäre für eine spätere Phase)
- Keine Änderung am App Group ID oder UserDefaults Key
- Keine neuen Widget-Größen oder -Typen

## Kontext & Recherche

### Relevante Dateien

- `Sources/aiPresentsApp/Services/WidgetDataService.swift` — Struct `WidgetBirthdayEntry` + `makeEntries()` + Reload-Aufruf
- `Sources/BirthdayWidget/WidgetSharedTypes.swift` — **Duplikat** desselben Structs für das Widget-Target
- `Sources/BirthdayWidget/BirthdayTimelineProvider.swift` — `getTimeline()` mit 7-Tage-Fenster und dayOffset-Subtraktion
- `Sources/BirthdayWidget/BirthdayWidgetViews.swift` — konsumiert `birthday.daysUntil` direkt
- `Sources/aiPresentsApp/Utilities/BirthdayCalculator.swift` — `clearCache()` existiert, wird nur in `refreshTimeline()` aufgerufen

### Wichtiges Architektur-Detail

`WidgetBirthdayEntry` ist in **zwei Targets dupliziert** (Widget-Extensions können nicht auf das App-Target zugreifen):
- App-Target: `Sources/aiPresentsApp/Services/WidgetDataService.swift` (Zeile 6–14)
- Widget-Target: `Sources/BirthdayWidget/WidgetSharedTypes.swift` (Zeile 4–12)

**Beide Structs müssen synchron geändert werden.**

### Widget `kind`-String

`BirthdayWidget.swift:5` — `let kind: String = "BirthdayWidget"`
→ Für `reloadTimelines(ofKind: "BirthdayWidget")` verwenden.

### Best-Practice-Erkenntnisse (WidgetKit)

- `reloadAllTimelines()` aus dem App-Foreground ist nicht budget-limitiert, schadet aber zukünftiger Erweiterbarkeit
- 30 Tage pre-computed Timeline mit `policy: .after(nextRefreshDate)` ist die empfohlene Strategie
- JSON-in-UserDefaults ist korrekt für Geburtstagsdaten (weit unter 1 MB)
- SwiftData direkt im Widget-Target lohnt sich erst bei komplexen Abfragen — hier nicht nötig

## Technische Kerndezision

**`daysUntil: Int` → `nextBirthdayDate: Date` im JSON-Snapshot**

Rationale: Ein `Date` referenziert ein unveränderliches Kalenderereignis. Jede Timeline-Position
(jedes `entry.date`) kann daraus eigenständig und korrekt `daysUntil` berechnen:

```
daysUntil = Calendar.dateComponents([.day], from: entry.date, to: birthday.nextBirthdayDate).day
```

Diese Berechnung liefert immer den korrekten Wert — unabhängig davon, wann `getTimeline()` aufgerufen wird
oder wie lange der JSON-Snapshot unverändert im App Group UserDefaults lag.

> *Dies ist direktionale Orientierung, keine Implementierungsspezifikation.*

```
Snapshot (JSON)          Provider              Views
────────────────         ─────────────         ──────────────────────────
id                   →   id               →    displayName
displayName          →   displayName      →    relation
nextBirthdayDate ──┐→   nextBirthdayDate  →    nextBirthdayDate
nextAge              │   nextAge           →    daysUntil (berechnet aus
relation             │   relation              entry.date → nextBirthdayDate)
giftStatus           │   giftStatus
skipGift             │   skipGift
                     │
entry.date ──────────┘→  daysUntil (berechnet)
                         [filter: daysUntil >= 0]
```

## Open Questions

### Resolved During Planning

- **Soll `daysUntil` im Struct bleiben (als Redundanz) oder komplett entfernt werden?**
  Entscheidung: Komplett entfernen. Redundante Felder führen zu Inkonsistenz-Bugs in der Zukunft.
  Die Views berechnen es aus `entry.date` + `birthday.nextBirthdayDate` inline.

- **Soll die Timeline von 7 auf 30 Tage erweitert werden?**
  Ja. Mit `nextBirthdayDate` ist die Verlängerung kostenlos (kein größerer Snapshot nötig).
  `policy: .after(nextRefreshDate)` wird entsprechend auf 30 Tage gesetzt.

- **SwiftData direkt im Widget-Target?**
  Nein. JSON-Snapshot ist für diese Datenmenge korrekt und einfacher.

### Deferred to Implementation

- Exact Swift syntax für `dateComponents([.day], from:to:)` wenn `nextBirthdayDate` in der Vergangenheit liegt (guard days >= 0)
- Ob `BirthdayWidgetViews.swift` `entry.date` oder `Date()` für die View-interne Berechnung nutzen soll (muss `entry.date` sein für Timeline-Korrektheit)

## Implementation Units

- [ ] **Unit 1: `WidgetBirthdayEntry` in beiden Targets — `nextBirthdayDate: Date` statt `daysUntil: Int`**

**Goal:** Das Codable-Struct speichert das echte Geburtsdatum als `Date` im JSON-Snapshot, nicht mehr den vorberechneten Integer-Countdown.

**Requirements:** R1, R2

**Dependencies:** Keine

**Files:**
- Modify: `Sources/aiPresentsApp/Services/WidgetDataService.swift` — Struct + `makeEntries()`
- Modify: `Sources/BirthdayWidget/WidgetSharedTypes.swift` — identisches Struct (Widget-Target-Duplikat)

**Approach:**
- `WidgetBirthdayEntry`: `daysUntil: Int` entfernen, `nextBirthdayDate: Date` hinzufügen (Codable Date → ISO8601 by default)
- `makeEntries()`: `BirthdayCalculator.nextBirthday(for:from:)` existiert bereits — dessen Rückgabewert als `nextBirthdayDate` speichern (statt `daysUntil` von `BirthdayCalculator.daysUntilBirthday()`)
- Wenn `nextBirthday` nil ist (kein gültiger Geburtstag berechenbar): Person herausfiltern (wie bisher)
- **Beide Struct-Definitionen müssen Feld-für-Feld identisch sein** — sie teilen dasselbe JSON-Format

**Patterns to follow:**
- `makeEntries()` in `WidgetDataService.swift:83–107` — bestehende Logik beibehalten, nur Feldname wechseln

**Test scenarios:**
- Person mit bekanntem Geburtstag: `nextBirthdayDate` ist das nächste Datum dieses Jahres (oder nächstes Jahr wenn bereits passiert)
- Person mit unbekanntem Geburtsjahr (`birthYearKnown = false`): `nextBirthdayDate` korrekt ohne Jahresberechnung
- Schaltjahr (29.02.): `BirthdayCalculator.nextBirthday()` gibt korrektes Datum zurück (bestehende Logik)
- JSON-Roundtrip: Encode → Decode ergibt identisches `nextBirthdayDate`

**Verification:**
- Build: Beide Targets kompilieren fehlerfrei
- `makeEntries()` gibt Entries mit `nextBirthdayDate` zurück, kein `daysUntil` im JSON mehr

---

- [ ] **Unit 2: `BirthdayTimelineProvider` — Dynamische Countdown-Berechnung + 30-Tage-Fenster**

**Goal:** Der Provider berechnet `daysUntil` für jede Timeline-Position dynamisch aus `entryDate → nextBirthdayDate`. Die Timeline umfasst 30 statt 7 Tage.

**Requirements:** R1, R2

**Dependencies:** Unit 1 (neues Struct-Format)

**Files:**
- Modify: `Sources/BirthdayWidget/BirthdayTimelineProvider.swift`

**Approach:**
- `getTimeline()`: Loop von `0..<30` statt `0..<7`
- Für jede Timeline-Position (`entryDate`): `daysUntil = Calendar.dateComponents([.day], from: entryDate, to: birthday.nextBirthdayDate).day`
- Filter: `guard days >= 0` — gleiche Semantik wie bisher, aber jetzt korrekt auf Basis realer Daten
- Sortierung: weiterhin nach `daysUntil` ascending
- `policy: .after(nextRefreshDate)` → `nextRefreshDate` = `startOfDay` in 30 Tagen
- Sample-Daten: `nextBirthdayDate` als relative Dates definieren: `Calendar.current.date(byAdding: .day, value: N, to: Date())`

**Patterns to follow:**
- Bestehende `getTimeline()` Struktur beibehalten — nur `dayOffset`-Subtraktion ersetzen durch echte Datum-Differenz

**Test scenarios:**
- Geburtstag in 3 Tagen: Timeline-Entry für Tag 0 zeigt 3, Tag 1 zeigt 2, Tag 3 zeigt 0
- Geburtstag heute (daysUntil = 0): Entry für Tag 0 zeigt 0, Entry für Tag 1 filtert Person heraus (wäre -1)
- Geburtstag in 25 Tagen: Korrekt innerhalb des 30-Tage-Fensters
- Alle Personen haben weit entfernte Geburtstage (>30 Tage): Widget zeigt leere Einträge — leerer State muss korrekt gerendert werden
- Timeline-Entry für Tag 29: `daysUntil` wird korrekt aus 29 Tagen Distanz berechnet

**Verification:**
- Widget-Preview (Medium + Large) zeigt korrekte Countdowns
- `getSnapshot()` funktioniert unverändert (liest Entries und gibt direkt aus)
- Build: Widget-Target kompiliert fehlerfrei

---

- [ ] **Unit 3: `BirthdayWidgetViews` — `daysUntil` inline aus `entry.date + nextBirthdayDate` berechnen**

**Goal:** Da `WidgetBirthdayEntry` kein `daysUntil` mehr hat, berechnen die Views den Wert inline aus den verfügbaren Daten.

**Requirements:** R1

**Dependencies:** Unit 1 (kein `daysUntil` mehr im Struct)

**Files:**
- Modify: `Sources/BirthdayWidget/BirthdayWidgetViews.swift`

**Approach:**
- `BirthdayWidgetRow` (und alle anderen Views) nutzen derzeit `birthday.daysUntil`
- Ersetzen durch: `Calendar.current.dateComponents([.day], from: entry.date, to: birthday.nextBirthdayDate).day ?? 0`
- `entry.date` ist aus `BirthdayTimelineEntry` zugänglich — muss als Parameter in die View gereicht werden wenn nicht bereits vorhanden
- **Wichtig:** `entry.date` (nicht `Date()`) verwenden — die View muss den Countdown für die jeweilige Timeline-Position anzeigen, nicht für "jetzt"

**Patterns to follow:**
- `BirthdayWidgetMediumView` und `BirthdayWidgetLargeView` reichen `entry` durch → `BirthdayWidgetRow` hat Zugriff auf `entry.date`

**Test scenarios:**
- `entry.date` = heute + 2 Tage, `nextBirthdayDate` = heute + 5 Tage → `daysUntil` = 3 (korrekt für diese Timeline-Position)
- Farblogik (rosa/orange/blau) basiert auf berechnetem `daysUntil` — muss identisch zur bisherigen Logik bleiben
- `entry.date > nextBirthdayDate` sollte in der View nicht vorkommen (Provider filtert diese heraus) — dennoch defensiv auf `max(0, ...)` prüfen

**Verification:**
- Widget-Previews zeigen korrekte Farben und Countdown-Werte
- Keine Verwendung von `birthday.daysUntil` mehr im Widget-Target (Grep-Check)

---

- [ ] **Unit 4: `WidgetDataService` — Cache-Invalidierung + `reloadTimelines(ofKind:)`**

**Goal:** Cache wird vor jeder Widget-Berechnung gecleared; Reload verwendet den spezifischen Kind-String.

**Requirements:** R3, R4

**Dependencies:** Keine (unabhängig von Units 1–3, kann parallel implementiert werden)

**Files:**
- Modify: `Sources/aiPresentsApp/Services/WidgetDataService.swift`

**Approach:**
- In `updateWidgetData()`: `BirthdayCalculator.clearCache()` vor dem Aufruf von `makeEntries()` einfügen
- `WidgetCenter.shared.reloadAllTimelines()` → `WidgetCenter.shared.reloadTimelines(ofKind: "BirthdayWidget")`
- Kind-String als `private static let widgetKind = "BirthdayWidget"` Konstante extrahieren

**Patterns to follow:**
- `clearCache()` wird in `TimelineView.swift:refreshTimeline()` aufgerufen — gleiches Muster

**Test scenarios:**
- `updateWidgetData()` aufgerufen kurz nach App-Start: Cache wird gecleared, frische Werte berechnet
- `updateWidgetData()` aufgerufen beim Hintergrund-Wechsel kurz nach Mitternacht: Cache-Invalidierung verhindert, dass veraltete Werte vom Vortag eingefroren werden

**Verification:**
- `reloadAllTimelines()` kommt nicht mehr im App-Target vor (Grep-Check)
- `clearCache()` wird in `updateWidgetData()` aufgerufen (Code-Review)

## System-Wide Impact

- **Keine Breaking Changes für Nutzer:** Das Widget zeigt weiterhin dieselben Informationen, aber korrekt
- **JSON-Format Änderung:** Der UserDefaults-Key `widgetBirthdayEntries` enthält ein neues JSON-Schema (`nextBirthdayDate` statt `daysUntil`). Bei erstem App-Update schlägt `JSONDecoder().decode()` in `WidgetSharedTypes.swift:readEntries()` fehl → gibt `[]` zurück → Widget leer bis App das erste Mal `updateWidgetData()` schreibt. Das ist akzeptabel (passiert beim ersten App-Start nach Update).
- **`BirthdayWidgetViews.swift` braucht `entry.date`:** Prüfen ob `entry` bereits in die Sub-Views propagiert wird oder ob eine Anpassung der View-Hierarchie nötig ist.

## Risks & Dependencies

- **JSON-Schema-Break:** Einmaliger leerer Widget-State beim ersten Start nach Update. Nicht kritisch — App schreibt sofort beim Start neuen Snapshot.
- **`nextBirthdayDate` nach Geburtstag:** Nach dem Geburtstag zeigt der Snapshot das Datum der **vergangenen** Feier bis die App das nächste Mal geöffnet wird (dann wird `nextBirthday` für nächstes Jahr berechnet). Da der Provider `daysUntil >= 0` filtert, wird die Person nach ihrem Geburtstag aus dem Widget verschwinden — das ist korrekt. Erst nach App-Öffnung erscheint sie wieder mit 365 Tagen.
- **Beide Struct-Definitionen in Sync:** Unit 1 muss beide Dateien gleichzeitig ändern. Compiler weist auf Typ-Fehler hin wenn eine Seite fehlt.

## Sources & References

- Bestehender Code: `Sources/BirthdayWidget/BirthdayTimelineProvider.swift`
- Bestehender Code: `Sources/aiPresentsApp/Services/WidgetDataService.swift`
- WidgetKit Doku: Keeping a widget up to date — Apple Developer Documentation
- Forschungs-Erkenntnis: `BirthdayCalculator.nextBirthday()` existiert bereits und liefert das exakte `Date` — kein neuer Code nötig, nur Nutzung des bereits vorhandenen Rückgabewerts
