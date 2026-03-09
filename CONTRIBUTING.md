# Contributing to ai-presents-app-ios

Vielen Dank für dein Interesse an ai-presents-app-ios! Dieser Leitfaden hilft dir, schnell loszulegen.

## Entwicklungs-Setup

### Voraussetzungen
- macOS 14.0+ (Sonoma)
- Xcode 15.4+
- Swift 5.10+
- Git

### Projekt klonen
```bash
git clone https://github.com/hendrikgrueger-web/geburtstage-geschenke-iOS.git
cd ai-presents-app-ios
```

### Abhängigkeiten installieren
```bash
# Swift Package Manager Dependencies werden automatisch gelöst
swift package resolve
```

### Projekt öffnen
```bash
# Als Xcode Projekt öffnen
open Package.swift

# Oder: CLI Tests laufen lassen
swift test
```

## Coding Standards

### Swift Style Guide
Wir folgen der [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/).

### Namenskonventionen
- **Types**: `PascalCase` (z.B. `PersonDetailView`)
- **Methods/Properties**: `camelCase` (z.B. `calculateNextBirthday`)
- **Constants**: `camelCase` mit `let` (z.B. `maxDays`)
- **Acronyms**: `PascalCase` wenn es ein Typ ist, `camelCase` wenn es eine Variable ist
  - ✅ `URL`, `JSON`
  - ✅ `urlString`, `jsonData`

### SwiftUI Best Practices
- Views sollten stateless sein, wenn möglich
- Verwende `@Observable` für ViewModels (iOS 17+)
- Separate business logic in ViewModels/Services
- Vermeide komplexe Logik in View body

### SwiftData Best Practices
- Verwende `@Model` markierte Klassen
- Definiere klare `@Relationship` Referenzen
- Verwende FetchDescriptors für optimierte Queries

## Code Style

### Formatierung
- Einrückung: 4 Spaces
- Zeilenlänge: max 120 Zeichen
- Leerzeilen: 1 zwischen logischen Blöcken, 2 zwischen Funktionen/Types

### Imports
```swift
import SwiftUI
import SwiftData
import Foundation
// System Imports zuerst, dann Third Party
```

### Documentation
```swift
/// Calculates the next birthday for a person.
///
/// - Parameter person: The person to calculate the birthday for
/// - Parameter from: The reference date (default: today)
/// - Returns: The next birthday date, or nil if calculation fails
func calculateNextBirthday(for person: PersonRef, from today: Date = Date()) -> Date? {
    // Implementation
}
```

## Testing

### Test-Struktur
```swift
import XCTest
@testable import aiPresentsApp

final class FeatureTests: XCTestCase {
    override func setUp() async throws {
        // Setup code
    }

    func testFeature() {
        // Test implementation
        XCTAssertEqual(actual, expected)
    }
}
```

### Test-Namenskonventionen
- `test[Feature]` – Tests für ein Feature
- `test[Feature]When[Condition]` – Tests für einen speziellen Fall
- `test[Feature]Returns[Expected]When[Input]` – Beschreibende Tests

### Tests ausführen
```bash
# Alle Tests
swift test

# Spezielle Tests
swift test --filter FeatureTests

# Mit Code Coverage
swift test --enable-code-coverage
```

## Git Workflow

### Branches
- `main` – Produktionscode
- `develop` – Entwicklungscode (optional)
- `feature/XYZ` – Feature Branches
- `bugfix/XYZ` – Bugfix Branches

### Commit Messages
Wir folgen [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: Neues Feature
- `fix`: Bugfix
- `docs`: Dokumentation
- `style`: Code Style (keine Logik-Änderung)
- `refactor`: Refactoring
- `test`: Tests hinzufügen/ändern
- `chore`: Build-Prozess/Tooling

**Beispiele:**
```
feat(settings): add dark mode toggle
fix(birthday): correct leap year calculation
docs(readme): update installation instructions
test(reminder): add unit tests for notification scheduling
```

### Pull Requests
1. Branch erstellen (`git checkout -b feature/my-feature`)
2. Änderungen committen
3. Branch pushen (`git push origin feature/my-feature`)
4. PR erstellen mit:
   - Klarem Titel und Beschreibung
   - Reference zu Issue (falls vorhanden)
   - Screenshots/UI-Änderungen bei relevanten Features
   - Checklist für Review

## Projekt-Struktur

```
Sources/aiPresentsApp/
├── Models/              # SwiftData Models
├── Services/            # Business Logic Services
├── ViewModels/          # @Observable ViewModels
├── Views/               # SwiftUI Views
│   ├── Components/      # Reusable UI Components
│   └── Widgets/         # Widget Views
├── Utilities/           # Helper Functions
└── Resources/           # Assets, Colors, etc.

Tests/aiPresentsAppTests/
├── ModelTests/          # Model Tests
├── ServiceTests/        # Service Tests
└── ViewTests/           # View Tests

Docs/                    # Documentation
.github/                 # GitHub Actions/Workflows
```

## Code Review Prozess

### Review-Checkliste
- [ ] Code folgt dem Style Guide
- [ ] Tests sind vorhanden und bestehen
- [ ] Dokumentation ist aktuell
- [ ] Keine Debug Code/Prints
- [ ] Accessibility Labels sind gesetzt
- [ ] Haptic Feedback ist sinnvoll
- [ ] SwiftLint durchläuft ohne Fehler
- [ ] UI Tests (wenn nötig)

### Review-Feedback
- Sei konstruktiv und spezifisch
- Begründe deine Vorschläge
- Schlage Alternativen vor, wenn möglich

## Issues und Bug Reports

### Issue Template
```markdown
**Titel**: Kurze Beschreibung

**Beschreibung**:
Detaillierte Beschreibung des Problems

**Schritte zum Reproduzieren**:
1.
2.
3.

**Erwartetes Verhalten**:
Was passieren sollte

**Tatsächliches Verhalten**:
Was passiert

**Umgebung**:
- iOS Version: ...
- App Version: ...
- Gerät: ...
```

## Release-Prozess

1. Version in `Package.swift` und `aiPresentsApp/Info.plist` updaten
2. CHANGELOG.md aktualisieren
3. `vX.Y.Z` Tag erstellen
4. Release Notes in GitHub Release schreiben
5. TestFlight hochladen (für Beta)

## Kommunikation

- Für Fragen: Issues auf GitHub
- Für Diskussionen: GitHub Discussions
- Für Notfälle: Kontakt den Maintainer

## Hilfreiche Ressourcen

- [Swift Language Guide](https://docs.swift.org/swift-book/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [SwiftLint Rules](https://github.com/realm/SwiftLint/blob/master/Rules.md)

## Lizenz

Durch deinen Beitrag erklärst du dich einverstanden, dass dein Beitrag unter der gleichen Lizenz wie das Projekt veröffentlicht wird.
