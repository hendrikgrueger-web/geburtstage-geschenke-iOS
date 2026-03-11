import Foundation

/// Leitet das Geschlecht lokal aus Beziehungstyp und Vorname ab — für anonymisierte KI-Prompts.
/// Keine Daten verlassen das Gerät.
enum GenderInference {

    enum Gender: String, Sendable {
        case male
        case female
        case neutral

        var localizedLabel: String {
            switch self {
            case .male: String(localized: "männlich", table: "AIContent")
            case .female: String(localized: "weiblich", table: "AIContent")
            case .neutral: String(localized: "Person", table: "AIContent")
            }
        }

        /// Für englische KI-Prompts
        var englishLabel: String {
            switch self {
            case .male: "male"
            case .female: "female"
            case .neutral: "person"
            }
        }
    }

    // MARK: - Inference

    /// Leitet das Geschlecht ab: zuerst aus der Beziehung, dann aus dem Vornamen.
    static func infer(relation: String, firstName: String) -> Gender {
        if let fromRelation = inferFromRelation(relation) {
            return fromRelation
        }
        return inferFromFirstName(firstName)
    }

    // MARK: - Relation-basiert (primär)

    private static func inferFromRelation(_ relation: String) -> Gender? {
        let lower = relation.lowercased()

        // Weiblich
        if ["mutter", "schwester", "tochter", "oma", "großmutter", "tante", "nichte", "schwägerin",
            "mother", "sister", "daughter", "grandmother", "aunt", "niece"].contains(lower) {
            return .female
        }

        // Männlich
        if ["vater", "bruder", "sohn", "opa", "großvater", "onkel", "neffe", "schwager",
            "father", "brother", "son", "grandfather", "uncle", "nephew"].contains(lower) {
            return .male
        }

        // Neutral (bewusst keine Annahme)
        // "Partner/in", "Freund/in", "Kollege/in", "Kind", "Sonstige" → nil
        return nil
    }

    // MARK: - Vorname-basiert (Fallback)

    private static func inferFromFirstName(_ name: String) -> Gender {
        let lower = name.lowercased().trimmingCharacters(in: .whitespaces)
        let firstName = String(lower.split(separator: " ").first ?? Substring(lower))

        if femaleNames.contains(firstName) { return .female }
        if maleNames.contains(firstName) { return .male }
        return .neutral
    }

    // MARK: - Häufige deutsche Vornamen (~100 pro Geschlecht)

    private static let femaleNames: Set<String> = [
        "anna", "maria", "emma", "lena", "laura", "julia", "sarah", "sophie", "lisa", "lea",
        "hannah", "katharina", "johanna", "marie", "lara", "nina", "jana", "christina", "stefanie", "sandra",
        "melanie", "nicole", "andrea", "claudia", "petra", "sabine", "monika", "martina", "karin", "susanne",
        "birgit", "heike", "gabriele", "ursula", "renate", "ingrid", "helga", "eva", "charlotte", "emilia",
        "mia", "ella", "clara", "ida", "greta", "frieda", "luisa", "amelie", "nele", "lina",
        "elisa", "paula", "rosa", "martha", "helena", "victoria", "carla", "antonia", "theresa", "franziska",
        "margarete", "elisabeth", "dorothea", "angelika", "barbara", "brigitte", "anja", "tanja", "simone", "silke",
        "miriam", "diana", "vera", "sonja", "katja", "nadine", "manuela", "daniela", "natalie", "carina",
        "vanessa", "jessica", "jennifer", "michelle", "alina", "jasmin", "isabel", "sophia", "stella", "maya",
        "annika", "marlene", "inga", "svenja", "maike", "imke", "wiebke", "frauke", "birte", "jule"
    ]

    private static let maleNames: Set<String> = [
        "peter", "thomas", "michael", "andreas", "stefan", "christian", "martin", "markus", "daniel", "matthias",
        "alexander", "tobias", "sebastian", "jan", "tim", "lukas", "felix", "jonas", "paul", "leon",
        "maximilian", "david", "philipp", "florian", "benjamin", "niklas", "moritz", "julian", "simon", "oliver",
        "frank", "jürgen", "klaus", "werner", "hans", "dieter", "manfred", "karl", "heinz", "gerhard",
        "rainer", "bernd", "wolfgang", "helmut", "günter", "friedrich", "norbert", "walter", "ernst", "rudolf",
        "noah", "elias", "finn", "liam", "henry", "emil", "theo", "ben", "max", "leo",
        "oskar", "anton", "carl", "hugo", "fritz", "otto", "arthur", "ludwig", "georg", "konrad",
        "erik", "lars", "sven", "kai", "uwe", "jens", "dirk", "ralf", "holger", "thorsten",
        "marc", "patrick", "dennis", "marcel", "kevin", "robin", "nico", "luca", "fabian", "dominik",
        "robert", "johannes", "christoph", "benedikt", "hendrik", "malte", "torben", "lennart", "mats", "nils"
    ]
}
