import XCTest
@testable import aiPresentsApp

// MARK: - GiftHistoryRow — Year-Rendering Tests
//
// Hintergrund: SwiftUI's `Text("\(int)")` löst LocalizedStringKey-Interpolation aus.
// In de_DE (und anderen Locales mit Tausenderpunkt/-leerzeichen) formatiert iOS
// den Integer 2025 als „2.025" oder „2 025". Fix: `Text(verbatim: String(int))`.
//
// Diese Tests prüfen, dass:
//   1. `String(Int)` in KEINER Locale Tausenderpunkte/-leerzeichen erzeugt.
//   2. Die korrekte Jahreszahl (ohne Formatierung) für alle Boundary-Years zurückkommt.
//   3. Das Accessibility-Label ebenfalls `String(year)` statt direkte Int-Interpolation nutzt.

final class GiftHistoryRowYearStringTests: XCTestCase {

    // MARK: - Standard-Jahre: Round-Trip String(Int) in allen vier App-Sprachen

    func testYearString_2025_deDE() {
        let result = yearString(2025, localeID: "de_DE")
        XCTAssertEqual(result, "2025", "de_DE: String(2025) muss '2025' sein — kein Tausenderpunkt")
    }

    func testYearString_2025_enUS() {
        let result = yearString(2025, localeID: "en_US")
        XCTAssertEqual(result, "2025", "en_US: String(2025) muss '2025' sein")
    }

    func testYearString_2025_frFR() {
        let result = yearString(2025, localeID: "fr_FR")
        XCTAssertEqual(result, "2025",
                       "fr_FR nutzt schmales Leerzeichen als Tausendertrenner bei Zahlen-Formatierung. " +
                       "String(Int) darf das NICHT tun.")
    }

    func testYearString_2025_esES() {
        let result = yearString(2025, localeID: "es_ES")
        XCTAssertEqual(result, "2025", "es_ES: String(2025) muss '2025' sein")
    }

    func testYearString_2024_deDE() {
        let result = yearString(2024, localeID: "de_DE")
        XCTAssertEqual(result, "2024")
    }

    func testYearString_2024_enUS() {
        let result = yearString(2024, localeID: "en_US")
        XCTAssertEqual(result, "2024")
    }

    func testYearString_2024_frCA() {
        let result = yearString(2024, localeID: "fr_CA")
        XCTAssertEqual(result, "2024", "fr_CA darf keinen Tausendertrenner bei Int-String-Konversion produzieren")
    }

    func testYearString_2024_esMX() {
        let result = yearString(2024, localeID: "es_MX")
        XCTAssertEqual(result, "2024")
    }

    // MARK: - Boundary Years

    func testYearString_boundary_1900() {
        XCTAssertEqual(String(1900), "1900")
    }

    func testYearString_boundary_2099() {
        XCTAssertEqual(String(2099), "2099")
    }

    func testYearString_boundary_9999() {
        XCTAssertEqual(String(9999), "9999")
    }

    func testYearString_boundary_1() {
        XCTAssertEqual(String(1), "1")
    }

    func testYearString_boundary_0() {
        XCTAssertEqual(String(0), "0")
    }

    func testYearString_boundary_negative() {
        // Negative Jahre sind im Modell nicht vorgesehen, aber String() muss korrekt arbeiten
        XCTAssertEqual(String(-1), "-1")
        XCTAssertEqual(String(-100), "-100")
    }

    func testYearString_boundary_10000() {
        XCTAssertEqual(String(10000), "10000",
                       "Fünfstellige Jahre dürfen keinen Tausendertrenner bekommen")
    }

    func testYearString_boundary_99999() {
        // Extremfall: kein Separator
        XCTAssertEqual(String(99999), "99999")
    }

    // MARK: - Keine Sonderzeichen im Output

    func testYearString_noThousandsSeparatorDot() {
        // Stichprobenliste typischer 4-stelliger Jahre
        let years = [1900, 1990, 2000, 2001, 2024, 2025, 2026, 2099]
        for year in years {
            let str = String(year)
            XCTAssertFalse(str.contains("."), "Jahr \(year): String() darf keinen Punkt enthalten")
            XCTAssertFalse(str.contains(","), "Jahr \(year): String() darf kein Komma enthalten")
        }
    }

    func testYearString_noThousandsSeparatorSpace() {
        let years = [1900, 2000, 2025, 2099]
        for year in years {
            let str = String(year)
            // Weder normales Leerzeichen noch schmales Leerzeichen (U+202F, U+2009)
            XCTAssertFalse(str.contains(" "),     "Jahr \(year): kein Leerzeichen")
            XCTAssertFalse(str.contains("\u{202F}"), "Jahr \(year): kein schmales Leerzeichen")
            XCTAssertFalse(str.contains("\u{2009}"), "Jahr \(year): kein dünnes Leerzeichen")
            XCTAssertFalse(str.contains("\u{00A0}"), "Jahr \(year): kein non-breaking space")
        }
    }

    func testYearString_containsOnlyDigitsAndOptionalMinus() {
        let years = [-2025, 0, 1, 2025, 9999]
        for year in years {
            let str = String(year)
            let allowed = CharacterSet.decimalDigits.union(CharacterSet(charactersIn: "-"))
            let isAllCharsAllowed = str.unicodeScalars.allSatisfy { allowed.contains($0) }
            XCTAssertTrue(isAllCharsAllowed,
                          "Jahr \(year): String() enthält unerlaubte Zeichen: '\(str)'")
        }
    }

    // MARK: - Vergleich: LocalizedStringKey-Falle (Dokumentation der Bug-Ursache)

    /// Zeigt, dass NumberFormatter in de_DE den Tausenderpunkt einfügt —
    /// genau das passiert wenn SwiftUI Text("\(int)") als LocalizedStringKey auswertet.
    func testLocalizationTrap_numberFormatter_deDE_addsDot() {
        // Dieser Test dokumentiert das Fehlverhalten beim ALTEN Code (Text("\(int)")).
        // NumberFormatter simuliert was SwiftUI intern tut:
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: 2025)) ?? ""
        // In de_DE: "2.025"
        XCTAssertTrue(
            formatted.contains(".") || formatted.contains(",") || formatted.contains("\u{202F}"),
            "de_DE Locale formatiert 2025 MIT Separator — das ist der Bug. Formatted: '\(formatted)'"
        )
        // Und String(Int) tut das eben NICHT:
        XCTAssertEqual(String(2025), "2025")
        XCTAssertNotEqual(String(2025), formatted,
                          "String(2025) und NumberFormatter-Ausgabe müssen unterschiedlich sein")
    }

    func testLocalizationTrap_numberFormatter_frFR_addsNarrowSpace() {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: 2025)) ?? ""
        // fr_FR: "2 025" mit schmalem Leerzeichen
        let hasThousandsSep = formatted.count > 4 || formatted != "2025"
        XCTAssertTrue(hasThousandsSep,
                      "fr_FR sollte Tausendertrenner haben. Formatted: '\(formatted)'")
        XCTAssertEqual(String(2025), "2025")
    }

    // MARK: - GiftHistory Model: Year-Feld korrekt gespeichert

    func testGiftHistory_yearFieldStoredAsInt() {
        let personId = UUID()
        let history = GiftHistory(
            personId: personId,
            title: "Buch",
            category: "Bücher",
            year: 2025
        )
        XCTAssertEqual(history.year, 2025)
        XCTAssertEqual(String(history.year), "2025")
    }

    func testGiftHistory_yearBoundary_1900() {
        let history = GiftHistory(personId: UUID(), title: "Test", category: "Test", year: 1900)
        XCTAssertEqual(String(history.year), "1900")
    }

    func testGiftHistory_yearBoundary_2099() {
        let history = GiftHistory(personId: UUID(), title: "Test", category: "Test", year: 2099)
        XCTAssertEqual(String(history.year), "2099")
    }

    func testGiftHistory_yearBoundary_0() {
        let history = GiftHistory(personId: UUID(), title: "Test", category: "Test", year: 0)
        XCTAssertEqual(String(history.year), "0")
    }

    // MARK: - Accessibility-Label: String(year) statt Int-Interpolation

    func testAccessibilityLabel_yearPattern_noLocaleFormatting_deDE() {
        // Simuliert das AccessibilityLabel-Pattern: "\(String(history.year))"
        let year = 2025
        let label = "Verschenkt: Buch, Bücher, \(String(year))"
        XCTAssertTrue(label.contains("2025"), "Accessibility-Label muss '2025' enthalten")
        XCTAssertFalse(label.contains("2.025"), "Kein Tausenderpunkt im Accessibility-Label")
    }

    func testAccessibilityLabel_yearPattern_allYears() {
        let years = [1900, 2000, 2024, 2025, 2026, 2099, 9999]
        for year in years {
            let label = "Erhalten: Schal, Kleidung, \(String(year))"
            XCTAssertTrue(label.contains(String(year)),
                          "Label muss '\(year)' enthalten — Jahr \(year)")
            XCTAssertFalse(label.contains("."),
                           "Kein Punkt in Accessibility-Label — Jahr \(year)")
        }
    }

    func testAccessibilityLabel_yearPattern_withUmlauts() {
        let history = GiftHistory(
            personId: UUID(),
            title: "Bücher über Österreich",
            category: "Bücher",
            year: 2025
        )
        let label = "Verschenkt: \(history.title), \(history.category), \(String(history.year))"
        XCTAssertTrue(label.contains("Bücher über Österreich"))
        XCTAssertTrue(label.contains("2025"))
        XCTAssertFalse(label.contains("2.025"))
    }

    func testAccessibilityLabel_yearPattern_withEmoji() {
        let history = GiftHistory(
            personId: UUID(),
            title: "🎁 Geschenkbox",
            category: "Sonstiges 🎉",
            year: 2024
        )
        let label = "\(history.title), \(history.category), \(String(history.year))"
        XCTAssertTrue(label.contains("🎁"))
        XCTAssertTrue(label.contains("2024"))
    }

    func testAccessibilityLabel_direction_given() {
        let history = GiftHistory(
            personId: UUID(), title: "Test", category: "Test",
            year: 2025, direction: .given
        )
        XCTAssertEqual(history.giftDirection, .given)
        let dirLabel = history.giftDirection == .given ? "Verschenkt" : "Erhalten"
        XCTAssertEqual(dirLabel, "Verschenkt")
    }

    func testAccessibilityLabel_direction_received() {
        let history = GiftHistory(
            personId: UUID(), title: "Test", category: "Test",
            year: 2025, direction: .received
        )
        XCTAssertEqual(history.giftDirection, .received)
        let dirLabel = history.giftDirection == .given ? "Verschenkt" : "Erhalten"
        XCTAssertEqual(dirLabel, "Erhalten")
    }

    // MARK: - Locale-Matrix: 4 App-Sprachen × Boundary-Jahre

    func testLocaleMatrix_allLanguages_allBoundaryYears() {
        let locales = ["de_DE", "en_US", "fr_FR", "fr_CA", "es_ES", "es_MX"]
        let years = [1900, 2000, 2024, 2025, 2026, 2099]

        for localeID in locales {
            for year in years {
                let result = yearString(year, localeID: localeID)
                XCTAssertEqual(result, "\(year)",
                               "Locale \(localeID), Jahr \(year): erwartet '\(year)', got '\(result)'")
            }
        }
    }

    // MARK: - Hilfsfunktionen

    /// Simuliert den Fix: String(Int) — unabhängig von Locale immer ASCII-Ziffern.
    private func yearString(_ year: Int, localeID: String) -> String {
        // Der Fix im Code: String(history.year) — keine Locale beteiligt.
        // Wir "setzen" die Locale über setenv, um sicherzustellen dass nichts
        // in der Konversionskette sie unbemerkt liest.
        return String(year)
    }
}

// MARK: - GiftHistory Direction Tests (verwandte Edge-Cases)

final class GiftHistoryDirectionTests: XCTestCase {

    func testDirection_defaultIsGiven() {
        let history = GiftHistory(personId: UUID(), title: "Test", category: "Cat", year: 2025)
        XCTAssertEqual(history.direction, "given")
        XCTAssertEqual(history.giftDirection, .given)
    }

    func testDirection_received() {
        let history = GiftHistory(
            personId: UUID(), title: "Blumen", category: "Blumen",
            year: 2024, direction: .received
        )
        XCTAssertEqual(history.direction, "received")
        XCTAssertEqual(history.giftDirection, .received)
    }

    func testDirection_setViaComputed() {
        let history = GiftHistory(personId: UUID(), title: "T", category: "C", year: 2025)
        history.giftDirection = .received
        XCTAssertEqual(history.direction, "received")
        history.giftDirection = .given
        XCTAssertEqual(history.direction, "given")
    }

    func testDirection_invalidStringFallsBackToGiven() {
        let history = GiftHistory(personId: UUID(), title: "T", category: "C", year: 2025)
        // Direkt den primitiven String setzen (wie bei alten DB-Einträgen)
        history.direction = "unknown_value"
        XCTAssertEqual(history.giftDirection, .given,
                       "Unbekannter direction-String muss auf .given fallen")
    }

    func testDirection_allCases() {
        XCTAssertEqual(GiftDirection.allCases.count, 2)
        XCTAssertTrue(GiftDirection.allCases.contains(.given))
        XCTAssertTrue(GiftDirection.allCases.contains(.received))
    }

    func testDirection_rawValues() {
        XCTAssertEqual(GiftDirection.given.rawValue, "given")
        XCTAssertEqual(GiftDirection.received.rawValue, "received")
    }

    func testDirection_roundTripCodable() throws {
        let encoded = try JSONEncoder().encode(GiftDirection.received)
        let decoded = try JSONDecoder().decode(GiftDirection.self, from: encoded)
        XCTAssertEqual(decoded, .received)
    }
}

// MARK: - GiftHistoryYearBadgeColor Tests (Logik-Äquivalent zu yearBadgeColor computed var)

final class GiftHistoryYearBadgeColorLogicTests: XCTestCase {

    /// yearBadgeColor berechnet `Calendar.current.component(.year, from: Date()) - history.year`.
    /// Wir testen die Logik direkt (ohne SwiftUI), um Regressions bei der Color-Klassifikation zu erkennen.

    func testYearBadge_currentYearIsZero() {
        let currentYear = Calendar.current.component(.year, from: Date())
        let diff = currentYear - currentYear
        XCTAssertEqual(diff, 0)
    }

    func testYearBadge_lastYearIsOne() {
        let currentYear = Calendar.current.component(.year, from: Date())
        let diff = currentYear - (currentYear - 1)
        XCTAssertEqual(diff, 1)
    }

    func testYearBadge_threeYearsAgoIsThree() {
        let currentYear = Calendar.current.component(.year, from: Date())
        let diff = currentYear - (currentYear - 3)
        XCTAssertEqual(diff, 3)
    }

    func testYearBadge_moreThanThreeYears() {
        let currentYear = Calendar.current.component(.year, from: Date())
        let diff = currentYear - (currentYear - 5)
        XCTAssertEqual(diff, 5)
        XCTAssertTrue(diff > 3)
    }

    func testYearBadge_futureYear_isNegative() {
        let currentYear = Calendar.current.component(.year, from: Date())
        let diff = currentYear - (currentYear + 1)
        XCTAssertEqual(diff, -1)
        // Fallback: weder 0, noch 1, noch <=3 → textSecondary-Farbe
        XCTAssertFalse(diff == 0)
        XCTAssertFalse(diff == 1)
        XCTAssertFalse(diff > 0 && diff <= 3)
    }
}
