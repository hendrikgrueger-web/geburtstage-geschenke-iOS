import Foundation

// Foundation Models (Apple Intelligence) — auf iOS 26+ mit A17 Pro / M1 oder neuer.
// Der Import ist mit #if canImport abgesichert, damit das Projekt auch mit älteren
// Xcode-Versionen kompiliert (Demo-Modus greift dann automatisch).
#if canImport(FoundationModels)
import FoundationModels
#endif

/// KI-Service für Geschenkvorschläge und Geburtstagsgrüße.
///
/// ## Datenschutz-Architektur: 100% lokal
///
/// Die gesamte KI-Verarbeitung findet auf dem Gerät statt (Apple Intelligence).
/// Es werden **keinerlei Daten an externe Server gesendet**. Kein API-Key,
/// kein Netzwerkzugriff, keine Drittanbieter.
///
/// ## Voraussetzungen für Apple Intelligence
/// - iOS 26.0 oder neuer
/// - iPhone 15 Pro oder alle iPhone 16 (A17 Pro / A18 Chip)
/// - Apple Intelligence in den Einstellungen aktiviert
///
/// ## Fallback
/// Wenn Apple Intelligence nicht verfügbar ist (Gerät nicht unterstützt oder
/// nicht aktiviert), liefert die App Demo-Vorschläge ohne KI.
struct AIService {
    static let shared = AIService()

    private init() {}

    // MARK: - Verfügbarkeit

    /// Gibt an, ob Apple Intelligence auf diesem Gerät verfügbar ist.
    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.isAvailable
        }
        #endif
        return false
    }

    // MARK: - Öffentliche API

    @MainActor
    func generateGiftIdeas(
        for person: PersonRef,
        budgetMin: Double,
        budgetMax: Double,
        tags: [String],
        pastGifts: [GiftHistory]
    ) async throws -> [GiftSuggestion] {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), SystemLanguageModel.default.isAvailable {
            let prompt = buildGiftPrompt(person: person, budgetMin: budgetMin,
                                         budgetMax: budgetMax, tags: tags, pastGifts: pastGifts)
            return try await generateWithFoundationModels(prompt: prompt, parse: parseJSONSuggestions)
        }
        #endif
        return generateDemoSuggestions(for: person, budget: budgetMax)
    }

    @MainActor
    func generateBirthdayMessage(for person: PersonRef, pastGifts: [GiftHistory] = []) async throws -> BirthdayMessage {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), SystemLanguageModel.default.isAvailable {
            let prompt = buildBirthdayPrompt(for: person, pastGifts: pastGifts)
            return try await generateWithFoundationModels(prompt: prompt, parse: parseJSONBirthdayMessage)
        }
        #endif
        return generateDemoBirthdayMessage(for: person)
    }

    // MARK: - Foundation Models (lokal, kein Netzwerk)

    @available(iOS 26.0, *)
    private func generateWithFoundationModels<T>(
        prompt: String,
        parse: (String) throws -> T
    ) async throws -> T {
        #if canImport(FoundationModels)
        guard SystemLanguageModel.default.isAvailable else {
            throw AIError.notAvailable
        }
        let session = LanguageModelSession()
        let response = try await session.respond(to: prompt)
        return try parse(response.content)
        #else
        throw AIError.notAvailable
        #endif
    }

    // MARK: - Prompt-Builder
    // Da alles lokal verarbeitet wird, können Name und exaktes Alter
    // direkt im Prompt verwendet werden — kein Datenschutzproblem.

    private func buildGiftPrompt(
        person: PersonRef,
        budgetMin: Double,
        budgetMax: Double,
        tags: [String],
        pastGifts: [GiftHistory]
    ) -> String {
        let exactAge = BirthdayDateHelper.age(from: person.birthday)
        let zodiac = BirthdayDateHelper.zodiacSign(from: person.birthday)
        let daysUntil = BirthdayDateHelper.daysUntilBirthday(from: person.birthday)

        var urgencyHint = ""
        if let days = daysUntil {
            switch days {
            case 0:     urgencyHint = " — Geburtstag ist heute!"
            case 1:     urgencyHint = " — Geburtstag ist morgen!"
            case 2...7: urgencyHint = " — Geburtstag in \(days) Tagen"
            default:    break
            }
        }

        var prompt = """
        Erstelle 5 passende Geschenkideen für \(person.displayName), \(exactAge) Jahre (\(person.relation))\(urgencyHint).

        Sternzeichen: \(zodiac)
        Budget: \(Int(budgetMin))€–\(Int(budgetMax))€ (strikt einhalten)
        """

        if !tags.isEmpty {
            prompt += "\nInteressen: \(tags.joined(separator: ", "))"
        }

        if !pastGifts.isEmpty {
            let previous = pastGifts.map { "- \($0.title) (\($0.year))" }.joined(separator: "\n")
            prompt += "\n\nBereits verschenkt (nicht wiederholen):\n\(previous)"
        }

        prompt += """


        Ausgabe als JSON-Array (kein Markdown, kein Text drumherum):
        [{"title": "Konkreter Geschenkname", "reason": "Kurze Begründung (1–2 Sätze)"}]
        """

        return prompt
    }

    private func buildBirthdayPrompt(for person: PersonRef, pastGifts: [GiftHistory]) -> String {
        let exactAge = BirthdayDateHelper.age(from: person.birthday)
        let zodiac = BirthdayDateHelper.zodiacSign(from: person.birthday)

        var prompt = """
        Schreibe eine herzliche Geburtstagsgrußkarte für \(person.displayName), \(exactAge) Jahre (\(person.relation)).
        Sternzeichen: \(zodiac)
        Tonfall: persönlich, warm, nicht floskelhaft
        """

        if let lastGift = pastGifts.sorted(by: { $0.year > $1.year }).first {
            prompt += "\nLetztes Geschenk: \(lastGift.title) (\(lastGift.year))"
        }

        prompt += """


        Ausgabe als JSON (kein Markdown):
        {"greeting": "Anrede (z.B. Liebe/r ...)", "body": "Nachrichtentext (3–5 Sätze)"}
        """

        return prompt
    }

    // MARK: - JSON-Parser

    private func parseJSONSuggestions(_ text: String) throws -> [GiftSuggestion] {
        let cleaned = stripMarkdown(text)
        guard let data = cleaned.data(using: .utf8),
              let array = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw AIError.invalidResponse
        }
        return array.compactMap { item -> GiftSuggestion? in
            guard let title = item["title"] as? String,
                  let reason = item["reason"] as? String else { return nil }
            return GiftSuggestion(title: title, reason: reason)
        }
    }

    private func parseJSONBirthdayMessage(_ text: String) throws -> BirthdayMessage {
        let cleaned = stripMarkdown(text)
        guard let data = cleaned.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let greeting = json["greeting"] as? String,
              let body = json["body"] as? String else {
            throw AIError.invalidResponse
        }
        return BirthdayMessage(greeting: greeting, body: body)
    }

    /// Entfernt Markdown-Codeblöcke (```json ... ```) aus LLM-Antworten.
    private func stripMarkdown(_ text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if result.hasPrefix("```") {
            result = result.components(separatedBy: "\n").dropFirst().joined(separator: "\n")
            if result.hasSuffix("```") { result = String(result.dropLast(3)) }
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Demo-Modus (offline, wenn Apple Intelligence nicht verfügbar)

    private func generateDemoSuggestions(for person: PersonRef, budget: Double) -> [GiftSuggestion] {
        let relation = person.relation.lowercased()
        let zodiac = BirthdayDateHelper.zodiacSign(from: person.birthday)
        let age = BirthdayDateHelper.age(from: person.birthday)
        let isMilestone = BirthdayDateHelper.isMilestoneAge(age: age)

        func note() -> String { "\(zodiac)-Energie (\(personalityHint(for: zodiac)))." }

        var items: [(String, String)]

        if isMilestone {
            items = [
                ("Erlebnis-Gutschein", "Unvergessliches für diesen runden Geburtstag. \(note())"),
                ("Personalisiertes Andenken", "Ein bleibendes Erinnerungsstück für diesen Meilenstein."),
                ("Reise- oder Wochenend-Gutschein", "Neue Abenteuer für diesen Lebensabschnitt."),
                ("Hochwertige Genuss-Erfahrung", "Genuss als Ausdruck von Wertschätzung. \(note())"),
                ("Fotobook oder Erinnerungsalbum", "Die schönsten Momente festhalten.")
            ]
        } else if relation.contains("partner") {
            items = [
                ("Romantisches Wochenend-Erlebnis", "Qualitätszeit zu zweit."),
                ("Personalisiertes Geschenk", "Einzigartig und mit persönlichem Bezug. \(note())"),
                ("Schmuck oder Accessoire", "Zeitlos und wertschätzend."),
                ("Erlebnis für zwei", "Kochkurs, Weinprobe oder Wellness. \(note())"),
                ("Hochwertige Parfümerie", "Ein klassisches, elegantes Geschenk.")
            ]
        } else if relation.contains("familie") || relation.contains("mama") || relation.contains("papa") {
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

    private func generateDemoBirthdayMessage(for person: PersonRef) -> BirthdayMessage {
        let zodiac = BirthdayDateHelper.zodiacSign(from: person.birthday)
        return BirthdayMessage(
            greeting: "Liebe/r \(person.displayName),",
            body: """
            alles Gute zum Geburtstag! Ich wünsche dir einen wunderschönen Tag, an dem du rundum verwöhnt wirst. \(zodiacWish(for: zodiac))

            Genieß diesen besonderen Tag!

            Herzlichst,
            Dein(e) \(person.relation)
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
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "Apple Intelligence ist auf diesem Gerät nicht verfügbar. Bitte aktiviere Apple Intelligence in den Einstellungen."
            case .invalidResponse:
                return "Die KI hat eine ungültige Antwort geliefert. Bitte erneut versuchen."
            }
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
