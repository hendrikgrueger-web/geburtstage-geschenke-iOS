import Foundation

// Foundation Models (Apple Intelligence) — iOS 26+, A17 Pro / A18 / A19.
// #if canImport sorgt für Kompatibilität mit älterem Xcode.
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - @Generable Ausgabe-Structs
//
// Apple's empfohlener Weg für strukturierte Ausgaben ("Guided Generation").
// JSON im Prompt führt zu GenerationError -1 — @Generable ist die korrekte Methode.
// Das Modell befüllt die Swift-Struct direkt, ohne JSON-Parsing.

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable
struct GiftSuggestionsOutput {
    var suggestions: [GiftItem]

    @Generable
    struct GiftItem {
        /// Konkreter, kaufbarer Geschenkname (z.B. "Kochkurs Pasta & Risotto")
        var title: String
        /// Kurze persönliche Begründung, warum dieses Geschenk passt (1–2 Sätze)
        var reason: String
    }
}

@available(iOS 26.0, *)
@Generable
struct BirthdayMessageOutput {
    /// Persönliche Anrede (z.B. "Lieber Max,")
    var greeting: String
    /// Herzlicher Nachrichtentext, 3–5 Sätze
    var body: String
}
#endif

// MARK: - Sendable Kontext-Structs
// Werden genutzt, um SwiftData-Objekte (non-Sendable) sicher über Actor-Grenzen zu übergeben.

private struct GiftContext: Sendable {
    let name: String
    let age: Int
    let relation: String
    let zodiac: String
    let daysUntil: Int?
    let tags: [String]
    let pastGiftTitles: [String] // Nur Titel, kein ganzes GiftHistory-Objekt
}

private struct BirthdayContext: Sendable {
    let name: String
    let age: Int
    let relation: String
    let zodiac: String
    let lastGiftTitle: String?
    let lastGiftYear: Int?
}

// MARK: - AIService

/// KI-Service für Geschenkvorschläge und Geburtstagsgrüße.
///
/// ## Datenschutz: 100% lokal
/// Alle Verarbeitung findet via Apple Intelligence auf dem Gerät statt.
/// Kein Netzwerkzugriff, kein API-Key, kein Drittanbieter.
///
/// ## Voraussetzungen
/// - iOS 26.0+, A17 Pro / A18 / A19 (iPhone 16e / A16 wird NICHT unterstützt)
/// - Apple Intelligence in Einstellungen aktiviert
///
/// ## Fallback
/// Demo-Modus wenn Apple Intelligence nicht verfügbar ist.
struct AIService {
    static let shared = AIService()
    private init() {}

    // MARK: - Verfügbarkeit

    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.isAvailable
        }
        #endif
        return false
    }

    // MARK: - Öffentliche API (@MainActor — SwiftData-Objekte extrahieren)

    @MainActor
    func generateGiftIdeas(
        for person: PersonRef,
        budgetMin: Double,
        budgetMax: Double,
        tags: [String],
        pastGifts: [GiftHistory]
    ) async throws -> [GiftSuggestion] {

        // Daten auf @MainActor in Sendable-Struct extrahieren
        let context = GiftContext(
            name: person.displayName,
            age: BirthdayDateHelper.age(from: person.birthday),
            relation: person.relation,
            zodiac: BirthdayDateHelper.zodiacSign(from: person.birthday),
            daysUntil: BirthdayDateHelper.daysUntilBirthday(from: person.birthday),
            tags: tags,
            pastGiftTitles: pastGifts.map { "\($0.title) (\($0.year))" }
        )
        let budgetRange = (min: budgetMin, max: budgetMax)

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), SystemLanguageModel.default.isAvailable {
            return try await generateGiftIdeasWithAI(context: context, budget: budgetRange)
        }
        #endif
        return demoSuggestions(relation: context.relation, zodiac: context.zodiac, age: context.age)
    }

    @MainActor
    func generateBirthdayMessage(for person: PersonRef, pastGifts: [GiftHistory] = []) async throws -> BirthdayMessage {

        let lastGift = pastGifts.sorted(by: { $0.year > $1.year }).first
        let context = BirthdayContext(
            name: person.displayName,
            age: BirthdayDateHelper.age(from: person.birthday),
            relation: person.relation,
            zodiac: BirthdayDateHelper.zodiacSign(from: person.birthday),
            lastGiftTitle: lastGift?.title,
            lastGiftYear: lastGift.map { $0.year }
        )

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), SystemLanguageModel.default.isAvailable {
            return try await generateBirthdayMessageWithAI(context: context)
        }
        #endif
        return demoBirthdayMessage(name: context.name, relation: context.relation, zodiac: context.zodiac)
    }

    // MARK: - Foundation Models (nonisolated, empfängt nur Sendable-Typen)

    @available(iOS 26.0, *)
    private func generateGiftIdeasWithAI(
        context: GiftContext,
        budget: (min: Double, max: Double)
    ) async throws -> [GiftSuggestion] {
        #if canImport(FoundationModels)

        var prompt = """
        Erstelle 5 passende Geschenkideen für \(context.name), \(context.age) Jahre, \(context.relation).
        Sternzeichen: \(context.zodiac).
        Budget: \(Int(budget.min))–\(Int(budget.max)) Euro (strikt einhalten).
        """

        if !context.tags.isEmpty {
            prompt += "\nInteressen: \(context.tags.joined(separator: ", "))."
        }

        if !context.pastGiftTitles.isEmpty {
            prompt += "\nBereits verschenkt (nicht wiederholen): \(context.pastGiftTitles.joined(separator: ", "))."
        }

        if let days = context.daysUntil {
            switch days {
            case 0:     prompt += "\nWichtig: Geburtstag ist HEUTE!"
            case 1:     prompt += "\nWichtig: Geburtstag ist morgen!"
            case 2...7: prompt += "\nWichtig: Geburtstag in \(days) Tagen — schnell verfügbare Ideen bevorzugen."
            default: break
            }
        }

        let session = LanguageModelSession(
            instructions: "Du bist ein erfahrener Geschenkberater. Antworte auf Deutsch. Schlage konkrete, kaufbare Geschenke vor."
        )
        let response = try await session.respond(to: prompt, generating: GiftSuggestionsOutput.self)
        return response.content.suggestions.map { GiftSuggestion(title: $0.title, reason: $0.reason) }

        #else
        throw AIError.notAvailable
        #endif
    }

    @available(iOS 26.0, *)
    private func generateBirthdayMessageWithAI(context: BirthdayContext) async throws -> BirthdayMessage {
        #if canImport(FoundationModels)

        var prompt = """
        Schreibe eine herzliche Geburtstagsgrußkarte für \(context.name), \(context.age) Jahre, \(context.relation).
        Sternzeichen: \(context.zodiac).
        """

        if let title = context.lastGiftTitle, let year = context.lastGiftYear {
            prompt += "\nLetztes Geschenk: \(title) (\(year))."
        }

        let session = LanguageModelSession(
            instructions: "Du bist ein herzlicher Texter für Geburtstagsgrüße. Schreibe auf Deutsch, persönlich und authentisch, ohne Floskeln."
        )
        let response = try await session.respond(to: prompt, generating: BirthdayMessageOutput.self)
        return BirthdayMessage(greeting: response.content.greeting, body: response.content.body)

        #else
        throw AIError.notAvailable
        #endif
    }

    // MARK: - Demo-Modus (vollständig offline)

    private func demoSuggestions(relation: String, zodiac: String, age: Int) -> [GiftSuggestion] {
        let rel = relation.lowercased()
        let isMilestone = BirthdayDateHelper.isMilestoneAge(age: age)
        func note() -> String { "Passt gut zu \(zodiac) (\(personalityHint(for: zodiac)))." }

        var items: [(String, String)]
        if isMilestone {
            items = [
                ("Erlebnis-Gutschein", "Unvergessliches für diesen runden Geburtstag. \(note())"),
                ("Personalisiertes Andenken", "Ein bleibendes Erinnerungsstück für diesen Meilenstein."),
                ("Reise- oder Wochenend-Gutschein", "Neue Abenteuer für diesen Lebensabschnitt."),
                ("Hochwertige Genuss-Erfahrung", "Genuss als Ausdruck von Wertschätzung. \(note())"),
                ("Fotobook oder Erinnerungsalbum", "Die schönsten Momente festhalten.")
            ]
        } else if rel.contains("partner") {
            items = [
                ("Romantisches Wochenend-Erlebnis", "Qualitätszeit zu zweit."),
                ("Personalisiertes Geschenk", "Einzigartig und mit persönlichem Bezug. \(note())"),
                ("Schmuck oder Accessoire", "Zeitlos und wertschätzend."),
                ("Erlebnis für zwei", "Kochkurs, Weinprobe oder Wellness. \(note())"),
                ("Hochwertige Parfümerie", "Ein klassisches, elegantes Geschenk.")
            ]
        } else if rel.contains("mutter") || rel.contains("vater") || rel.contains("oma") ||
                  rel.contains("opa") || rel.contains("tante") || rel.contains("onkel") {
            items = [
                ("Fotoalbum mit gemeinsamen Erinnerungen", "Persönlich und sentimental."),
                ("Hochwertiges Küchen-Accessoire", "Praktisch und von dauerhaftem Nutzen."),
                ("Erlebnis-Gutschein für gemeinsame Zeit", "Erinnerungen statt Dinge. \(note())"),
                ("Buch zum Lieblingsthema", "Zeigt echtes Interesse. \(note())"),
                ("Pflegeset oder Spa-Gutschein", "Etwas Verwöhnendes für den Alltag.")
            ]
        } else {
            items = [
                ("Personalisiertes Geschenk", "Aufmerksamkeit, die bleibt. \(note())"),
                ("Erlebnis-Gutschein", "Erinnerungen statt Dinge."),
                ("Hochwertiges Buch oder Hörbuch", "Nachhaltig und inspirierend. \(note())"),
                ("Praktisches Gadget", "Nützlich im Alltag."),
                ("Specialty-Kaffee oder Tee-Set", "Genussmoment für zu Hause.")
            ]
        }
        return items.map { GiftSuggestion(title: $0.0, reason: $0.1) }
    }

    private func demoBirthdayMessage(name: String, relation: String, zodiac: String) -> BirthdayMessage {
        BirthdayMessage(
            greeting: "Liebe/r \(name),",
            body: """
            alles Gute zum Geburtstag! Ich wünsche dir einen wunderschönen Tag, an dem du rundum verwöhnt wirst. \(zodiacWish(for: zodiac))

            Genieß diesen besonderen Tag!

            Herzlichst,
            Dein(e) \(relation)
            """.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    // MARK: - Hilfsfunktionen

    private func personalityHint(for zodiac: String) -> String {
        switch zodiac.lowercased() {
        case "widder":     return "energisch, spontan"
        case "stier":      return "genussvoll, bodenständig"
        case "zwillinge":  return "neugierig, kommunikativ"
        case "krebs":      return "fürsorglich, emotional"
        case "löwe":       return "kreativ, selbstbewusst"
        case "jungfrau":   return "perfektionistisch, praktisch"
        case "waage":      return "harmonisch, ästhetisch"
        case "skorpion":   return "intensiv, leidenschaftlich"
        case "schütze":    return "abenteuerlustig, optimistisch"
        case "steinbock":  return "ehrgeizig, diszipliniert"
        case "wassermann": return "eigenständig, innovativ"
        case "fische":     return "künstlerisch, einfühlsam"
        default:           return "einzigartig"
        }
    }

    private func zodiacWish(for zodiac: String) -> String {
        switch zodiac.lowercased() {
        case "widder":     return "Möge deine Energie und Spontaneität dich weiterbringen!"
        case "stier":      return "Genieß die schönen Momente des Lebens!"
        case "zwillinge":  return "Möge deine Neugier immer neue Wege öffnen!"
        case "krebs":      return "Deine Fürsorge ist unbezahlbar — genieß diesen Tag!"
        case "löwe":       return "Strahle weiter hell und inspiriere uns alle!"
        case "jungfrau":   return "Deine Akribie ist beeindruckend — bleib so!"
        case "waage":      return "Bringe weiterhin Harmonie in die Welt!"
        case "skorpion":   return "Deine Leidenschaft und Tiefe sind einzigartig!"
        case "schütze":    return "Möge dein Optimismus dich zu neuen Höhen führen!"
        case "steinbock":  return "Dein Ehrgeiz und Disziplin sind vorbildlich!"
        case "wassermann": return "Deine Kreativität und Unabhängigkeit inspirieren!"
        case "fische":     return "Deine Empathie und Kreativität sind ein Geschenk!"
        default:           return "Bleib so einzigartig wie du bist!"
        }
    }

    // MARK: - Fehler

    enum AIError: LocalizedError {
        case notAvailable

        var errorDescription: String? {
            "Apple Intelligence ist auf diesem Gerät nicht verfügbar. Bitte in den Einstellungen aktivieren."
        }
    }
}

// MARK: - Datenstrukturen

struct GiftSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let reason: String
}

struct BirthdayMessage {
    let greeting: String
    let body: String

    var fullText: String { "\(greeting)\n\n\(body)" }
}
