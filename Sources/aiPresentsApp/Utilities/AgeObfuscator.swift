import Foundation

/// Wandelt exaktes Alter in eine ungefähre Altersgruppe um — für anonymisierte KI-Prompts.
/// Ziel: KI bekommt genug Kontext für altersgerechte Vorschläge, aber kein identifizierbares Alter.
enum AgeObfuscator {

    /// Gibt eine menschliche Altersgruppe zurück: "Kleinkind", "Mitte 30", "Anfang 60" etc.
    static func approximateAge(_ exactAge: Int) -> String {
        let langCode = Locale.current.language.languageCode?.identifier ?? "en"

        switch exactAge {
        case 0...2:
            switch langCode {
            case "de": return "Baby/Kleinkind"
            case "fr": return "bébé"
            case "es": return "bebé"
            default:   return "baby/toddler"
            }
        case 3...5:
            switch langCode {
            case "de": return "Kindergartenkind"
            case "fr": return "tout-petit"
            case "es": return "niño/a pequeño/a"
            default:   return "preschooler"
            }
        case 6...9:
            switch langCode {
            case "de": return "Grundschulkind"
            case "fr": return "enfant"
            case "es": return "niño/a"
            default:   return "elementary school child"
            }
        case 10...12:
            switch langCode {
            case "de": return "Kind (ca. 10–12)"
            case "fr": return "enfant (env. 10–12 ans)"
            case "es": return "niño/a (aprox. 10–12)"
            default:   return "child (approx. 10–12)"
            }
        case 13...15:
            switch langCode {
            case "de": return "junger Teenager"
            case "fr": return "adolescent(e)"
            case "es": return "adolescente"
            default:   return "young teenager"
            }
        case 16...17:
            switch langCode {
            case "de": return "Teenager"
            case "fr": return "adolescent(e)"
            case "es": return "adolescente"
            default:   return "teenager"
            }
        case 18...19:
            switch langCode {
            case "de": return "junger Erwachsener (ca. 18–19)"
            case "fr": return "jeune adulte (env. 18–19 ans)"
            case "es": return "adulto/a joven (aprox. 18–19)"
            default:   return "young adult (approx. 18–19)"
            }
        default:
            return approximateAdultAge(exactAge, langCode: langCode)
        }
    }

    // MARK: - Private

    /// Für Erwachsene (20+): "Anfang/Mitte/Ende X0"
    private static func approximateAdultAge(_ age: Int, langCode: String) -> String {
        let decade = (age / 10) * 10
        let position = age % 10

        switch langCode {
        case "de":
            let prefix: String
            switch position {
            case 0...3: prefix = "Anfang"
            case 4...6: prefix = "Mitte"
            default:    prefix = "Ende"
            }
            return "\(prefix) \(decade)"
        case "fr":
            let prefix: String
            switch position {
            case 0...3: prefix = "début de la"
            case 4...6: prefix = "milieu de la"
            default:    prefix = "fin de la"
            }
            let suffix: String
            switch decade {
            case 20:  suffix = "vingtaine"
            case 30:  suffix = "trentaine"
            case 40:  suffix = "quarantaine"
            case 50:  suffix = "cinquantaine"
            case 60:  suffix = "soixantaine"
            case 70:  suffix = "soixante-dixaine"
            case 80:  suffix = "huitantaine"
            case 90:  suffix = "nonantaine"
            default:  suffix = "\(decade)aine"
            }
            return "\(prefix) \(suffix)"
        case "es":
            let prefix: String
            switch position {
            case 0...3: prefix = "principios de los"
            case 4...6: prefix = "mediados de los"
            default:    prefix = "finales de los"
            }
            return "\(prefix) \(decade)"
        default:
            let prefix: String
            switch position {
            case 0...3: prefix = "early"
            case 4...6: prefix = "mid"
            default:    prefix = "late"
            }
            return "\(prefix) \(decade)s"
        }
    }
}
