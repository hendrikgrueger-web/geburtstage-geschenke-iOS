# Plan: App auf iPhone 16e Simulator lauffähig machen

## Status: OFFEN

## Problem

Das Projekt ist ein Swift Package mit `.library` Target — es wird nur ein `.o` Object File gebaut, kein `.app` Bundle. Die App kann daher nicht auf dem Simulator installiert/gestartet werden.

## Lösung: Xcode-Projekt via xcodegen

### 1. xcodegen installieren
```bash
brew install xcodegen
```

### 2. `project.yml` erstellen (Projekt-Root)
- iOS App-Target mit `Sources/aiPresentsApp/` als Source
- Lokales Swift Package als Dependency
- `App/Info.plist` referenziert
- Bundle ID: `com.hendrikgrueger.ai-presents`, iOS 17

### 3. `Package.swift` — `@main` aus Library excluden
```swift
.target(name: "aiPresentsApp", path: "Sources/aiPresentsApp", exclude: ["aiPresentsApp.swift"])
```
Verhindert "duplicate main" Konflikt zwischen Library und App-Target.

### 4. `App/Info.plist` — Doppelten UIApplicationSceneManifest entfernen
Zeilen 53-69 entfernen (Duplikat von Zeilen 25-29).

### 5. `App/aiPresentsApp.swift` löschen
Veraltete Kopie mit Compile-Fehlern (`identifier:` Label, `nil` statt `.none`).
Die korrekte Version ist `Sources/aiPresentsApp/aiPresentsApp.swift`.

### 6. `xcodegen generate` ausführen
Erzeugt `ai-presents-app-ios.xcodeproj`.

### 7. Build → Install → Launch
```bash
xcodebuild -project ai-presents-app-ios.xcodeproj \
  -scheme ai-presents-app-ios \
  -destination 'platform=iOS Simulator,id=393E9E09-95BE-481C-9C15-567808F8AF26' \
  build

xcrun simctl install 393E9E09-95BE-481C-9C15-567808F8AF26 <path-to>.app
xcrun simctl launch 393E9E09-95BE-481C-9C15-567808F8AF26 com.hendrikgrueger.ai-presents
```

### 8. Tests verifizieren
120/120 Tests müssen weiterhin passen (nutzen das Library-Target via Package.swift).

## Kritische Dateien
| Datei | Aktion |
|-------|--------|
| `Package.swift` | `exclude: ["aiPresentsApp.swift"]` hinzufügen |
| `project.yml` | NEU erstellen |
| `App/Info.plist` | Duplikat-Key entfernen |
| `App/aiPresentsApp.swift` | Löschen (trash) |

## Hinweise
- **CloudKit**: Ohne Entitlements fällt die App auf local-only Fallback zurück (ok für Simulator)
- **App Icon**: Fehlt, Placeholder wird angezeigt — funktioniert trotzdem
- **Signing**: Nicht nötig für Simulator-Builds
