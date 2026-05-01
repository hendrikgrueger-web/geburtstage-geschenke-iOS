# Plan: Startseite Redesign

## Ziel

Startseite nach Apple HIG vereinfachen:
- Nächste Geburtstage prominent oben (Hero-Karussell)
- "Noch ohne Geschenk" als Call-to-Action
- Vollständige Liste unten
- Alles Überflüssige raus

---

## Neue Struktur

```
NavigationBar: "Geburtstage"                    [+]
────────────────────────────────────────────────────
[Hero-Karussell: nächste 3 Geburtstage]
  ┌──────────────────────────────────────────┐
  │  👤  Max Mustermann                      │
  │      🎉 Heute wird 32!                   │
  │      💡 3 Ideen                          │
  └──────────────────────────────────────────┘
                ● ○ ○
────────────────────────────────────────────────────
Noch ohne Geschenk
  [E]  [H]  [A]  [P]  →  (horizontal scroll)
────────────────────────────────────────────────────
Alle Geburtstage
  Erika Muster      In 2 Tagen      >
  Hans Müller       In 5 Tagen      >
  Anna Schmidt      In 7 Tagen      >
  ...
```

---

## Änderungen

### 1. Neues Widget: `UpcomingBirthdayHero`

**Datei:** `Sources/aiPresentsApp/Widgets/BirthdayWidgetView.swift` umbenennen/ersetzen durch `UpcomingBirthdayHero.swift`

- `@Query private var allPeople: [PersonRef]` (bereits umgebaut ✓)
- Zeigt immer die nächsten **3** Geburtstage (kein Limit auf 14 Tage — einfach die nächsten 3, egal wie weit)
- **`TabView(selection:) { ... }.tabViewStyle(.page(indexDisplayMode: .automatic))`** — natives iOS Paging mit Page-Dots
- Page-Dots nur sichtbar wenn ≥ 2 Einträge
- Kein `.onAppear`-Fetch, kein `BirthdayWidgetData`

**Karten-Inhalt (minimal):**
- `PersonAvatar` (50pt)
- Name (`headline`)
- Altersinfo + Countdown (`subheadline`, AppColor.primary bei heute/morgen)
- Geschenkideen-Count als kleiner Chip — nur wenn `giftIdeas?.count ?? 0 > 0`
- Tap → `NavigationLink` zu `PersonDetailView`

**Hintergrund:** Gradient aus `AppColor.gradientForRelation(person.relation).opacity(0.12)`, cornerRadius 16

### 2. `TimelineView.swift` — Aufräumen

**Entfernen:**
- `@State private var selectedTab` + `TimelineTab` enum + `Picker` (Segmented Control)
- `QuickStatsView()` — komplett raus
- `filteredBirthdays` Tab-Logik vereinfachen → nur noch chronologisch alle (kein Tab-Filter)
- `emptyStateMessage` switch über Tabs → nur noch generischer Text

**Behalten:**
- Suchfeld (weiterhin nützlich)
- Filter-Menü (Toolbar, Hat Ideen / Ohne Ideen / Beziehung)
- `NochOhneGeschenkSection`
- `BirthdayWidgetView` → ersetzt durch `UpcomingBirthdayHero`
- Geburtstagsliste (alle, chronologisch, kein Zeitlimit)

**Neue `filteredBirthdays`-Logik:**
```swift
// Keine Tab-Filterung mehr — alle Personen, sortiert nach nächstem Geburtstag
// Nur Suche + filterHasIdeas + filterRelation bleiben aktiv
```

### 3. `QuickStatsView` — entfernen aus TimelineView

`QuickStatsView.swift` bleibt als Datei erhalten (könnte in Settings nützlich sein), wird aber nicht mehr in `TimelineView` eingebunden.

---

## Nicht geändert

- `NochOhneGeschenkSection.swift` — unverändert
- `PersonDetailView`, `BirthdayRow`, alle anderen Views
- `BirthdayWidgetData.swift` — bleibt als Utility

---

## Verifikation

1. App starten → Hero zeigt sofort nächste 3 Geburtstage
2. Swipe im Hero → zweite/dritte Karte erscheint, Page-Dot wechselt
3. "Noch ohne Geschenk" zeigt Personen ohne Ideen mit Countdown
4. Liste zeigt alle Personen chronologisch (nicht mehr auf 7/30 Tage begrenzt)
5. Suche funktioniert noch
6. Filter-Menü (Toolbar) funktioniert noch
7. Kein Segmented Control sichtbar
8. Keine QuickStats sichtbar
