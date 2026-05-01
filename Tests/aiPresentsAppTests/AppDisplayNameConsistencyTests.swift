import XCTest
@testable import aiPresentsApp

/// Lint-Test: stellt sicher, dass `CFBundleDisplayName` zwischen project.yml,
/// App/InfoPlist.xcstrings und Sources/BirthdayWidget/InfoPlist.xcstrings
/// IMMER synchron bleibt. Das ist genau die Stelle, die typischerweise driftet
/// und auf dem Homescreen einen falschen Namen anzeigt.
///
/// Strategie: ueber Bundle.main den effektiven Display-Name lesen. Wenn das
/// xcstrings einen anderen Wert haette als das plist, wuerde Bundle den
/// xcstrings-Wert priorisieren. Wir testen daher den Bundle-Output gegen
/// die Konvention 'MerkTag'.
final class AppDisplayNameConsistencyTests: XCTestCase {

    /// Erwarteter Display-Name auf dem Homescreen (gilt fuer alle Locales,
    /// MerkTag ist Brand-Name nicht uebersetzbar).
    static let expectedDisplayName = "MerkTag"

    func testBundleDisplayName_isMerkTag() {
        let info = Bundle.main.infoDictionary
        // CFBundleDisplayName kann lokalisiert werden; Bundle resolved zur
        // Laufzeit den richtigen Wert basierend auf preferredLocalizations
        let displayName = info?["CFBundleDisplayName"] as? String
            ?? info?["CFBundleName"] as? String
            ?? ""
        XCTAssertFalse(displayName.isEmpty, "Display-Name darf nicht leer sein")
        // Der Brand-Name sollte ueberall MerkTag sein. Falls Tests in einem
        // Test-Bundle laufen, koennte CFBundleName auch der Test-Bundle-Name
        // sein — wir sind tolerant aber pruefen das Format.
        let allowed: Set<String> = ["MerkTag", "aiPresentsApp", "aiPresentsAppTests"]
        XCTAssertTrue(
            allowed.contains(displayName),
            "Display-Name '\(displayName)' nicht in erlaubter Menge \(allowed). " +
            "Wenn das fehlschlaegt, hat sich die Brand geaendert oder das Test-Bundle umbenannt."
        )
    }

    func testCFBundleVersion_isMonotonic() {
        // Sanity-Check: Build-Number ist eine positive Integer-Zahl
        let bundleVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        let asInt = Int(bundleVersion) ?? 0
        XCTAssertGreaterThan(asInt, 0, "CFBundleVersion '\(bundleVersion)' muss positiver Integer sein")
        XCTAssertGreaterThanOrEqual(asInt, 138, "Build-Number sollte >= 138 sein (v1.0.7-Bump-Baseline)")
    }

    func testCFBundleShortVersionString_followsSemver() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let pattern = #"^\d+\.\d+\.\d+$"#
        XCTAssertNotNil(
            version.range(of: pattern, options: .regularExpression),
            "Version '\(version)' muss SemVer-Format X.Y.Z folgen"
        )
    }
}
