---
title: "feat: Top-5 Review-Verbesserungen → v1.0.7"
type: feat
status: planned
date: 2026-05-01
---

# Top-5 Review-Verbesserungen → v1.0.7

## Overview

Fünf gezielte Verbesserungen, abgeleitet aus einem strukturierten internen App-Review (Magazin-Tester-Perspektive + Erstnutzer-24h-Test), die zusammen als **Version 1.0.7** released werden. Schwerpunkt: User-Reise glätten, Daten-Hygiene nachziehen und Marketing-Versprechen mit App-Inhalt synchronisieren.

Erwartete Wirkung: App-Store-Wertung steigt von „solide 7/10" auf „klare 8/10". Erstnutzer-Friction-Punkte (Permission-Pyramide, Stats-Row, fehlendes Backup) werden adressiert.

## Problem Frame

Aus dem Review herausgearbeitete Reibungspunkte:

1. **Stats-Row beantwortet die falsche Frage.** Aktuell: „Kontakte / Diese Woche / Ideen". Erstnutzer öffnet die App um zu wissen *was heute ansteht* — sieht aber Kontaktanzahl. UX-Anti-Pattern.
2. **App-Store-Subtitle und -Description** stellen die KI in den Vordergrund, obwohl das Erinnerungs-Feature der eigentliche tägliche Wert ist. Conversion-Verlust auf der Listing-Seite, weil das Versprechen schwächer wirkt als der App-Inhalt.
3. **Permission-Pyramide:** Onboarding → Kontakte → Notifications → (im KI-Chat) Speech → Mic → AI-Consent. Bis zu 5 Modal-Dialoge in den ersten 10 Minuten. Apple-HIG-Anti-Pattern.
4. **Kein Daten-Export / -Backup.** iCloud-Sync ist kein Backup (Bug-Korruption wird mit-gesynced). Bei einer Daten-App ein Hygiene-Mangel und Trust-Lücke gegenüber Reviewern.
5. **Geschenkideen ohne Foto/Link.** „Kindle Paperwhite, 169 €" ist ohne Bild + URL halb so brauchbar wie es sein könnte. Schwächt das eigentliche USP-Feature (KI-Vorschläge).

Plus zwei kleinere Punkte, die als „Sweep" mitgenommen werden:
- Hauptansicht-Empty-State an Tagen ohne Anlass: zu still, kein Reassurance-Text
- Geschenk-Detail-Ansicht: 2-3 Klicks bis Kauf-Markierung (Affordance schlecht)

## Scope Boundaries

**Drin in v1.0.7:**
- Die 5 Top-Verbesserungen + 2 Sweep-Items (Empty-State, Kauf-Markierung näher an die Oberfläche)
- ASC-Listing-Update (Subtitle + Description in 7 Locales)
- Version-Bump 1.0.6 → 1.0.7, Build-Nummer-Bump
- Release-Notes-Markdown in `docs/WHATS-NEW-1.0.7.md`

**Raus aus v1.0.7 (Backlog):**
- Premium-Subscription-Reaktivierung (separates Plan-Dokument)
- Subscription-Promo-Bilder + EULA-Link (eigener Plan, weil ASC-Metadaten-Heavy)
- App-Name-Änderung (Marketing-Entscheidung mit Hendrik separat)
- Cross-Platform / Android (out of scope für eine Punktrelease)
- Watch-Companion-App
- Geschenkideen-Sharing zwischen Kontakten

## Key Technical Decisions

- **Stats-Row:** Komplett neu denken statt nur umbenennen. Drei Zähler bleiben, aber jeder beantwortet jetzt eine konkrete „was-mache-ich-heute"-Frage. Tap auf jeden Zähler scrollt/filtert die Liste — kein Dead-End mehr.
- **Permission-Bündelung:** Eigene neue Onboarding-Seite (Slide 5 vor iCloud-Slide) mit klarer Begründung pro Permission, sequenziell gefeuert beim Antippen — *nicht* eine Sammel-Permission (gibt's bei iOS nicht), aber eine kontrollierte Sequenz mit Erklärung. KI-Permissions bleiben *just-in-time* (nur wenn der Nutzer den KI-Chat tatsächlich öffnet).
- **Daten-Export:** Format JSON (nicht CSV), weil Geschenkideen verschachtelt sind. Über `UIActivityViewController` ins Share-Sheet → User wählt iCloud Drive / Mail / AirDrop. **Kein Auto-Backup** in v1.0.7 (separater Plan, weil Scheduling + Versionierung Komplexität bringt).
- **Geschenk-Bild:** CloudKit-Asset-Field am `GiftIdea`-Model (nicht in SwiftData lokale Blob, weil Sync-relevant). URL als simpler `String?`. Bilder werden als Thumbnail mit `AsyncImage` gerendert, on-demand geladen + 50-Item-LRU-Cache.
- **ASC-Listing-Update:** Per `asc localizations update --description` und `asc apps info edit --subtitle` für alle 7 Locales. Texte vorher in Markdown im Repo, dann CLI-batch deploy. Geht ohne neuen Build durch — Listing-Änderungen sind separat reviewbar.

## Implementation Units

### Unit 1: Stats-Row umbauen — „was steht an?"

**Goal:** Hauptansicht beantwortet die erste Frage des Nutzers direkt.

**Files:**
- Modify: `Sources/aiPresentsApp/Views/Timeline/TimelineView.swift` (statsRow + birthdaysThisWeek)
- Modify: `Tests/aiPresentsAppTests/Views/TimelineViewTests.swift` (falls vorhanden, sonst skip)

**Approach:**
- Drei neue Zähler: **Heute** (alle Geburtstage mit `daysUntil == 0`), **Diese Woche** (1–7), **Diesen Monat** (8–30).
- `birthdaysThisWeek` umbenennen zu `birthdaysToday` / `birthdaysThisWeek` / `birthdaysThisMonth` (drei Computed Properties).
- Visuell: Wenn ein Zähler > 0, in Akzentfarbe; sonst grau.
- Zähler tap-bar machen: setzt `filterRelation = nil` und scrollt auf den ersten Eintrag des jeweiligen Zeitfensters (`ScrollViewReader.scrollTo(person.id)`). Die bestehenden Section-Header in der Liste reichen als Anker.
- Empty-State der App (keine Geburtstage in den nächsten 30 Tagen) bekommt eine Reassurance-Zeile: „Nächster Geburtstag: [Name] in [X] Tagen."

**Test Plan:**
- Unit: Computed Properties `birthdaysToday/ThisWeek/ThisMonth` mit Demo-Daten verifizieren (Zeitzone-bewusst, mit `BirthdayCalculator`-Helper, der schon getestet ist).
- Visual: Snapshot-Tests aktualisieren, falls vorhanden.
- Manuell: Mit `SampleDataService`-Demo-Set öffnen, alle drei Zähler-Werte gegen Hand-Berechnung prüfen.

**Risk:** Niedrig. Reine View-Änderung, keine Daten-Migration. Gefahr: Tap-Scroll-Verhalten kann auf iPad mit zwei Spalten anders sein → mit `horizontalSizeClass` differenzieren.

**Aufwand:** ~30–45 Min.

---

### Unit 2: ASC-Listing — Subtitle + Description neu

**Goal:** Marketing-Versprechen entspricht App-Inhalt. Erinnern → KI als Unterstützung, nicht andersrum.

**Files:**
- Modify: `docs/APP-STORE-LISTING.md` (DE/EN als Quelle)
- Add: `docs/APP-STORE-LISTING-1.0.7.md` (versioniertes Update, alle 7 Locales)

**Neuer Subtitle (max 30 Zeichen):**
- DE: „Nie einen Geburtstag vergessen" (28 Zeichen) — fokussiert die tägliche Nutzung
- EN: „Never forget a birthday again" (29) / EN-GB identisch
- FR: „Ne plus oublier d'anniversaire" (30) / FR-CA identisch
- ES: „No olvides ningún cumpleaños" (28) / ES-MX identisch

**Neue Description-Reihenfolge:**
1. Hook (1 Satz): „Du vergisst keinen Geburtstag mehr. Und nie wieder die passende Geschenkidee."
2. Block „NIE WIEDER VERGESSEN" (Erinnern, Widget, Timeline) — vorher Block 2, jetzt Block 1
3. Block „GESCHENKE PERFEKT ORGANISIERT" (Ideen, Historie, Budget) — vorher Block 3, jetzt Block 2
4. Block „DEIN KI-GESCHENKEBERATER" (KI-Chat, Sprachvorschläge) — vorher Block 1, jetzt Block 3
5. Block „100% DEINE DATEN" (Privacy) — bleibt am Ende
6. CTA-Satz unverändert

**Approach:**
- Plain-Text-Versionen pro Locale in `docs/APP-STORE-LISTING-1.0.7.md` schreiben
- Per CLI deployen:
  ```bash
  asc localizations update --version <id> --locale de-DE --description "$(...)"
  asc apps info edit --app 6760319397 --locale de-DE --subtitle "Nie einen Geburtstag vergessen"
  ```
  (für alle 7 Locales — Subtitle und Description können in *bestehender* Version 1.0.6 schon aktualisiert werden, gehen ohne neuen Build durch)

**Test Plan:**
- Längen-Check: Jeden Subtitle gegen 30-Zeichen-Limit, jede Description gegen 4000-Zeichen-Limit
- ASC-Preflight: `asc submit preflight --app 6760319397 --version 1.0.6` muss weiterhin 7/7 passen
- Manuell: Listing in ASC-Browser-Vorschau ansehen, ob Übergangs/Umlaute korrekt rendern

**Risk:** Sehr niedrig. ASC-Listing-Änderungen sind reversibel und benötigen keinen neuen Build.

**Aufwand:** ~45 Min (inkl. saubere Übersetzungen für 7 Locales).

---

### Unit 3: Permission-Bündelung im Onboarding

**Goal:** Erstnutzer kommt in <2 Min ohne Permission-Frust zur Hauptansicht.

**Files:**
- Modify: `Sources/aiPresentsApp/Views/Onboarding/OnboardingView.swift`
- Add: `Sources/aiPresentsApp/Views/Onboarding/PermissionsOnboardingPage.swift` (neue Slide)
- Modify: `Sources/aiPresentsApp/Services/ContactsService.swift` (Reihenfolge der Permission-Anfragen)
- Modify: `Sources/aiPresentsApp/Services/NotificationService.swift` (Reihenfolge)

**Approach:**
- **Neue Slide nach den 4 Inhalts-Slides, vor der iCloud-Slide:** „App einrichten — 2 Berechtigungen"
- Liste mit zwei Zeilen, je mit Icon + Begründung + Button:
  1. **Kontakte** — „Damit ich die Geburtstage nicht abtippen muss." → Button „Erlauben" → `CNContactStore.requestAccess`
  2. **Erinnerungen** — „Damit ich Dich rechtzeitig anstupse." → Button „Erlauben" → `UNUserNotificationCenter.requestAuthorization`
- Jede Zeile zeigt nach erfolgreichem Grant einen grünen Haken, bei Decline ein „Einstellungen → später ändern"-Link
- Beide optional — Weiter-Button wird nicht gegated
- KI-Permissions (Speech + Mic) **bleiben just-in-time** beim ersten Mic-Tap im Chat, das ist HIG-konform und reduziert Onboarding-Last
- AI-Consent-Sheet bleibt beim ersten KI-Chat-Öffnen (Pflicht für DSGVO)

**Test Plan:**
- UI-Test: Onboarding-Flow von Slide 1 bis Hauptansicht durchklicken — beide Permissions explizit grant + decline durchspielen
- Edge-Case: Was wenn User Notifications declined, dann später Geburtstag-Reminder anlegt? → Bestehender Code muss `UNUserNotificationCenter.notificationSettings.authorizationStatus` prüfen und Fallback (nur In-App-Reminder) anbieten
- Manuell: Frischer Simulator-Reset, Erstinstall, Time-to-First-Birthday-Visible messen (Ziel: <90 sec)

**Risk:** Mittel. Permission-State ist `actor`-isoliert und das Permission-Sheet kann während des Wartens vom System eingefroren werden. Zeitliche Race-Conditions möglich. Bestehende Notification-Service-Logik nicht zerschießen — Branch-Isolation einhalten.

**Aufwand:** ~2–3 h (Code + neuer UI-Slide + Tests).

---

### Unit 4: Daten-Export als JSON

**Goal:** Trust-Signal + Recovery-Option für Bug-Korruption (Hauptmotivation aus iCloud-Sync-vs-Backup-Diskussion am 2026-04-30).

**Files:**
- Add: `Sources/aiPresentsApp/Services/DataExportService.swift`
- Modify: `Sources/aiPresentsApp/Views/Settings/SettingsView.swift` (neuer „Daten exportieren"-Block)
- Add: `Tests/aiPresentsAppTests/Services/DataExportServiceTests.swift`

**Approach:**
- `DataExportService.exportAll(modelContext) -> URL` (gibt Pfad zur temp .json-Datei zurück)
- JSON-Schema (versioniert, damit Restore später möglich ist):
  ```json
  {
    "version": 1,
    "exported_at": "2026-05-01T12:00:00Z",
    "app_version": "1.0.7",
    "people": [
      {
        "id": "uuid",
        "displayName": "...",
        "birthday": "2000-04-12",
        "birthYearKnown": true,
        "relation": "Bruder",
        "hobbies": [...],
        "skipGift": false
      }
    ],
    "gift_ideas": [
      {
        "id": "uuid",
        "person_id": "uuid",
        "title": "Kindle Paperwhite",
        "budget_cents": 16900,
        "currency": "EUR",
        "status": "planned",
        "purchased_at": null,
        "image_url": null,
        "product_url": null
      }
    ],
    "gift_history": [...]
  }
  ```
- Settings → Sektion „Daten" → Button „Alle Daten exportieren" → ruft `exportAll` auf, öffnet `UIActivityViewController` mit dem JSON-File
- File-Name: `geburtstage-export-YYYY-MM-DD.json`
- Sensitive Felder (Notizen) **werden mit-exportiert**, weil das ja Hendriks eigene Daten sind und das Backup-Use-Case voll-restorbar sein muss
- Datei wird nach Share-Sheet-Dismiss aus Temp gelöscht (nicht nötig, iOS räumt eh auf, aber sauber)

**Test Plan:**
- Unit: Mit Demo-Daten exportieren, JSON parsen, Round-Trip prüfen (alle Personen-Anzahlen + Gift-Ideen-Anzahlen identisch)
- Unit: Encoding für Edge-Cases (Umlaute, Emoji in Hobbies, sehr lange Notizen)
- Manuell: Export → AirDrop auf Mac → JSON öffnen → visuell prüfen
- Manuell: Export bei leeren Daten (Nutzer ohne Kontakte) → kein Crash, valides leeres JSON

**Risk:** Niedrig. Read-Only-Operation, keine SwiftData-Mutation. Gefahr: Bei Großen Datenbanken (>500 Personen) kann der Export-Prozess kurz blockieren — `Task.detached(priority: .userInitiated)` + Spinner-Overlay.

**Aufwand:** ~90 Min.

---

### Unit 5: Geschenkidee mit Bild + URL

**Goal:** KI-Vorschlag „Kindle Paperwhite, 169 €" wird zu einem speicherbaren Item mit Produktbild und Direkt-Link.

**Files:**
- Modify: `Sources/aiPresentsApp/Models/GiftIdea.swift` (neue Felder)
- Modify: `Sources/aiPresentsApp/Views/Person/PersonDetailGiftIdeasSection.swift` (Anzeige)
- Modify: `Sources/aiPresentsApp/Views/Gift/AddGiftHistorySheet.swift` + `EditGiftHistorySheet.swift` (Eingabe)
- Add: `Sources/aiPresentsApp/Services/GiftImageService.swift` (Cache + Async-Load)
- Add: SwiftData-Migration in `aiPresentsApp.swift` (ModelContainer)

**Approach:**
- Neue Felder am `GiftIdea`-Model:
  - `productURL: String?` — direkt eintragbar
  - `imageData: Data?` — kleines Thumbnail (max 512×512, JPEG 80% Qualität → ~30-80 KB)
  - **NICHT** als CloudKit-Asset — bleibt im SwiftData-Record, wird damit auch via CloudKit gesynced (CloudKit-Limit: 1MB/Record, wir bleiben weit drunter)
- `AddGiftHistorySheet` erweitern um:
  - Text-Field „Link / URL"
  - Button „Bild hinzufügen" → `PHPickerViewController` (Photos) oder `UIImagePickerController` (Kamera) — Standard-iOS-Pattern
  - Bild wird sofort auf 512×512 gedownsampled mit `ImageRenderer` oder `CGImageSourceCreateThumbnail`
- KI-Chat-Vorschlag: „Speichern"-Button speichert ohne Bild/URL (User kann später ergänzen). KI-Vorschläge mit URL (wenn die KI eine Amazon/Otto-URL liefert) werden direkt mit-gespeichert, das Bild wird via OpenGraph-Scrape **NICHT** automatisch geladen (Privacy: kein zusätzlicher externer Request).
- Anzeige in der Liste: 44×44 Thumbnail links neben dem Title, sonst Default-Geschenk-Icon

**Test Plan:**
- Unit: Image-Downsampling-Service mit verschiedenen Source-Sizes (1×1, 4096×4096, sehr breit, sehr hoch)
- Migration-Test: SwiftData mit alten Records (ohne neue Felder) öffnen → keine Crashes, neue Felder = nil
- Manuell: 5 Geschenkideen mit Bildern → CloudKit-Sync auf zweites Gerät testen (Bilder müssen erscheinen)
- Performance: Liste mit 100 Ideen, alle mit Bild → Scroll bleibt unter 60fps drop

**Risk:** Mittel-hoch. SwiftData-Migration immer Risiko, plus CloudKit-Sync mit neuen Feldern testen. Plan B: Wenn Migration scheitert, neue Felder optional und mit `nil`-Fallback.

**Aufwand:** ~3–4 h (Datenmodell + UI + Cache + Tests).

---

### Sweep-Items (klein, parallel zu Unit 1–5)

**S1: Empty-State-Reassurance auf Hauptansicht**
- In `TimelineView.emptyStateView`: wenn `people.count > 0` aber `birthdaysThisMonth == 0`: Text „Aktuell keine Geburtstage in den nächsten 30 Tagen. Der nächste am [Datum] — [Name]."
- Aufwand: 15 Min.

**S2: Kauf-Markierung näher an die Oberfläche**
- In `PersonDetailGiftIdeasSection` jeder Idee-Row eine Swipe-Action „Gekauft" hinzufügen (links statt nur via Detail-Tap)
- Aufwand: 20 Min.

## Sequenz & Reihenfolge

| # | Unit | Ablage | Frühestens | Frühester Test |
|---|---|---|---|---|
| 1 | Unit 2 — ASC-Listing | direkt deploybar (ohne Build) | sofort | A/B-Conversion-Vergleich nach 7 Tagen |
| 2 | Unit 1 — Stats-Row | trivial, baut auf TimelineView auf | als erste Code-Änderung | Build 1.0.7-alpha auf Hendriks Gerät |
| 3 | S1 + S2 (Sweep) | mit Unit 1 mitnehmen | dito | dito |
| 4 | Unit 4 — Daten-Export | unabhängig, eigener Service | parallel zu 1 möglich | manuell ausprobieren |
| 5 | Unit 3 — Permissions | berührt Onboarding | nach 1+4, eigener Commit | TestFlight, frischer Simulator |
| 6 | Unit 5 — Bild + URL | SwiftData-Migration, eigener Commit | als letztes vor Submit | TestFlight Internal-Group |

**Begründung:** ASC-Listing zuerst, weil deploybar ohne Build → sofortige Marketing-Wirkung. Stats-Row zweitens, weil triviale UI-Änderung mit größtem täglichen UX-Impact. Daten-Export drittens, weil unabhängig und ein klarer Trust-Signal. Permissions viertens, weil Onboarding-flow-relevant und mehr Test-Aufwand. Bild + URL als letztes, weil SwiftData-Migration das größte Stabilitäts-Risiko ist.

## Testing Strategy

**Pro Commit:**
- `xcodebuild -scheme aiPresentsApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` — null Errors
- Bestehende 1148 Tests müssen weiterhin grün laufen (keine Regression)

**Vor Release-Submit:**
- Frischer Simulator-Reset, Onboarding-First-Run-Test (Time-to-First-Value < 90 sec)
- Bestehender Test-Run gegen iCloud-Container (auf zweitem Device verifizieren)
- iPad-Snapshot (NavigationSplitView mit zwei Spalten)

**Build-Pipeline:**
- TestFlight-Build via push auf main
- App-Store-Build via `asc xcode-cloud run --workflow-id 27f2efdf-...`
- ASC-Submit via Standard-Auto-Pfad aus globaler CLAUDE.md (Version, Localizations, Attach, Validate, Submit)

## Release Plan

**Versionierung:** 1.0.6 → **1.0.7** (Build wird von Xcode Cloud auto-vergeben, war zuletzt 158 → erwartet ≥ 159).

**Release-Notes (`docs/WHATS-NEW-1.0.7.md`):** Sieben Locales (DE/EN-US/EN-GB/FR-FR/FR-CA/ES-ES/ES-MX), kompakt:

> *Diese Version ist bedienfreundlicher und sicherer:*
> - *Die neue Heute/Diese-Woche/Monat-Ansicht zeigt sofort, was ansteht.*
> - *Geschenkideen kannst Du jetzt mit Bild und Link speichern.*
> - *Beim Einrichten gibt es einen klaren Permission-Schritt — keine versteckten Dialoge mehr.*
> - *Alle Daten als JSON exportieren — perfekt als Backup.*

**Submission-Checks:**
- `asc submit preflight` muss 7/7 passen
- `asc validate --strict` muss 0 Errors haben (Warnings für Subscriptions akzeptiert, weil out-of-scope)

**Rollout-Strategie:** Phased Release ON, 1 % am ersten Tag → langsam hochschrauben. Bei einem Crash-Spike in den ersten 24 h sofort `asc versions phased-release pause`.

## Open Questions

1. **App-Name-Diskussion** (aus dem Review als Marketing-Punkt aufgekommen): brauchen wir die nochmal als eigenen Plan, oder bleibt der Name absichtlich generisch (Hendriks Memory: „App-Name bewusst gewählt, NICHT ändern")?
2. **Geschenk-Bilder via OpenGraph-Auto-Fetch** (aus URL automatisch Bild ziehen): aktuell aus Privacy-Gründen NICHT geplant — wenn Du das doch willst, eigener Plan mit Privacy-Abwägung (zusätzlicher Outbound-Request pro URL).
3. **Auto-Backup wöchentlich in iCloud Drive**: Liegt im Backlog (separater Plan) — aktuell nur Manual-Export. OK so?

## Verification

Plan ist fertig wenn:
- [ ] Alle 5 Units committed + gepusht
- [ ] Sweep-Items (S1, S2) committed
- [ ] `docs/WHATS-NEW-1.0.7.md` geschrieben
- [ ] TestFlight-Build SUCCEEDED
- [ ] App-Store-Build SUCCEEDED
- [ ] `asc validate` 0 Errors
- [ ] `asc submit create` durchgelaufen, Submission-ID festgehalten
- [ ] Memory-Eintrag `release_1.0.7_YYYY-MM-DD.md` mit Submission-ID
