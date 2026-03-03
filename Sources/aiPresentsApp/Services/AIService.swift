import Foundation

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

/// KI-Service für Geschenkvorschläge und Geburtstagsgrüße via OpenRouter (Google Gemini).
///
/// ## Datenschutz: Cloud-Verarbeitung
/// Ausgewählte Daten werden an OpenRouter → Google Gemini (USA) übertragen.
/// Übertragen werden: Vorname, Alter, Beziehungstyp, Sternzeichen, Interessen/Tags,
/// Budget-Rahmen (Min/Max), Titel vergangener Geschenke.
/// NICHT übertragen: Geburtsdatum, Links, Notizen, Telefonnummer.
///
/// ## Voraussetzungen
/// - API-Key in Info.plist (OpenRouterAPIKey)
/// - Einwilligung via AIConsentManager
///
/// ## Fallback
/// Demo-Modus wenn API-Key fehlt oder bei Netzwerkfehler.
struct AIService {
    static let shared = AIService()
    private init() {}

    // MARK: - Verfügbarkeit

    /// True wenn API-Key konfiguriert ist UND Einwilligung gegeben wurde.
    /// Nur auf dem MainActor aufrufbar (da AIConsentManager MainActor-isoliert ist).
    @MainActor
    static var isAvailable: Bool {
        isAPIKeyConfigured && AIConsentManager.shared.consentGiven
    }

    static var isAPIKeyConfigured: Bool {
        let key = Bundle.main.infoDictionary?["OpenRouterAPIKey"] as? String ?? ""
        return !key.isEmpty && !key.hasPrefix("sk-or-v1-YOUR") && !key.hasPrefix("PLACEHOLDER") && key.count > 20
    }

    private static var apiKey: String {
        Bundle.main.infoDictionary?["OpenRouterAPIKey"] as? String ?? ""
    }

    // MARK: - Öffentliche API (@MainActor — SwiftData-Objekte extrahieren)

    @MainActor
    func generateGiftIdeas(
        for person: PersonRef,
        budgetMin: Double,
        budgetMax: Double,
        tags: [String],
        pastGifts: [GiftHistory],
        excludeTitles: [String] = []
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

        if AIService.isAvailable && AIConsentManager.shared.canUseAI {
            do {
                return try await generateGiftIdeasWithOpenRouter(context: context, budget: budgetRange, excludeTitles: excludeTitles)
            } catch {
                AppLogger.data.warning("OpenRouter Fehler, verwende Demo-Modus: \(error.localizedDescription)")
            }
        }
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

        if AIService.isAvailable && AIConsentManager.shared.canUseAI {
            do {
                return try await generateBirthdayMessageWithOpenRouter(context: context)
            } catch {
                AppLogger.data.warning("OpenRouter Fehler, verwende Demo-Modus: \(error.localizedDescription)")
            }
        }
        return demoBirthdayMessage(name: context.name, relation: context.relation, zodiac: context.zodiac)
    }

    // MARK: - OpenRouter API

    private func generateGiftIdeasWithOpenRouter(
        context: GiftContext,
        budget: (min: Double, max: Double),
        excludeTitles: [String] = []
    ) async throws -> [GiftSuggestion] {

        var userPrompt = """
        Erstelle 5 passende Geschenkideen für \(context.name), \(context.age) Jahre, \(context.relation).
        Sternzeichen: \(context.zodiac).
        Budget: \(Int(budget.min))–\(Int(budget.max)) Euro (strikt einhalten).
        """

        if !context.tags.isEmpty {
            userPrompt += "\nInteressen: \(context.tags.joined(separator: ", "))."
        }

        let allExcluded = context.pastGiftTitles + excludeTitles
        if !allExcluded.isEmpty {
            userPrompt += "\nBereits vorgeschlagen oder verschenkt (NICHT wiederholen): \(allExcluded.joined(separator: ", "))."
        }

        if let days = context.daysUntil {
            switch days {
            case 0:     userPrompt += "\nWichtig: Geburtstag ist HEUTE!"
            case 1:     userPrompt += "\nWichtig: Geburtstag ist morgen!"
            case 2...7: userPrompt += "\nWichtig: Geburtstag in \(days) Tagen — schnell verfügbare Ideen bevorzugen."
            default: break
            }
        }

        let systemPrompt = "Du bist ein Geschenkberater. Regeln: 1) title = konkretes Geschenk in 1-3 Worten (z.B. \"Espressomaschine\", \"Yoga-Matte\", \"Konzertkarten\"). 2) reason = kurze Begründung warum es passt (1 Satz, ANDERS als title). Antworte NUR mit validem JSON ohne Markdown-Codeblöcke. Format: {\"suggestions\":[{\"title\":\"...\",\"reason\":\"...\"}]}"

        let responseData = try await callOpenRouter(system: systemPrompt, user: userPrompt)

        guard let json = try? JSONDecoder().decode(GiftSuggestionsJSON.self, from: responseData) else {
            AppLogger.data.warning("JSON-Parse-Fehler bei Gift Ideas, verwende Demo-Modus")
            return demoSuggestions(relation: context.relation, zodiac: context.zodiac, age: context.age)
        }

        return json.suggestions.map { GiftSuggestion(title: $0.title, reason: $0.reason) }
    }

    private func generateBirthdayMessageWithOpenRouter(context: BirthdayContext) async throws -> BirthdayMessage {

        var userPrompt = """
        Schreibe eine herzliche Geburtstagsgrußkarte für \(context.name), \(context.age) Jahre, \(context.relation).
        Sternzeichen: \(context.zodiac).
        """

        if let title = context.lastGiftTitle, let year = context.lastGiftYear {
            userPrompt += "\nLetztes Geschenk: \(title) (\(year))."
        }

        let systemPrompt = "Du bist ein Texter für Geburtstagsgrüße. Antworte NUR mit validem JSON ohne Markdown-Codeblöcke. Format: {\"greeting\":\"...\",\"body\":\"...\"}"

        let responseData = try await callOpenRouter(system: systemPrompt, user: userPrompt)

        guard let json = try? JSONDecoder().decode(BirthdayMessageJSON.self, from: responseData) else {
            AppLogger.data.warning("JSON-Parse-Fehler bei Birthday Message, verwende Demo-Modus")
            return demoBirthdayMessage(name: context.name, relation: context.relation, zodiac: context.zodiac)
        }

        return BirthdayMessage(greeting: json.greeting, body: json.body)
    }

    private func callOpenRouter(system: String, user: String) async throws -> Data {
        let key = AIService.apiKey
        guard !key.isEmpty else { throw AIError.noAPIKey }

        let url = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://github.com/harryhirsch1878/ai-presents-app-ios", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("AI Präsente", forHTTPHeaderField: "X-Title")

        let body: [String: Any] = [
            "model": "google/gemini-3.1-flash-lite-preview",
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            AppLogger.data.error("OpenRouter HTTP \(httpResponse.statusCode)")
            throw AIError.httpError(httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content else {
            throw AIError.emptyResponse
        }

        guard let contentData = content.data(using: .utf8) else {
            throw AIError.emptyResponse
        }
        return contentData
    }

    // MARK: - Response Structs (privat)

    private struct OpenRouterResponse: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable { let content: String }
            let message: Message
        }
        let choices: [Choice]
    }

    private struct GiftSuggestionsJSON: Decodable {
        struct Item: Decodable { let title: String; let reason: String }
        let suggestions: [Item]
    }

    private struct BirthdayMessageJSON: Decodable {
        let greeting: String
        let body: String
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
        case noAPIKey
        case httpError(Int)
        case emptyResponse

        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "Kein API-Key konfiguriert. Bitte trage deinen OpenRouter-Key ein."
            case .httpError(let code):
                return "OpenRouter API-Fehler (HTTP \(code)). Bitte prüfe deinen API-Key."
            case .emptyResponse:
                return "Leere Antwort vom KI-Dienst erhalten."
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
