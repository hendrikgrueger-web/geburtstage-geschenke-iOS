# PRD — ai-presents-app-ios (v1)

## 1) Ziel
Eine iPhone-App, die Geburtstage und Geschenkplanung in einem klaren, schnellen Flow abbildet:
- **Wer hat wann Geburtstag?**
- **Was schenke ich sinnvoll?**
- **Wann muss ich aktiv werden?**

## 2) Zielgruppe
Primär 1 User (Hendrik) mit hoher Erwartung an:
- Geschwindigkeit
- Übersichtlichkeit
- Apple-native UX
- geringe Komplexität bei hoher Wirkung

## 3) Kernnutzen
- Keine verpassten Geburtstage
- Geschenkideen kontextbezogen gespeichert
- rechtzeitige Erinnerungen mit Eskalation
- optional KI-Hilfe bei Ideenfindung

## 4) Muss-Anforderungen (MVP)
1. Import von Geburtstagsdaten aus iOS-Kontakten
2. Timeline mit Filtern (Heute/7/30 Tage)
3. Geschenkideen pro Person (CRUD)
4. Reminder-Engine mit Standardstufen 30/14/7/2
5. iCloud-Sync (CloudKit)
6. Deutsch als Primärsprache

## 5) Soll-Anforderungen (v1.x)
- Geschenkhistorie pro Kontakt
- Share/Export relevanter Einträge
- Onboarding mit Berechtigungsführung
- bessere URL- und Budget-Validierung

## 6) KI-Funktionen (opt-in)
- 5 Geschenkideen + kurze Begründung
- Wiederholungs-Guard (ähnliche Geschenke vermeiden)
- personalisierte Geburtstagsnachrichten als Entwurf

## 7) Nicht-Ziele (MVP)
- Multi-User Collaboration
- Shop-Integrationen
- komplexes Recommendation-System on-device
- iPad/Mac-First Umsetzung

## 8) Qualitätskriterien
- App startet stabil und reagiert flüssig
- keine Blocker-Crashes in Kernflows
- Reminder zuverlässig und nachvollziehbar
- Accessibility-Basis sauber

## 9) Erfolgsmessung (MVP-intern)
- Kernflow ohne Fehler durchführbar:
  Kontakt → Idee → Reminder → Statusupdate
- keine offenen Blocker in QA-Checkliste
- subjektive UX-Bewertung: „klar, schnell, Apple-like"
