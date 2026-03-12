# Development & QA Guide

## 1) Arbeitsmodus
- kleine, sichere Änderungen
- nach jeder Änderung: Build-Check + kurzer Self-Review
- klare Commit-Messages

## 2) Branch-/Commit-Konvention
- `feat:` neue Funktion
- `fix:` Bugfix
- `refactor:` Strukturverbesserung
- `docs:` Dokuänderung

## 3) QA-Definition „lauffähig"
**Blocker (No-Go):**
- Build bricht
- App crasht in Kernflow
- Reminder nicht planbar
- Navigation zu leeren/invaliden States mit Crash

**Minor (Go möglich):**
- kleines UI-Polish
- Label-Text nicht final
- sekundäre Komfortfeatures

## 4) Mindest-Tests vor Push
1. App Start
2. Timeline sichtbar
3. Person öffnen
4. Geschenkidee anlegen
5. Geschenkidee bearbeiten
6. Reminder-Regeln aufrufen
7. zurück navigieren ohne Fehler
8. mindestens ein Empty-State geprüft

## 5) Accessibility-Mindeststandard
- Buttons/Swipe-Actions mit Labels
- sinnvolle Reihenfolge in VoiceOver
- keine rein farbabhängigen Zustände

## 6) Dokumentationsregel
Bei Feature/Fix immer aktualisieren:
- README (falls user-relevant)
- PRD/Architecture (falls Verhalten/Scope geändert)
- Roadmap (falls Meilenstein verschoben)
