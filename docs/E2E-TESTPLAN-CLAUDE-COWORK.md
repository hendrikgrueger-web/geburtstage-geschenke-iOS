# E2E-Testplan für Claude Cowork (Computer Use)

> **Zweck:** Dieser Testplan ist für eine Claude-Cowork-Session gedacht, in der Claude
> per Computer Use die App `aiPresentsApp` im iOS Simulator selbständig durchklickt.
> Die App ist auf Deutsch — alle UI-Texte, Buttons und Screen-Titel unten sind
> wörtlich so im Simulator zu finden.

---

## 0. Setup vor Testbeginn

### 0.1 Simulator starten & App bauen

Im Terminal:

```bash
cd ~/Developer/geburtstage-geschenke-iOS    # oder Pfad zum Projekt
xcodebuild -project ai-presents-app-ios.xcodeproj -scheme aiPresentsApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
open -a Simulator
xcrun simctl boot "iPhone 17 Pro" 2>/dev/null || true
```

Anschließend in Xcode `aiPresentsApp` Scheme wählen und Run drücken
(Cmd+R), damit die App im Simulator startet.

### 0.2 Sauberer Ausgangszustand

**Vor jedem kompletten Testdurchlauf:**

1. Im Simulator: `Device > Erase All Content and Settings…`
   (oder via Terminal: `xcrun simctl erase "iPhone 17 Pro"`)
2. App neu installieren (Cmd+R in Xcode)
3. Auf dem ersten Launch wird das Onboarding gezeigt — das ist Teil von **TC-01**.

### 0.3 Demo-Daten (für Tests, die Personen brauchen)

Die App importiert Personen normalerweise aus Apple Contacts. Da der Simulator
leere Kontakte hat, gibt es eingebauten Seed-Code:

1. Settings öffnen (Tab/Toolbar-Button "Einstellungen")
2. Ganz nach unten scrollen → **"Dev Settings"** öffnen
3. Auf **"Demo-Daten erstellen"** tippen → Bestätigung abwarten
4. Zurück zur Timeline → mehrere Geburtstage sollten jetzt sichtbar sein.

> **Wenn "Dev Settings" nicht sichtbar ist:** Build-Variante ist nicht Debug.
> Dann manuell ein bis zwei Personen über "Kontakte importieren" anlegen
> (siehe TC-02). Im Simulator vorher unter `Contacts.app` 2–3 Testkontakte
> mit Geburtsdatum eintragen.

### 0.4 KI-Tests vorbereiten

Damit KI-Aufrufe (TC-06, TC-07, TC-08) tatsächlich Antworten liefern,
muss `App/Secrets.xcconfig` ein gültiges `AI_PROXY_SECRET` enthalten.
Ohne Secret kommt eine Fehlermeldung — den Fall ebenfalls protokollieren,
aber nicht als App-Bug bewerten.

---

## 1. Bekannte Einschränkungen für Computer Use

| Einschränkung | Auswirkung |
|---|---|
| Apple Kontakte im Simulator leer | Personen-Import (TC-02) braucht Demo-Daten oder vorher manuell angelegte Kontakte. |
| Push-Benachrichtigungen | Im Simulator nur eingeschränkt testbar — Erinnerungen-Toggle anlegen, aber nicht auf echtes Banner warten. |
| Face ID / Touch ID | Im Simulator über `Features > Face ID > Enrolled` und `Matching Face`. App-Lock-Test entsprechend simulieren. |
| iCloud Sync | Wirklicher Sync zwischen Geräten nicht testbar — nur Toggle und Persistenz nach App-Restart. |
| StoreKit / IAP | Paywall öffnet sich, Käufe nicht real ausführen. Nur UI-Verhalten testen. |

---

## 2. Reporting-Format

**Pro Testfall** ein Eintrag im finalen Bericht mit:

- **TC-ID + Titel**
- **Status:** ✅ bestanden | ⚠️ Auffällig | ❌ fehlgeschlagen
- **Beobachtung:** Was wurde tatsächlich gesehen?
- **Abweichung vom erwarteten Verhalten** (falls Status ≠ ✅)
- **Screenshot:** Pfad zur Screenshot-Datei (per `xcrun simctl io booted screenshot ~/Desktop/tc-XX.png`)
- **Reproduzierbar?** Ja/Nein/Manchmal
- **Schweregrad:** Kritisch / Hoch / Mittel / Niedrig / Kosmetik

Am Ende eine **Zusammenfassung** mit Anzahl bestanden/fehlgeschlagen
und einer Liste der Top-3-Probleme nach Schweregrad.

---

## 3. Testfälle

### TC-01 — Onboarding & First Launch

**Vorbedingung:** Frisch installierte App (Erase All Content vorher).

**Schritte:**
1. App starten.
2. Erster Onboarding-Screen sollte erscheinen (Welcome / Feature-Übersicht).
3. Durch alle Onboarding-Pages navigieren (Buttons "Weiter").
4. Auf dem iCloud-Screen die Option **"iCloud Sync aktivieren"** wählen.
5. Onboarding abschließen.

**Erwartet:**
- Alle Pages laden ohne Crash.
- Texte sind auf Deutsch und nicht abgeschnitten.
- Nach Abschluss landet man auf der Timeline mit Titel **"Geburtstage"**.
- Beim zweiten App-Start wird das Onboarding **nicht** erneut gezeigt.

**Negativfall:**
- Schritt 4 mit **"Nur lokal speichern"** wiederholen → Hinweis dass jederzeit änderbar.

---

### TC-02 — Timeline-Hauptansicht

**Vorbedingung:** Demo-Daten erstellt (siehe 0.3).

**Schritte:**
1. Auf der Timeline (Titel **"Geburtstage"**) prüfen, ob Geburtstage chronologisch sortiert sind.
2. "Heute"-Button (Pfeil-Icon in Toolbar) tippen → Liste springt zu heutigem Datum.
3. Filter-Icon tippen → Menü mit "Alle" und Beziehungstypen erscheint.
4. Eine Beziehung wählen → Liste filtert sich.
5. Auf "Alle" zurücksetzen.
6. Eine Geburtstagszeile antippen → Person-Detail öffnet sich (TC-03).
7. Auf der Timeline nach unten / oben scrollen.

**Erwartet:**
- Sortierung korrekt (nächster Geburtstag zuerst, vergangene optional je nach Toggle).
- Countdown-Badge "in X Tagen" / "heute" / "morgen" stimmt zum heutigen Datum (2026-05-01).
- Filter ändern die Liste sichtbar.
- Statistik-Banner oben (Übersicht) ist lesbar.

---

### TC-03 — Person-Detail

**Vorbedingung:** Mindestens eine Person vorhanden.

**Schritte:**
1. Person aus Timeline antippen.
2. Header-Section: Name, Avatar, Geburtsdatum, Beziehung sichtbar.
3. Section "Hobbies" prüfen → "+" tippen → Hobby eingeben → speichern → erscheint als Chip.
4. Hobby löschen (Wischen oder X auf Chip).
5. "Kontakt bearbeiten" oben rechts → Beziehung ändern → Speichern.

**Erwartet:**
- Änderungen bleiben nach Schließen + erneutem Öffnen erhalten.
- Keine Crashes beim Wechseln zwischen Sections.

---

### TC-04 — Geschenk-Idee anlegen, bearbeiten, löschen

**Vorbedingung:** Person-Detail offen.

**Schritte:**
1. Section "Geschenk-Ideen" → Plus-Button (oder "Idee hinzufügen") tippen.
2. Sheet **"Geschenk-Idee"** öffnet sich.
3. Felder ausfüllen: Titel = "Buch Mitten in Deutschland", Preis = 29,99, Notiz = "Beim Buchhändler", Tag-Auswahl prüfen.
4. Speichern.
5. Idee in Liste antippen → Sheet **"Idee bearbeiten"** → Status auf "geplant" / "gekauft" / "verschenkt" durchklicken.
6. Wischen zum Löschen einer Idee.

**Erwartet:**
- Pflichtfeld-Validierung (leerer Titel → Speichern deaktiviert).
- Währungsformat passt zur eingestellten Locale (EUR mit Komma).
- Status-Wechsel ändert Icon/Farbe in der Liste.
- Gelöschte Idee bleibt nach App-Neustart gelöscht.

---

### TC-05 — Geschenk-Historie

**Vorbedingung:** Person-Detail offen.

**Schritte:**
1. Section "Geschenk-Historie" → Plus-Button.
2. Im Sheet zwischen **"Geschenk vermerken"** (verschenkt) und **"Erhaltenes Geschenk"** wechseln.
3. Anlass auswählen (Geburtstag / Weihnachten / …), Jahr, Titel, Preis ausfüllen → speichern.
4. Eintrag antippen → Sheet **"Geschenk bearbeiten"** → Werte ändern → speichern.
5. Eintrag löschen.

**Erwartet:**
- Reihenfolge nach Jahr absteigend.
- Direction-Toggle (gegeben/erhalten) korrekt persistiert.
- Keine Doppel-Einträge nach mehrfachem Speichern.

---

### TC-06 — KI-Geschenkvorschläge (Consent + Antwort)

**Vorbedingung:** App nutzt KI noch nicht (Erstaufruf).

**Schritte:**
1. Auf Person-Detail oder Timeline-Kontextmenü → **"KI-Vorschläge"** tippen.
2. Erst-Aufruf: Sheet **"Datenschutz-Einwilligung"** muss erscheinen.
3. Text aufmerksam lesen, dann zustimmen.
4. Sheet **"KI-Geschenk-Ideen"** öffnet sich → Loading-Indikator → Vorschläge erscheinen.
5. Einen Vorschlag mit "Übernehmen" / Plus zur Ideenliste hinzufügen.
6. Sheet schließen, erneut öffnen → Consent-Sheet darf jetzt **nicht** mehr erscheinen.

**Erwartet:**
- Consent-Sheet listet exakt die übertragenen Felder (Vorname, Altersgruppe, Relation, Sternzeichen, Hobbies, Budget) und die NICHT übertragenen Felder (Nachname, exaktes Geburtsdatum, Notizen).
- Vorschläge auf Deutsch, sinnvolle Inhalte (keine Lorem-Ipsum, keine englischen Halluzinationen wenn Locale=de).
- Übernommene Vorschläge erscheinen sofort in der Geschenk-Ideen-Liste.
- Bei Netzfehler / fehlendem Secret: klare Fehlermeldung mit "Erneut versuchen".

---

### TC-07 — KI-Chat

**Vorbedingung:** Consent v2 erteilt (TC-06).

**Schritte:**
1. Suchleiste oben in Timeline tippen oder KI-Assistent-Eintrag → Sheet **"KI-Assistent"** öffnet sich.
2. Frage tippen: *"Was schenke ich meiner Schwester zum 40."*
3. Senden.
4. Antwort abwarten, dann Folgefrage stellen: *"Geht das auch günstiger?"*
5. Chat schließen, später wieder öffnen → Verlauf prüfen (je nach Implementierung persistiert oder nicht).

**Erwartet:**
- Typing-Indicator erscheint während der Antwort.
- Bubbles korrekt links/rechts (User vs. KI).
- Folgefrage berücksichtigt Kontext.
- Keine personenbezogenen Daten ohne Bezug in Prompt sichtbar.

---

### TC-08 — KI-Geburtstagsnachricht

**Schritte:**
1. Person-Detail → Aktion **"Geburtstagsnachricht"** (Sparkles-Icon).
2. Sheet **"Geburtstagsnachricht"** öffnet sich → Tonalität wählen (z.B. herzlich/lustig).
3. Generieren.
4. Antwort kopieren.

**Erwartet:**
- Generierter Text passt zur Person (Vorname, Beziehung).
- Kopieren legt Text in die Zwischenablage.
- Mehrfaches Generieren liefert variierende Ergebnisse.

---

### TC-09 — Suche in Timeline

**Schritte:**
1. Auf der Timeline die Such-/KI-Leiste **"Suche oder frag die KI…"** tippen.
2. Vornamen einer existierenden Person tippen.
3. Liste filtert auf Treffer.
4. Suchtext löschen → vollständige Liste zurück.
5. Sehr seltenen String eingeben → Empty-State.

**Erwartet:**
- Filterung schon ab erstem Buchstaben.
- Empty-State mit Hinweistext.
- Kein Lag bei vielen Personen.

---

### TC-10 — Erinnerungs-Einstellungen

**Schritte:**
1. Settings → **"Benachrichtigungen"** → Toggle "Erinnerungen aktivieren" einschalten.
2. iOS fragt nach Berechtigung → erlauben.
3. Eintrag **"Erinnerungseinstellungen"** öffnen → Vorlauf einstellen (z.B. 1 Tag vorher, 09:00 Uhr).
4. Speichern, zurück.
5. **"Erinnerungen neu laden"** tippen.
6. Toggle wieder ausschalten → Bestätigung.

**Erwartet:**
- Bei abgelehnter Berechtigung: klarer Hinweis und Link zu iOS-Einstellungen.
- Eingestellte Zeit bleibt nach App-Neustart erhalten.

---

### TC-11 — Währung wählen

**Schritte:**
1. Settings → **"Darstellung"** → "Währung" antippen → **CurrencyPickerView** öffnet sich.
2. Andere Währung wählen (z.B. CHF).
3. Zurück → in Settings die Anzeige prüfen.
4. Eine Geschenk-Idee öffnen → Preis sollte in CHF formatiert sein.
5. Auf "Automatisch" zurücksetzen.

**Erwartet:**
- Währungsumstellung wirkt sofort, kein App-Restart nötig.

---

### TC-12 — App-Lock (Face ID / Touch ID)

**Vorbedingung:** Im Simulator Face ID enrolled.

**Schritte:**
1. Settings → "Sicherheit" → Toggle **"App-Lock"** einschalten.
2. App in den Hintergrund schicken (Home-Geste).
3. App wieder öffnen → Face-ID-Prompt sollte erscheinen.
4. Im Simulator: `Features > Face ID > Matching Face` → entsperrt.
5. Erneut Hintergrund → `Non-matching Face` → bleibt gesperrt.
6. Toggle ausschalten → keine Sperre mehr.

**Erwartet:**
- Lock-Screen blockiert Inhalte (kein Leak bei App-Switcher-Vorschau).
- Fehlversuch → "Erneut versuchen"-Button.

---

### TC-13 — Datenschutz / AGB / Impressum

**Schritte:**
1. Settings → "Datenschutz" tippen → PrivacyView öffnet sich, Text scrollbar.
2. Zurück → "Nutzungsbedingungen" → TermsView.
3. Zurück → "Impressum" → LegalView.

**Erwartet:**
- Texte vollständig auf Deutsch, keine Platzhalter, kein "Lorem".
- Kontaktdaten und Datum sichtbar.

---

### TC-14 — KI-Einwilligung widerrufen

**Schritte:**
1. Settings → KI-Bereich → Toggle **"KI-Vorschläge aktiviert"** ausschalten → Bestätigungsdialog.
2. Bestätigen.
3. KI-Funktion erneut aufrufen (TC-06) → Consent-Sheet muss wieder erscheinen.

**Erwartet:**
- Toggle-Änderung persistent.
- Beim Wieder-Einschalten erneuter Consent-Flow.

---

### TC-15 — iCloud-Sync-Toggle

**Schritte:**
1. Settings → "iCloud Sync" Toggle umlegen.
2. Hinweis "Die Änderung wird beim nächsten App-Start wirksam." sollte erscheinen.
3. App komplett beenden (Swipe-up, App schließen) → neu starten.
4. Daten weiter vorhanden, Toggle-Zustand persistiert.

**Erwartet:**
- Kein Datenverlust beim Umschalten.
- Hinweistext sichtbar.

---

### TC-16 — Paywall / Premium

**Schritte:**
1. Aktion auslösen, die Premium erfordert (z.B. mehr als die Free-Quote KI-Aufrufe oder bestimmte Features — exakter Trigger ist im aktuellen Build zu beobachten).
2. PaywallView (Titel **"Premium"**) öffnet sich.
3. Beide Optionen (Monatlich / Jährlich) sichtbar, Preise lesbar.
4. "Wiederherstellen"-Button antippen → Loading, dann Resultat.
5. Schließen ohne Kauf → App bleibt im Free-Modus.

**Erwartet:**
- Keine echten Käufe ausgeführt.
- "Wiederherstellen" zeigt sinnvollen Status auch ohne Account.
- Gestaltung pixelgenau (keine Überlappungen auf iPhone 17 Pro).

---

### TC-17 — Alle Daten löschen

**Schritte:**
1. Settings → ganz unten "Alle Daten löschen" (rote Aktion).
2. Bestätigungsdialog mit Hinweis dass Kontakte/Kalender unberührt bleiben.
3. Bestätigen.
4. Timeline ist leer, Person-Detail nicht mehr erreichbar.

**Erwartet:**
- Wirklich alle Personen, Ideen, Historie gelöscht.
- Onboarding wird **nicht** wieder gezeigt (Settings != First-Launch-Reset).
- Apple Contacts/Kalender unberührt.

---

### TC-18 — iPad-Layout & Orientierung (optional)

**Vorbedingung:** Simulator iPad Pro 13" (M5).

**Schritte:**
1. Build mit iPad-Destination, App starten.
2. NavigationSplitView: links Timeline, rechts Detail.
3. Gerät rotieren: Portrait, Landscape Left, Landscape Right, Upside-Down.
4. Bei jeder Orientierung Person öffnen, Sheet öffnen, KI starten.

**Erwartet:**
- Kein Layout-Bruch, keine abgeschnittenen Elemente.
- Sheets als Form-Sheet mittig, nicht Vollbild.
- Split-View funktioniert auch im Querformat geteilt mit anderer App (Slide Over).

---

## 4. Smoke-Reihenfolge (wenn nur 30 Min Zeit)

Wenn nicht alles möglich ist, in dieser Reihenfolge: **TC-01 → TC-02 → TC-04 → TC-06 → TC-09 → TC-10 → TC-17**.

Das deckt: First Launch, Hauptliste, CRUD, KI mit Consent, Suche, Erinnerungen, Daten löschen.

---

## 5. Bekannte offene Punkte (NICHT als Bug melden)

Aus dem Backlog in `CLAUDE.md`:

- Custom RelationOptions werden noch nicht über iCloud synchronisiert.
- Vordefinierte Beziehungstypen sind in der DB auf Deutsch (Migration steht aus).
- Loading/Error-States in AI-Sheets sind dupliziert — kosmetisch.
- TypingIndicator-Avatar noch nicht in eigene View ausgelagert.
- `ReminderManager.swift:11` `nonisolated(unsafe)` Warning ist bewusst und unvermeidbar.

---

## 6. Abschluss-Bericht (Template)

```
# E2E-Testbericht — <Datum> — Build <Version (Build)>

## Zusammenfassung
- Bestanden: X/18
- Auffällig:  Y
- Fehlgeschlagen: Z

## Top-Probleme
1. [Schweregrad] TC-XX — Kurzbeschreibung — Screenshot: ...
2. ...

## Detailergebnisse
### TC-01 — Onboarding
Status: ✅
Beobachtung: ...

### TC-02 — Timeline
Status: ⚠️
Beobachtung: ...
Abweichung: ...
Screenshot: ~/Desktop/tc-02.png
```
