import Foundation

/// Wandelt exaktes Alter in eine ungefähre Altersgruppe um — für anonymisierte KI-Prompts.
/// Ziel: KI bekommt genug Kontext für altersgerechte Vorschläge, aber kein identifizierbares Alter.
enum AgeObfuscator {

    /// Gibt eine menschliche Altersgruppe zurück: "Kleinkind", "Mitte 30", "Anfang 60" etc.
    static func approximateAge(_ exactAge: Int) -> String {
        let isGerman = Locale.current.language.languageCode?.identifier == "de"

        switch exactAge {
        case 0...2:
            return isGerman ? "Baby/Kleinkind" : "baby/toddler"
        case 3...5:
            return isGerman ? "Kindergartenkind" : "preschooler"
        case 6...9:
            return isGerman ? "Grundschulkind" : "elementary school child"
        case 10...12:
            return isGerman ? "Kind (ca. 10–12)" : "child (approx. 10–12)"
        case 13...15:
            return isGerman ? "junger Teenager" : "young teenager"
        case 16...17:
            return isGerman ? "Teenager" : "teenager"
        case 18...19:
            return isGerman ? "junger Erwachsener (ca. 18–19)" : "young adult (approx. 18–19)"
        default:
            return approximateAdultAge(exactAge, isGerman: isGerman)
        }
    }

    // MARK: - Private

    /// Für Erwachsene (20+): "Anfang/Mitte/Ende X0"
    private static func approximateAdultAge(_ age: Int, isGerman: Bool) -> String {
        let decade = (age / 10) * 10
        let position = age % 10

        let prefix: String
        switch position {
        case 0...3:
            prefix = isGerman ? "Anfang" : "early"
        case 4...6:
            prefix = isGerman ? "Mitte" : "mid"
        default:
            prefix = isGerman ? "Ende" : "late"
        }

        return "\(prefix) \(decade)"
    }
}
