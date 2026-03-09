# Beta Tester Guide

> Willkommen bei aiPresents Beta! Danke für deine Unterstützung beim Testen.

---

## Was ist aiPresents?

aiPresents ist eine iOS App, die dir hilft:
- **Geburtstage zu überblicken** – Timeline mit heutigen und kommenden Geburtstagen
- **Geschenkideen zu verwalten** – Ideen anlegen, planen, tracken
- **Nichts zu vergessen** – Intelligente Erinnerungen vor wichtigen Daten
- **KI-gestützte Inspiration** – Geschenkideen generieren (optional)

---

## Test-Fokus für v0.2.0 Beta

### Kernfunktionen zum Testen

#### 1. Timeline (Hauptansicht)
- [ ] Tab-Navigation (Heute / 7 Tage / 30 Tage)
- [ ] Pull-to-Refresh funktioniert
- [ ] Suche nach Namen und Beziehungen
- [ ] Filter (Alle / Mit Ideen / Ohne Ideen / Beziehungen)
- [ ] Swipe-Aktionen für schnelle Hinzufügung
- [ ] Quick-Add (Plus-Icon) funktioniert
- [ ] Navigation zu PersonDetailView

#### 2. Personen & Geschenkideen
- [ ] PersonDetailView zeigt alle Infos
- [ ] Geschenkidee hinzufügen (Formular)
- [ ] Geschenkidee bearbeiten
- [ ] Geschenkidee löschen
- [ ] Status ändern (Idee → Geplant → Gekauft → Verschenkt)
- [ ] Geschenkidee duplizieren
- [ ] Geschenkidee teilen (Share Sheet)
- [ ] Budget-Slider funktioniert
- [ ] Tags hinzufügen
- [ ] URL-Validierung und Auto-https

#### 3. Geschenk-Historie
- [ ] Historie-Eintrag hinzufügen
- [ ] Historie-Eintrag bearbeiten
- [ ] Historie-Eintrag löschen
- [ ] Als Idee übernehmen

#### 4. Erinnerungen
- [ ] Berechtigungsabfrage (Notifications)
- [ ] Erinnerungen aktivieren/deaktivieren
- [ ] ReminderSettings öffnen und ändern
- [ ] Erinnerungen manuell neu laden
- [ ] Benachrichtigungen erhalten (simuliert durch Settings)

#### 5. Kontakte-Import
- [ ] iOS Kontakte-Permission abfragen
- [ ] Kontakte erfolgreich importieren
- [ ] Duplicate-Erkennung funktioniert
- [ ] Import abbrechen

#### 6. KI-Vorschläge
- [ ] AI-Suggestions Sheet öffnen
- [ ] Demo-Mode testen
- [ ] Optional: OpenRouter API testen (falls konfiguriert)
- [ ] KI-Vorschläge als Idee übernehmen

#### 7. Settings & Einstellungen
- [ ] App Version anzeigen
- [ ] Über die App (About Dialog)
- [ ] Feedback senden (Mail-App öffnet)
- [ ] Dev Settings (nur DEBUG build)
- [ ] iCloud Sync Status
- [ ] Daten löschen (mit Bestätigung)
- [ ] Datenschutz & Impressum (Privacy Policy & Terms of Service)

#### 8. iCloud Sync
- [ ] Daten auf zwei iOS Geräten testen
- [ ] Änderungen synchronisieren
- [ ] Offline-Modus funktioniert
- [ ] CloudKit Fallback (bei Netzwerkproblemen)

### Accessibility (Zugänglichkeit)
- [ ] VoiceOver Navigation funktioniert
- [ ] Accessibility Labels sind klar
- [ ] Reduced Motion aktivieren/deaktivieren
- [ ] Dynamic Type (Schriftgröße) testen

### UI/UX
- [ ] Empty States sind hilfreich
- [ ] Toast Notifications erscheinen
- [ ] Haptic Feedback spürbar
- [ ] Animierungen sind flüssig
- [ ] Dark Mode Support (falls aktiv)

---

## Bekannte Issues & Workarounds

### Minor Issues (keine Blocker)
- TimelineFilterView könnte in Zukunft als echte Komponente refactored werden
- Manchmal kann es zu leichten Verzögerungen bei der iCloud Sync kommen (normal)

### Bitte Feedback geben zu
- Welche Funktionen fehlen dir?
- Was ist unklar oder verwirrend?
- Welche Verbesserungen würdest du wünschen?
- Gibt es Performance-Probleme?
- Crashes oder unerwartetes Verhalten?

---

## Wie Feedback geben?

### In-App Feedback
1. Öffne Einstellungen
2. Tippe auf "Feedback senden"
3. Beschreibe dein Feedback im E-Mail-Text

### GitHub Issues
Besuche https://github.com/hendrikgrueger-web/geburtstage-geschenke-iOS/issues und erstelle ein Issue:
- **Titel**: Kurze, klare Beschreibung
- **Kategorie**: Bug / Feature Request / UX-Feedback / Sonstiges
- **Schritte zur Reproduktion** (bei Bugs): Was hast du getan?
- **Erwartetes Verhalten**: Was hättest du erwartet?
- **Tatsächliches Verhalten**: Was ist passiert?
- **Screenshots/Videos**: Falls hilfreich

### Email Feedback
Schreibe an hendrik@gruepi.de mit:
- App Version (siehe Einstellungen)
- iOS Version
- iPhone Modell
- Beschreibung des Problems/Feedbacks

---

## Crash Reporting

Wenn die App abstürzt:
1. Öffne Xcode Organizer (falls du Xcode hast)
2. Share Crash Log mit uns
3. Oder beschreibe was du getan hast kurz vor dem Crash

---

## Test-Tipps

1. **Teste das Worst-Case Szenario**: Was passiert, wenn du das Internet abschaltest?
2. **Teste Edge Cases**: Leere Listen, sehr lange Texte, spezielle Zeichen
3. **Teste Accessibility**: Aktiviere VoiceOver und navigiere durch die App
4. **Teste Notifications**: Schalte Erinnerungen ein und warte auf Geburtstage
5. **Teste Sync**: Ändere auf Gerät A, prüfe auf Gerät B

---

## Was kommt als Nächstes?

### v0.3.0 (Geplant)
- Home Screen Widget (iOS 17+)
- App Intents für Siri Integration
- iPad Optimierung
- Dark Mode Verbesserungen

### v0.4.0 (Geplant)
- WatchOS Companion App
- KI Prompt Optimierung
- Kontext-basierte Vorschläge
- Geschenk-Budget Tracker

---

## Danke!

Vielen Dank für deine Unterstützung beim Testen von aiPresents! Dein Feedback hilft uns, die App besser zu machen.

**Kontakt:**
- GitHub: https://github.com/hendrikgrueger-web/geburtstage-geschenke-iOS
- Email: hendrik@gruepi.de

---

## Haftungsausschluss

Dies ist eine Beta-Version. Daten können verloren gehen oder inkorrekt sein. Verwende keine kritischen Daten, die du nicht manuell backuppen kannst.

## Rechtliche Dokumente

- [Datenschutzrichtlinie (Privacy Policy)](Docs/PRIVACY.md) - Wie wir mit deinen Daten umgehen
- [Terms of Service](Docs/TERMS.md) - Nutzungsbedingungen der App

Beide Dokumente sind auch auf Englisch verfügbar: [Privacy Policy (English)](Docs/PRIVACY_EN.md), [Terms of Service (English)](Docs/TERMS_EN.md)

---

**iOS Version:** iOS 17.0+
**iPhone Modelle:** Alle iPhone-Modelle mit iOS 17+
**iCloud Account:** Erforderlich für Sync
