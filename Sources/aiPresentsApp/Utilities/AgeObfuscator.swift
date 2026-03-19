import Foundation

/// Wandelt exaktes Alter in eine ungefähre Altersgruppe um — für anonymisierte KI-Prompts.
/// Ziel: KI bekommt genug Kontext für altersgerechte Vorschläge, aber kein identifizierbares Alter.
enum AgeObfuscator {

    // MARK: - Age Group Labels

    /// Lokalisierte Labels pro Altersgruppe und Sprache.
    private static let ageGroupLabels: [String: [String: String]] = [
        "babyToddler": [
            "de": "Baby/Kleinkind",
            "en": "baby/toddler",
            "fr": "bébé",
            "es": "bebé"
        ],
        "preschooler": [
            "de": "Kindergartenkind",
            "en": "preschooler",
            "fr": "tout-petit",
            "es": "niño/a pequeño/a"
        ],
        "elementaryChild": [
            "de": "Grundschulkind",
            "en": "elementary school child",
            "fr": "enfant",
            "es": "niño/a"
        ],
        "child10to12": [
            "de": "Kind (ca. 10–12)",
            "en": "child (approx. 10–12)",
            "fr": "enfant (env. 10–12 ans)",
            "es": "niño/a (aprox. 10–12)"
        ],
        "youngTeenager": [
            "de": "junger Teenager",
            "en": "young teenager",
            "fr": "adolescent(e)",
            "es": "adolescente"
        ],
        "teenager": [
            "de": "Teenager",
            "en": "teenager",
            "fr": "adolescent(e)",
            "es": "adolescente"
        ],
        "youngAdult": [
            "de": "junger Erwachsener (ca. 18–19)",
            "en": "young adult (approx. 18–19)",
            "fr": "jeune adulte (env. 18–19 ans)",
            "es": "adulto/a joven (aprox. 18–19)"
        ]
    ]

    // MARK: - Adult Position Prefixes

    /// Lokalisierte Positionspräfixe für Erwachsene (Anfang/Mitte/Ende).
    private static let adultPositionPrefixes: [String: [String: String]] = [
        "early": [
            "de": "Anfang",
            "en": "early",
            "fr": "début de la",
            "es": "principios de los"
        ],
        "mid": [
            "de": "Mitte",
            "en": "mid",
            "fr": "milieu de la",
            "es": "mediados de los"
        ],
        "late": [
            "de": "Ende",
            "en": "late",
            "fr": "fin de la",
            "es": "finales de los"
        ]
    ]

    /// Französische Dekaden-Suffixe.
    private static let frenchDecadeSuffixes: [Int: String] = [
        20: "vingtaine",
        30: "trentaine",
        40: "quarantaine",
        50: "cinquantaine",
        60: "soixantaine",
        70: "soixante-dixaine",
        80: "huitantaine",
        90: "nonantaine"
    ]

    // MARK: - Public API

    /// Gibt eine menschliche Altersgruppe zurück: "Kleinkind", "Mitte 30", "Anfang 60" etc.
    static func approximateAge(_ exactAge: Int) -> String {
        let langCode = Locale.current.language.languageCode?.identifier ?? "en"

        if exactAge < 20 {
            let groupKey = ageGroupKey(for: exactAge)
            return ageGroupLabels[groupKey]?[langCode]
                ?? ageGroupLabels[groupKey]?["en"]
                ?? "unknown"
        }

        return approximateAdultAge(exactAge, langCode: langCode)
    }

    // MARK: - Private

    /// Ermittelt den Lookup-Key für Kinder/Jugendliche.
    private static func ageGroupKey(for age: Int) -> String {
        switch age {
        case 0...2:  return "babyToddler"
        case 3...5:  return "preschooler"
        case 6...9:  return "elementaryChild"
        case 10...12: return "child10to12"
        case 13...15: return "youngTeenager"
        case 16...17: return "teenager"
        default:      return "youngAdult" // 18-19
        }
    }

    /// Für Erwachsene (20+): "Anfang/Mitte/Ende X0"
    private static func approximateAdultAge(
        _ age: Int,
        langCode: String
    ) -> String {
        let decade = (age / 10) * 10
        let position = age % 10

        let positionKey: String
        switch position {
        case 0...3: positionKey = "early"
        case 4...6: positionKey = "mid"
        default:    positionKey = "late"
        }

        let prefix = adultPositionPrefixes[positionKey]?[langCode]
            ?? adultPositionPrefixes[positionKey]?["en"]
            ?? "early"

        switch langCode {
        case "fr":
            let suffix = frenchDecadeSuffixes[decade] ?? "\(decade)aine"
            return "\(prefix) \(suffix)"
        case "es":
            return "\(prefix) \(decade)"
        case "de":
            return "\(prefix) \(decade)"
        default:
            return "\(prefix) \(decade)s"
        }
    }
}
