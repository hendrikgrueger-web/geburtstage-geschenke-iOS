# ai-presents-app-ios

> iPhone-App für Geburtstage, Geschenkideen und rechtzeitige Erinnerungen – Apple-nativ, iCloud-fähig, KI-unterstützt (opt-in).

## Kurzüberblick
`ai-presents-app-ios` hilft dir, Geburtstage aus iOS-Kontakten zu nutzen, pro Person Geschenkideen zu pflegen und rechtzeitig erinnert zu werden.

**Leitprinzipien:**
- **Apple-Style first** (SwiftUI, HIG-orientiert)
- **Datensparsamkeit** (nur nötige Daten)
- **Zuverlässigkeit vor Spielerei**
- **KI optional**, Kernfunktionen laufen ohne KI

---

## Kernfunktionen (aktueller Stand)
- Geburtstag-Timeline: **Heute / 7 Tage / 30 Tage**
- Personenansicht mit Countdown, Geschenkideen, Historie
- Geschenkideen-CRUD (anlegen, bearbeiten, löschen, duplizieren)
- Reminder-Regeln (Default: **30/14/7/2 Tage**)
- Kontakte-Import (Contacts.framework)
- iCloud-Synchronisation (CloudKit / SwiftData)
- KI-Vorschläge (OpenRouter, opt-in)
- Accessibility-Basis (VoiceOver/Labels)

---

## Projektstruktur
```text
App/                            # App Entry & plist
Sources/aiPresentsApp/
  Models/                       # SwiftData-Modelle
  Services/                     # Contacts, Reminder, AI, CloudKit
  ViewModels/                   # UI-Logik
  Views/                        # SwiftUI Views & Sheets
  Utilities/                    # Haptics, Animation, Helper
  Widgets/                      # Widget Views (Ausbau)
Docs/                           # Produkt-/Technik-/Roadmap-Doku
```

---

## Schnellstart (Entwicklung)
1. Repo klonen
2. In Xcode öffnen (Package/App Target je nach Setup)
3. Signing-Team einstellen
4. Berechtigungen prüfen:
   - Contacts
   - Notifications
   - iCloud/CloudKit
5. Build & Run auf iPhone/Simulator

> Hinweis: Für KI-Funktionen OpenRouter-Konfiguration ergänzen (siehe `Docs/ARCHITECTURE.md`).

---

## Dokumentation
- `Docs/PRD.md` – Produktanforderungen (Deutsch)
- `Docs/ARCHITECTURE.md` – Technische Architektur
- `Docs/ROADMAP.md` – Delivery-Roadmap
- `Docs/EXECUTION-PLAN-4-WEEKS.md` – Umsetzungsplan mit Gates
- `Docs/LEGAL-OSS-REUSE.md` – OSS/Lizenzregeln
- `Docs/DEVELOPMENT.md` – Entwicklungs- und QA-Workflow

---

## Nächste Meilensteine
1. QA-Härtung (Blocker/Crash-Prävention)
2. TestFlight-Stabilisierung
3. KI-Qualität & Prompting verbessern
4. Widget + App Intents (nach MVP-Stabilität)

---

## Lizenz & OSS-Hinweise
Dieses Repo ist privat. Bei Übernahme externer OSS-Bausteine gelten die Regeln aus `Docs/LEGAL-OSS-REUSE.md`.
