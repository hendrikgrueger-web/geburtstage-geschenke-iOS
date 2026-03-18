import XCTest
@testable import aiPresentsApp

final class GenderInferenceTests: XCTestCase {

    // MARK: - Beziehungstyp-basierte Ableitung (weiblich)

    func testRelation_mutter_isFemale() {
        let result = GenderInference.infer(relation: "Mutter", firstName: "")
        XCTAssertEqual(result, .female)
    }

    func testRelation_schwester_isFemale() {
        let result = GenderInference.infer(relation: "Schwester", firstName: "")
        XCTAssertEqual(result, .female)
    }

    func testRelation_tochter_isFemale() {
        let result = GenderInference.infer(relation: "Tochter", firstName: "")
        XCTAssertEqual(result, .female)
    }

    func testRelation_oma_isFemale() {
        let result = GenderInference.infer(relation: "Oma", firstName: "")
        XCTAssertEqual(result, .female)
    }

    func testRelation_grossmutter_isFemale() {
        let result = GenderInference.infer(relation: "Großmutter", firstName: "")
        XCTAssertEqual(result, .female)
    }

    func testRelation_tante_isFemale() {
        let result = GenderInference.infer(relation: "Tante", firstName: "")
        XCTAssertEqual(result, .female)
    }

    func testRelation_nichte_isFemale() {
        let result = GenderInference.infer(relation: "Nichte", firstName: "")
        XCTAssertEqual(result, .female)
    }

    func testRelation_schwaegerin_isFemale() {
        let result = GenderInference.infer(relation: "Schwägerin", firstName: "")
        XCTAssertEqual(result, .female)
    }

    // Englische Varianten
    func testRelation_mother_isFemale() {
        let result = GenderInference.infer(relation: "mother", firstName: "")
        XCTAssertEqual(result, .female)
    }

    func testRelation_sister_isFemale() {
        let result = GenderInference.infer(relation: "sister", firstName: "")
        XCTAssertEqual(result, .female)
    }

    func testRelation_daughter_isFemale() {
        let result = GenderInference.infer(relation: "daughter", firstName: "")
        XCTAssertEqual(result, .female)
    }

    func testRelation_grandmother_isFemale() {
        let result = GenderInference.infer(relation: "grandmother", firstName: "")
        XCTAssertEqual(result, .female)
    }

    func testRelation_aunt_isFemale() {
        let result = GenderInference.infer(relation: "aunt", firstName: "")
        XCTAssertEqual(result, .female)
    }

    func testRelation_niece_isFemale() {
        let result = GenderInference.infer(relation: "niece", firstName: "")
        XCTAssertEqual(result, .female)
    }

    // MARK: - Beziehungstyp-basierte Ableitung (männlich)

    func testRelation_vater_isMale() {
        let result = GenderInference.infer(relation: "Vater", firstName: "")
        XCTAssertEqual(result, .male)
    }

    func testRelation_bruder_isMale() {
        let result = GenderInference.infer(relation: "Bruder", firstName: "")
        XCTAssertEqual(result, .male)
    }

    func testRelation_sohn_isMale() {
        let result = GenderInference.infer(relation: "Sohn", firstName: "")
        XCTAssertEqual(result, .male)
    }

    func testRelation_opa_isMale() {
        let result = GenderInference.infer(relation: "Opa", firstName: "")
        XCTAssertEqual(result, .male)
    }

    func testRelation_grossvater_isMale() {
        let result = GenderInference.infer(relation: "Großvater", firstName: "")
        XCTAssertEqual(result, .male)
    }

    func testRelation_onkel_isMale() {
        let result = GenderInference.infer(relation: "Onkel", firstName: "")
        XCTAssertEqual(result, .male)
    }

    func testRelation_neffe_isMale() {
        let result = GenderInference.infer(relation: "Neffe", firstName: "")
        XCTAssertEqual(result, .male)
    }

    func testRelation_schwager_isMale() {
        let result = GenderInference.infer(relation: "Schwager", firstName: "")
        XCTAssertEqual(result, .male)
    }

    // Englische Varianten
    func testRelation_father_isMale() {
        let result = GenderInference.infer(relation: "father", firstName: "")
        XCTAssertEqual(result, .male)
    }

    func testRelation_brother_isMale() {
        let result = GenderInference.infer(relation: "brother", firstName: "")
        XCTAssertEqual(result, .male)
    }

    func testRelation_son_isMale() {
        let result = GenderInference.infer(relation: "son", firstName: "")
        XCTAssertEqual(result, .male)
    }

    func testRelation_grandfather_isMale() {
        let result = GenderInference.infer(relation: "grandfather", firstName: "")
        XCTAssertEqual(result, .male)
    }

    func testRelation_uncle_isMale() {
        let result = GenderInference.infer(relation: "uncle", firstName: "")
        XCTAssertEqual(result, .male)
    }

    func testRelation_nephew_isMale() {
        let result = GenderInference.infer(relation: "nephew", firstName: "")
        XCTAssertEqual(result, .male)
    }

    // MARK: - Neutrale Beziehungstypen (Fallback auf Vorname)

    func testRelation_partnerin_fallsBackToName() {
        let result = GenderInference.infer(relation: "Partner/in", firstName: "Anna")
        XCTAssertEqual(result, .female, "Partner/in should not resolve from relation, but from name 'Anna'")
    }

    func testRelation_freundin_fallsBackToName() {
        let result = GenderInference.infer(relation: "Freund/in", firstName: "Max")
        XCTAssertEqual(result, .male, "Freund/in should fallback to name inference")
    }

    func testRelation_kollegin_fallsBackToName() {
        let result = GenderInference.infer(relation: "Kollege/in", firstName: "")
        XCTAssertEqual(result, .neutral, "Kollege/in with empty name should be neutral")
    }

    func testRelation_kind_fallsBackToName() {
        let result = GenderInference.infer(relation: "Kind", firstName: "")
        XCTAssertEqual(result, .neutral, "Kind with empty name should be neutral")
    }

    func testRelation_sonstige_fallsBackToName() {
        let result = GenderInference.infer(relation: "Sonstige", firstName: "Laura")
        XCTAssertEqual(result, .female, "Sonstige should fallback to name 'Laura'")
    }

    // MARK: - Vorname-basierte Ableitung

    func testFirstName_anna_isFemale() {
        let result = GenderInference.infer(relation: "", firstName: "Anna")
        XCTAssertEqual(result, .female)
    }

    func testFirstName_maria_isFemale() {
        let result = GenderInference.infer(relation: "", firstName: "Maria")
        XCTAssertEqual(result, .female)
    }

    func testFirstName_emma_isFemale() {
        let result = GenderInference.infer(relation: "", firstName: "Emma")
        XCTAssertEqual(result, .female)
    }

    func testFirstName_inga_isFemale() {
        let result = GenderInference.infer(relation: "", firstName: "Inga")
        XCTAssertEqual(result, .female)
    }

    func testFirstName_max_isMale() {
        let result = GenderInference.infer(relation: "", firstName: "Max")
        XCTAssertEqual(result, .male)
    }

    func testFirstName_peter_isMale() {
        let result = GenderInference.infer(relation: "", firstName: "Peter")
        XCTAssertEqual(result, .male)
    }

    func testFirstName_hendrik_isMale() {
        let result = GenderInference.infer(relation: "", firstName: "Hendrik")
        XCTAssertEqual(result, .male)
    }

    func testFirstName_thomas_isMale() {
        let result = GenderInference.infer(relation: "", firstName: "Thomas")
        XCTAssertEqual(result, .male)
    }

    func testFirstName_unknown_isNeutral() {
        let result = GenderInference.infer(relation: "", firstName: "Xyzzy")
        XCTAssertEqual(result, .neutral, "Unknown name should be neutral")
    }

    // MARK: - Priorität: Beziehungstyp schlägt Vornamen

    func testRelation_overrides_firstName() {
        // "Mutter" ist weiblich, obwohl "Max" männlich wäre
        let result = GenderInference.infer(relation: "Mutter", firstName: "Max")
        XCTAssertEqual(result, .female, "Relation 'Mutter' should override male name 'Max'")
    }

    func testRelation_vater_overrides_femaleName() {
        let result = GenderInference.infer(relation: "Vater", firstName: "Anna")
        XCTAssertEqual(result, .male, "Relation 'Vater' should override female name 'Anna'")
    }

    // MARK: - Case-Insensitivität

    func testRelation_caseInsensitive_uppercase() {
        let result = GenderInference.infer(relation: "MUTTER", firstName: "")
        XCTAssertEqual(result, .female, "Relation matching should be case-insensitive")
    }

    func testRelation_caseInsensitive_mixed() {
        let result = GenderInference.infer(relation: "vAtEr", firstName: "")
        XCTAssertEqual(result, .male, "Relation matching should be case-insensitive")
    }

    func testFirstName_caseInsensitive() {
        let result = GenderInference.infer(relation: "", firstName: "ANNA")
        XCTAssertEqual(result, .female, "First name matching should be case-insensitive")
    }

    // MARK: - Leere Strings

    func testEmptyRelation_emptyName_isNeutral() {
        let result = GenderInference.infer(relation: "", firstName: "")
        XCTAssertEqual(result, .neutral, "Empty inputs should return neutral")
    }

    func testEmptyRelation_unknownName_isNeutral() {
        let result = GenderInference.infer(relation: "", firstName: "Qwertz")
        XCTAssertEqual(result, .neutral)
    }

    // MARK: - Unbekannte Beziehungstypen

    func testUnknownRelation_fallsBackToName() {
        let result = GenderInference.infer(relation: "Nachbar", firstName: "Laura")
        XCTAssertEqual(result, .female, "Unknown relation should fallback to name inference")
    }

    func testUnknownRelation_unknownName_isNeutral() {
        let result = GenderInference.infer(relation: "Mentor", firstName: "Qwertz")
        XCTAssertEqual(result, .neutral)
    }

    // MARK: - Vorname mit Leerzeichen (Multi-Part)

    func testFirstName_withSpaces_usesFirstPart() {
        let result = GenderInference.infer(relation: "", firstName: "Anna Maria")
        XCTAssertEqual(result, .female, "Should use first part 'Anna' for inference")
    }

    func testFirstName_leadingSpaces_trimmed() {
        let result = GenderInference.infer(relation: "", firstName: "  Max  ")
        XCTAssertEqual(result, .male, "Leading/trailing spaces should be trimmed")
    }

    // MARK: - Labels (localizedLabel, englishLabel)

    func testGender_male_englishLabel() {
        XCTAssertEqual(GenderInference.Gender.male.englishLabel, "male")
    }

    func testGender_female_englishLabel() {
        XCTAssertEqual(GenderInference.Gender.female.englishLabel, "female")
    }

    func testGender_neutral_englishLabel() {
        XCTAssertEqual(GenderInference.Gender.neutral.englishLabel, "person")
    }

    func testGender_localizedLabel_notEmpty() {
        // localizedLabel hängt von der Locale ab, aber darf nie leer sein
        XCTAssertFalse(GenderInference.Gender.male.localizedLabel.isEmpty)
        XCTAssertFalse(GenderInference.Gender.female.localizedLabel.isEmpty)
        XCTAssertFalse(GenderInference.Gender.neutral.localizedLabel.isEmpty)
    }

    // MARK: - Gender rawValue

    func testGender_rawValues() {
        XCTAssertEqual(GenderInference.Gender.male.rawValue, "male")
        XCTAssertEqual(GenderInference.Gender.female.rawValue, "female")
        XCTAssertEqual(GenderInference.Gender.neutral.rawValue, "neutral")
    }

    // MARK: - Sendable Conformance (compile-time, aber wir prüfen Typ)

    func testGender_isSendable() {
        let gender: GenderInference.Gender = .male
        // Wenn das kompiliert, ist Sendable erfüllt
        let _: any Sendable = gender
        XCTAssertTrue(true, "Gender conforms to Sendable")
    }
}
