---
title: "feat: Quality Hardening + v1.0.5 Release"
type: feat
status: active
date: 2026-04-10
---

# Quality Hardening + v1.0.5 Release

## Overview

Fünf gezielte Verbesserungen die zusammen als v1.0.5 released werden: Crash-Fix ausliefern, übersprungene Tests aktivieren, GenderInference-Lücken schließen, AI-Sheet-Duplikation eliminieren, RelationOptions iCloud-synced machen.

## Problem Frame

- v1.0.4 enthält einen Speech-Recognition-Crash-Fix der noch nicht bei allen Usern ist (Xcode Cloud Build nötig)
- 71 Tests sind übersprungen wegen SwiftData-ModelContainer-Konflikt mit TEST_HOST
- GenderInference erkennt 6 gängige Beziehungstypen nicht (Ehefrau, Ehemann, Cousin, Cousine, wife, husband)
- Zwei AI-Sheets haben identischen Loading/Error-State Code (~80 Zeilen dupliziert)
- Custom RelationOptions gehen bei Gerätewechsel verloren (nur UserDefaults, kein iCloud-Sync)

## Scope Boundaries

- Keine neuen Features, nur Qualität und Stabilität
- Kein Relation-DB-Migration (englische Keys) — das bleibt im Backlog
- Kein Premium-Gating — v1 bleibt komplett gratis
- Version wird auf 1.0.5 gebumpt, Build-Nummer erhöht

## Key Technical Decisions

- **Übersprungene Tests**: `XCTSkip` entfernen und `ModelConfiguration("test", isStoredInMemoryOnly: true, cloudKitDatabase: .none)` nutzen statt TEST_HOST-Container. Die Tests haben den Code bereits — er wird nur nie erreicht weil `XCTSkip` in `setUp()` wirft.
- **RelationOptions iCloud-Sync**: `NSUbiquitousKeyValueStore` statt SwiftData-Model. Grund: Minimal-invasiv, kein Schema-Migration nötig, CurrencyManager nutzt bereits dasselbe Pattern.
- **AI-Sheet-Refactoring**: Shared `AILoadingErrorView` als eigene View in `Views/Components/` extrahieren, kein ViewModifier (weil der Consent-Flow kontextabhängig ist).
- **GenderInference**: Fehlende Relationen zur bestehenden Liste hinzufügen — einfache Array-Erweiterung.

## Implementation Units

- [ ] **Unit 1: GenderInference — fehlende Relationen ergänzen**

  **Goal:** 6 fehlende Beziehungstypen in die Inference-Listen aufnehmen

  **Files:**
  - Modify: `Sources/aiPresentsApp/Utilities/GenderInference.swift`
  - Modify: `Tests/aiPresentsAppTests/PrivacyUtilitiesExtendedTests.swift`

  **Approach:**
  - Weiblich-Liste ergänzen: `ehefrau`, `cousine`, `wife`
  - Männlich-Liste ergänzen: `ehemann`, `cousin`, `husband`
  - Bestehende Tests in PrivacyUtilitiesExtendedTests von `.neutral`-Erwartung auf korrekte Gender-Erwartung ändern

  **Patterns to follow:** Bestehende Listen in `inferFromRelation()` (Zeile 42-59)

  **Test scenarios:**
  - `infer(relation: "Ehefrau", firstName: "")` → `.female`
  - `infer(relation: "husband", firstName: "")` → `.male`
  - Prioritäts-Test: `infer(relation: "Ehefrau", firstName: "Max")` → `.female` (Relation vor Name)

  **Verification:** Alle PrivacyUtilitiesExtendedTests grün, keine Regression in bestehenden GenderInferenceTests

- [ ] **Unit 2: Übersprungene Tests aktivieren (71 Tests)**

  **Goal:** Alle `XCTSkip`-Aufrufe entfernen und SwiftData-Tests mit In-Memory-Container lauffähig machen

  **Files:**
  - Modify: `Tests/aiPresentsAppTests/GiftModelValidationTests.swift`
  - Modify: `Tests/aiPresentsAppTests/PersonRefExportTests.swift`
  - Modify: `Tests/aiPresentsAppTests/ReminderManagerTests.swift`
  - Modify: `Tests/aiPresentsAppTests/SampleDataServiceTests.swift`
  - Modify: `Tests/aiPresentsAppTests/SuggestionQualityViewModelTests.swift`
  - Modify: `Tests/aiPresentsAppTests/UtilityTests/FormStateTests.swift`

  **Approach:**
  - `throw XCTSkip(...)` Zeile in jeder `setUp()` entfernen
  - ModelContainer-Konfiguration: `ModelConfiguration("test", isStoredInMemoryOnly: true, cloudKitDatabase: .none)` — `.none` verhindert CloudKit-Inverse-Relationship-Fehler
  - Schema muss alle Models enthalten: `[PersonRef.self, GiftIdea.self, GiftHistory.self, ReminderRule.self, SuggestionFeedback.self]`
  - Falls Tests trotzdem fehlschlagen: Container-Erstellung in separate Helper-Funktion auslagern

  **Patterns to follow:** `AppModelContainerFactory` in `Sources/aiPresentsApp/Utilities/AppModelContainerFactory.swift` — dort wird bereits ein lokaler Fallback-Container erstellt

  **Test scenarios:**
  - GiftModelValidation: CRUD, Cascade-Delete, Status-Übergänge
  - PersonRefExport: CSV-Export mit korrekten Daten
  - ReminderManager: Rule-Defaults, Storage
  - SampleData: Generierung und Bereinigung
  - SuggestionQuality: Feedback-Recording, Metriken

  **Verification:** `xcodebuild test` zeigt 0 übersprungene Tests in diesen 6 Klassen, Gesamtzahl Tests steigt von 1148 auf ~1219

- [ ] **Unit 3: AI-Sheet Loading/Error-State extrahieren**

  **Goal:** Duplizierten Loading- und Error-State-Code aus AIGiftSuggestionsSheet und AIBirthdayMessageSheet in shared Component auslagern

  **Files:**
  - Create: `Sources/aiPresentsApp/Views/Components/AILoadingErrorView.swift`
  - Modify: `Sources/aiPresentsApp/Views/AI/AIGiftSuggestionsSheet.swift`
  - Modify: `Sources/aiPresentsApp/Views/AI/AIBirthdayMessageSheet.swift`

  **Approach:**
  - `AILoadingErrorView` als struct mit Parametern: `loadingMessage: String`, `needsConsent: Bool`, `onConsent: () -> Void`, `onRetry: (() -> Void)?`
  - Separates `AILoadingView` (einfacher Spinner + Text) und `AIErrorView` (Consent-aware Error mit Retry)
  - In beiden Sheets die `loadingState` und `errorState()` computed properties durch die shared Components ersetzen
  - Consent-Logik bleibt in den Sheets (nur UI wird extrahiert)

  **Patterns to follow:** Bestehende Components in `Views/Components/` (z.B. `HobbiesChipView`, `ToastView`)

  **Test scenarios:**
  - AIGiftSuggestionsSheet zeigt Loading bei `isLoading && suggestions.isEmpty`
  - AIBirthdayMessageSheet zeigt Loading bei `isLoading`
  - Error-State mit Consent-Hinweis wenn `needsConsent = true`
  - Error-State mit Retry-Button wenn `needsConsent = false`

  **Verification:** Beide Sheets funktionieren identisch wie vorher, visuell keine Änderung. Build erfolgreich.

- [ ] **Unit 4: RelationOptions iCloud-Sync**

  **Goal:** Custom-Beziehungstypen über iCloud zwischen Geräten synchronisieren

  **Files:**
  - Modify: `Sources/aiPresentsApp/Utilities/RelationOptions.swift`
  - Modify: `Tests/aiPresentsAppTests/RelationOptionsTests.swift`

  **Approach:**
  - `NSUbiquitousKeyValueStore` als zusätzlichen Sync-Kanal nutzen (parallel zu UserDefaults)
  - Beim Schreiben: `UserDefaults` UND `NSUbiquitousKeyValueStore` aktualisieren
  - Beim Lesen: `NSUbiquitousKeyValueStore` bevorzugen, UserDefaults als Fallback
  - `didChangeExternallyNotification` beobachten für Live-Sync von anderen Geräten
  - Pattern identisch mit `CurrencyManager.swift` (Zeilen 57-72)

  **Patterns to follow:** `CurrencyManager.swift` — nutzt bereits `NSUbiquitousKeyValueStore` für `isAutomatic` und `currencyCode`

  **Test scenarios:**
  - Custom-Typ hinzufügen → in UserDefaults UND iCloud gespeichert
  - Custom-Typ entfernen → aus beiden entfernt
  - Externe iCloud-Änderung → lokale Liste aktualisiert
  - Merge: lokale + iCloud-Typen werden dedupliziert zusammengeführt

  **Verification:** Custom-Typen bleiben nach App-Neuinstallation erhalten (via iCloud). Keine Duplikate bei Sync-Konflikten.

- [ ] **Unit 5: Version bumpen + Release**

  **Goal:** Version auf 1.0.5 setzen und App Store Build triggern

  **Files:**
  - Modify: `project.yml` (2x: App + Widget)

  **Approach:**
  - `CFBundleShortVersionString` → `"1.0.5"` (1.0.4 war bei Apple geschlossen)
  - `CFBundleVersion` → nächste Build-Nummer (136+)
  - `xcodegen generate` ausführen
  - Build verifizieren mit `xcodebuild build`
  - Alle Tests laufen lassen
  - Push → Xcode Cloud "App Store Build" Workflow triggern

  **Verification:** Build erfolgreich, alle Tests grün (inkl. neu aktivierte), Push löst Xcode Cloud aus

## System-Wide Impact

- **GenderInference-Änderung:** Wirkt sich auf KI-Prompts aus — "Ehefrau" wird jetzt als weiblich erkannt statt neutral. Verbessert KI-Antwortqualität.
- **RelationOptions iCloud:** Betrifft RelationPickerView, PersonDetailView — Custom-Typen werden bei externem Sync automatisch aktualisiert.
- **AI-Sheet-Refactoring:** Rein visuelles Refactoring, keine Verhaltensänderung.

## Risks & Dependencies

- **SwiftData-Tests**: Container-Erstellung kann bei bestimmten Model-Konfigurationen fehlschlagen. Mitigation: `.cloudKitDatabase: .none` und vollständiges Schema.
- **iCloud-Sync**: `NSUbiquitousKeyValueStore` hat 1MB Limit und max 1024 Keys. Bei Custom-Relationen unkritisch (max. ~50 Strings).
- **Version 1.0.5**: Xcode Cloud muss funktionieren. Fallback: manueller Upload via Xcode.
