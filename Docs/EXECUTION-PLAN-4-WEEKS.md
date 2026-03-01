# Execution Plan (4 Wochen) — ai-presents-app-ios

## Woche 1 — MVP Core (ohne KI)
**Ziel:** App nutzbar für Geburtstage + Geschenkideen + Reminder

### Build
- iPhone SwiftUI App Skeleton
- Contacts Birthday Import (minimal fields)
- Timeline View: Heute / 7 Tage / 30 Tage
- Contact Detail + Gift Ideas CRUD
- Reminder Engine (30/14/7/2)

### Definition of Done
- 1 Testkontakt vollständig durchspielbar
- Reminder wird korrekt ausgelöst
- App startet stabil, keine Crashs im Happy Path

---

## Woche 2 — iCloud + Stabilität
**Ziel:** Daten zuverlässig zwischen Geräten synchronisieren

### Build
- SwiftData + CloudKit Sync
- Konfliktstrategie (last-write-wins für Notizen, append für Historie)
- Settings Screen (Permissions + Reminder Defaults)

### Definition of Done
- Änderungen auf Gerät A erscheinen auf Gerät B
- Keine doppelten Gift-Ideen durch Sync

---

## Woche 3 — KI v1 (OpenRouter, opt-in)
**Ziel:** Assistive KI ohne Core-Abhängigkeit

### Build
- AI Suggestion Panel pro Kontakt
- Input minimiert (Tags, Budget, Anlass, letzter Geschenktyp)
- Output: 5 konkrete Vorschläge + 1 Begründung je Vorschlag
- AI Toggle in Settings (opt-in)

### Definition of Done
- KI kann vollständig deaktiviert werden
- Core-App bleibt ohne KI vollständig nutzbar

---

## Woche 4 — Polish + TestFlight
**Ziel:** Release-fähiger Stand

### Build
- Apple-HIG Feinschliff
- Accessibility pass (Dynamic Type, VoiceOver Labels)
- Privacy Text + In-App Disclosure
- Crash/Edge-Case Fixes

### Definition of Done
- Interner TestFlight Build verteilt
- 10 zentrale Flows erfolgreich getestet

---

## Bewusst NICHT im MVP
- iPad / Mac Universal App
- Social Features
- Externe Shop-Integrationen
- Komplexe ML-Personalisierung on-device

---

## Entscheidungs-Gates
1. Ende Woche 1: Core-UX passt? Dann Sync starten.
2. Ende Woche 2: Sync stabil? Dann KI aktivieren.
3. Ende Woche 3: KI nützlich genug? Sonst KI in v1.1 verschieben.
