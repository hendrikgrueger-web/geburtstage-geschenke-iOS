import XCTest
@testable import aiPresentsApp

final class AgeObfuscatorTests: XCTestCase {

    // MARK: - Altersgruppen-Mapping (sprach-unabhängig, prüft nur nicht-leer)

    func testBabyToddler_ages0to2() {
        for age in 0...2 {
            let result = AgeObfuscator.approximateAge(age)
            XCTAssertFalse(result.isEmpty, "Age \(age) should return non-empty string")
        }
    }

    func testPreschooler_ages3to5() {
        for age in 3...5 {
            let result = AgeObfuscator.approximateAge(age)
            XCTAssertFalse(result.isEmpty, "Age \(age) should return non-empty string")
        }
    }

    func testElementarySchool_ages6to9() {
        for age in 6...9 {
            let result = AgeObfuscator.approximateAge(age)
            XCTAssertFalse(result.isEmpty, "Age \(age) should return non-empty string")
        }
    }

    func testTween_ages10to12() {
        for age in 10...12 {
            let result = AgeObfuscator.approximateAge(age)
            XCTAssertFalse(result.isEmpty, "Age \(age) should return non-empty string")
        }
    }

    func testYoungTeenager_ages13to15() {
        for age in 13...15 {
            let result = AgeObfuscator.approximateAge(age)
            XCTAssertFalse(result.isEmpty, "Age \(age) should return non-empty string")
        }
    }

    func testTeenager_ages16to17() {
        for age in 16...17 {
            let result = AgeObfuscator.approximateAge(age)
            XCTAssertFalse(result.isEmpty, "Age \(age) should return non-empty string")
        }
    }

    func testYoungAdult_ages18to19() {
        for age in 18...19 {
            let result = AgeObfuscator.approximateAge(age)
            XCTAssertFalse(result.isEmpty, "Age \(age) should return non-empty string")
        }
    }

    // MARK: - Erwachsene (20+): Anfang/Mitte/Ende Dekade

    func testAdult_early20s() {
        let result = AgeObfuscator.approximateAge(21)
        XCTAssertFalse(result.isEmpty)
        // "Anfang 20" (de), "early 20s" (en), etc.
    }

    func testAdult_mid30s() {
        let result = AgeObfuscator.approximateAge(35)
        XCTAssertFalse(result.isEmpty)
    }

    func testAdult_late40s() {
        let result = AgeObfuscator.approximateAge(48)
        XCTAssertFalse(result.isEmpty)
    }

    func testAdult_age50exact() {
        let result = AgeObfuscator.approximateAge(50)
        XCTAssertFalse(result.isEmpty)
    }

    func testAdult_age99() {
        let result = AgeObfuscator.approximateAge(99)
        XCTAssertFalse(result.isEmpty)
    }

    func testAdult_age100() {
        let result = AgeObfuscator.approximateAge(100)
        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - Edge Cases

    func testAge0_returnsNonEmpty() {
        let result = AgeObfuscator.approximateAge(0)
        XCTAssertFalse(result.isEmpty, "Age 0 should return a result")
    }

    func testNegativeAge_returnsNonEmpty() {
        // Negative Werte sollten nicht crashen
        let result = AgeObfuscator.approximateAge(-1)
        XCTAssertFalse(result.isEmpty, "Negative age should not crash and return a string")
    }

    func testNegativeAge_large_returnsNonEmpty() {
        let result = AgeObfuscator.approximateAge(-100)
        XCTAssertFalse(result.isEmpty, "Large negative age should not crash")
    }

    func testVeryHighAge_returnsNonEmpty() {
        let result = AgeObfuscator.approximateAge(120)
        XCTAssertFalse(result.isEmpty, "Age 120 should return a result")
    }

    // MARK: - Dekaden-Position korrekt (Anfang/Mitte/Ende)

    func testAdultPositions_earlyDecade() {
        // Alter X0–X3 = "Anfang" / "early"
        for offset in 0...3 {
            let age = 20 + offset
            let result = AgeObfuscator.approximateAge(age)
            XCTAssertFalse(result.isEmpty, "Age \(age) should map to early position")
        }
    }

    func testAdultPositions_midDecade() {
        // Alter X4–X6 = "Mitte" / "mid"
        for offset in 4...6 {
            let age = 30 + offset
            let result = AgeObfuscator.approximateAge(age)
            XCTAssertFalse(result.isEmpty, "Age \(age) should map to mid position")
        }
    }

    func testAdultPositions_lateDecade() {
        // Alter X7–X9 = "Ende" / "late"
        for offset in 7...9 {
            let age = 40 + offset
            let result = AgeObfuscator.approximateAge(age)
            XCTAssertFalse(result.isEmpty, "Age \(age) should map to late position")
        }
    }

    // MARK: - Vollständiger Dekaden-Sweep (20-99)

    func testAllAdultAges_returnNonEmpty() {
        for age in 20...99 {
            let result = AgeObfuscator.approximateAge(age)
            XCTAssertFalse(result.isEmpty, "Age \(age) should produce a non-empty label")
        }
    }

    // MARK: - Vollständiger Kinder-Sweep (0-19)

    func testAllChildAges_returnNonEmpty() {
        for age in 0...19 {
            let result = AgeObfuscator.approximateAge(age)
            XCTAssertFalse(result.isEmpty, "Age \(age) should produce a non-empty label")
        }
    }

    // MARK: - Keine identifizierenden Daten (DSGVO-Kern)

    func testResult_doesNotContainExactAge() {
        // Die approximierte Altersgruppe darf NICHT das exakte Alter als eigenständige Zahl enthalten
        // (ausgenommen Dekaden-Vielfache wie "20", "30" etc., die als Gruppenname verwendet werden)
        let age = 37
        let result = AgeObfuscator.approximateAge(age)
        XCTAssertFalse(result.contains("37"),
                       "Result '\(result)' should not contain exact age 37")
    }

    func testResult_age23_doesNotContainExactAge() {
        let result = AgeObfuscator.approximateAge(23)
        XCTAssertFalse(result.contains("23"),
                       "Result '\(result)' should not contain exact age 23")
    }

    func testResult_age48_doesNotContainExactAge() {
        let result = AgeObfuscator.approximateAge(48)
        XCTAssertFalse(result.contains("48"),
                       "Result '\(result)' should not contain exact age 48")
    }

    // MARK: - Verschiedene Altersgruppen sind tatsächlich unterschiedlich

    func testDifferentAgeGroups_produceDifferentResults() {
        let baby = AgeObfuscator.approximateAge(1)
        let teen = AgeObfuscator.approximateAge(15)
        let adult = AgeObfuscator.approximateAge(35)

        XCTAssertNotEqual(baby, teen, "Baby and teen should have different labels")
        XCTAssertNotEqual(teen, adult, "Teen and adult should have different labels")
        XCTAssertNotEqual(baby, adult, "Baby and adult should have different labels")
    }

    func testDifferentDecades_produceDifferentResults() {
        let twenties = AgeObfuscator.approximateAge(25)
        let thirties = AgeObfuscator.approximateAge(35)
        let forties = AgeObfuscator.approximateAge(45)

        XCTAssertNotEqual(twenties, thirties)
        XCTAssertNotEqual(thirties, forties)
    }

    func testDifferentPositions_produceDifferentResults() {
        let early = AgeObfuscator.approximateAge(31)
        let mid = AgeObfuscator.approximateAge(35)
        let late = AgeObfuscator.approximateAge(38)

        XCTAssertNotEqual(early, mid, "Early and mid 30s should differ")
        XCTAssertNotEqual(mid, late, "Mid and late 30s should differ")
    }
}
