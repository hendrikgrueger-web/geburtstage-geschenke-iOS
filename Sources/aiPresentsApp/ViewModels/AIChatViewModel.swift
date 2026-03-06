import Foundation
import SwiftData
import SwiftUI

/// ViewModel für den KI-Chat. Orchestriert System-Prompt-Bau, API-Calls und Action-Processing.
@MainActor
@Observable
final class AIChatViewModel {
    var messages: [ChatMessage] = []
    var isLoading = false
    var errorMessage: String?

    /// Wird gesetzt wenn eine Aktion ein Sheet öffnen soll.
    var pendingGiftIdeaPerson: PersonRef?
    var pendingGiftIdeaTitle: String = ""
    var pendingGiftIdeaNote: String = ""
    var pendingSuggestionsPerson: PersonRef?

    /// Wird gesetzt wenn ein Status-Update durchgeführt wurde.
    var lastStatusUpdateMessage: String?

    private var people: [PersonRef] = []
    private var giftIdeas: [GiftIdea] = []
    private var giftHistory: [GiftHistory] = []
    private var modelContext: ModelContext?

    /// Short-ID → UUID Lookup-Maps (werden beim System-Prompt-Bau befüllt)
    private var personIdMap: [String: UUID] = [:]
    private var giftIdeaIdMap: [String: UUID] = [:]

    // MARK: - Setup

    func configure(people: [PersonRef], giftIdeas: [GiftIdea], giftHistory: [GiftHistory], modelContext: ModelContext) {
        self.people = people
        self.giftIdeas = giftIdeas
        self.giftHistory = giftHistory
        self.modelContext = modelContext
    }

    // MARK: - Senden

    func sendMessage(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let userMessage = ChatMessage(role: .user, content: trimmed)
        messages.append(userMessage)
        isLoading = true
        errorMessage = nil

        do {
            let apiMessages = buildAPIMessages()
            let response = try await AIService.shared.callOpenRouterChat(messages: apiMessages)

            let action = parseAction(from: response.action)
            let assistantMessage = ChatMessage(role: .assistant, content: response.message, action: action)
            messages.append(assistantMessage)

            if let action {
                await processAction(action)
            }
        } catch {
            let errorMsg = error.localizedDescription
            errorMessage = errorMsg
            let errorChat = ChatMessage(role: .assistant, content: String(localized: "Entschuldigung, es gab einen Fehler. Bitte versuche es erneut."))
            messages.append(errorChat)
            AppLogger.data.error("Chat-Fehler", error: error)
        }

        isLoading = false
    }

    // MARK: - API Messages

    private func buildAPIMessages() -> [[String: String]] {
        var apiMessages: [[String: String]] = [
            ["role": "system", "content": buildSystemPrompt()]
        ]

        for msg in messages {
            switch msg.role {
            case .user:
                apiMessages.append(["role": "user", "content": msg.content])
            case .assistant:
                apiMessages.append(["role": "assistant", "content": msg.content])
            case .system:
                break
            }
        }

        return apiMessages
    }

    // MARK: - System Prompt

    func buildSystemPrompt() -> String {
        // ID-Maps bei jedem Prompt-Bau neu aufbauen
        personIdMap.removeAll()
        giftIdeaIdMap.removeAll()

        let isGerman = Locale.current.language.languageCode?.identifier == "de"

        // Kompakter Prompt — eine Sprache, kurze Regeln, Short-IDs
        var prompt: String
        if isGerman {
            prompt = """
            KI-Assistent der App "AI Präsente" (Geburtstags-/Geschenkeverwaltung).
            Antworte auf Deutsch, herzlich, kurz (1-3 Sätze). Nur Geburtstage/Geschenke — Off-Topic freundlich ablehnen.
            Bei mehrdeutigem Namen: nachfragen. Nutze Short-IDs (p1, g1 etc.) aus der Kontaktliste.
            Antworte NUR mit JSON: {"message":"...","action":{"type":"none"}}
            Aktionen: create_gift_idea(person_id,person_name,gift_title,gift_note) | query | update_gift_status(gift_idea_id,new_status:planned|purchased|given) | open_suggestions(person_id,person_name) | clarify_person | off_topic | none
            """
        } else {
            prompt = """
            AI assistant for "AI Präsente" (birthday/gift management app).
            Respond warmly, concisely (1-3 sentences). Only birthdays/gifts — politely decline off-topic.
            Ambiguous name: ask to clarify. Use short IDs (p1, g1 etc.) from the contact list.
            Respond ONLY with JSON: {"message":"...","action":{"type":"none"}}
            Actions: create_gift_idea(person_id,person_name,gift_title,gift_note) | query | update_gift_status(gift_idea_id,new_status:planned|purchased|given) | open_suggestions(person_id,person_name) | clarify_person | off_topic | none
            """
        }

        // Kompakte Kontaktliste
        prompt += "\n\nKontakte:\n"

        if people.isEmpty {
            prompt += "(keine)\n"
        } else {
            var giftCounter = 1
            for (index, person) in people.enumerated() {
                let pid = "p\(index + 1)"
                personIdMap[pid] = person.id

                prompt += buildCompactPersonEntry(person, shortId: pid, isGerman: isGerman, giftCounter: &giftCounter)
            }
        }

        return prompt
    }

    private func buildCompactPersonEntry(_ person: PersonRef, shortId: String, isGerman: Bool, giftCounter: inout Int) -> String {
        // Format: p1:Name|15.3.|34|10d|Freund/in|Reiten,Kochen
        let calendar = Calendar.current
        let month = calendar.component(.month, from: person.birthday)
        let day = calendar.component(.day, from: person.birthday)

        var parts: [String] = ["\(shortId):\(person.displayName)"]
        parts.append("\(day).\(month).")

        if person.birthYearKnown {
            parts.append("\(BirthdayDateHelper.age(from: person.birthday))J")
        }

        if let days = BirthdayDateHelper.daysUntilBirthday(from: person.birthday) {
            parts.append(days == 0 ? "HEUTE!" : "\(days)d")
        }

        parts.append(person.relation)

        if !person.hobbies.isEmpty {
            parts.append(person.hobbies.joined(separator: ","))
        }

        if person.skipGift {
            parts.append(isGerman ? "skip" : "skip")
        }

        var entry = parts.joined(separator: "|")

        // Geschenkideen kompakt
        let ideas = giftIdeas.filter { $0.personId == person.id }
        if !ideas.isEmpty {
            let ideaParts = ideas.map { idea -> String in
                let gid = "g\(giftCounter)"
                giftIdeaIdMap[gid] = idea.id
                giftCounter += 1
                return "\(gid):\(idea.title)[\(idea.status.rawValue)]"
            }
            entry += " >" + ideaParts.joined(separator: ",")
        }

        // Geschenkhistorie kompakt (nur letzten 2 Jahre, max 3)
        let history = giftHistory.filter { $0.personId == person.id }
            .sorted { $0.year > $1.year }
            .prefix(3)
        if !history.isEmpty {
            let histParts = history.map { "\($0.title)(\($0.year % 100))" }
            entry += " h:" + histParts.joined(separator: ",")
        }

        entry += "\n"
        return entry
    }

    // MARK: - Action Parsing

    private func parseAction(from json: ChatActionJSON?) -> ChatAction? {
        guard let json else { return nil }
        guard let type = ChatAction.ActionType(rawValue: json.type) else { return nil }

        let data = ActionData(
            personId: json.personId,
            personName: json.personName,
            giftTitle: json.giftTitle,
            giftNote: json.giftNote,
            newStatus: json.newStatus,
            giftIdeaId: json.giftIdeaId
        )
        return ChatAction(type: type, data: data)
    }

    // MARK: - Action Processing

    /// Löst eine Short-ID (z.B. "p1") oder volle UUID zu einer PersonRef auf.
    private func resolvePerson(from idString: String?) -> PersonRef? {
        guard let idString else { return nil }
        // Short-ID Lookup
        if let uuid = personIdMap[idString] {
            return people.first { $0.id == uuid }
        }
        // Fallback: volle UUID
        if let uuid = UUID(uuidString: idString) {
            return people.first { $0.id == uuid }
        }
        // Fallback: Name-Match
        return people.first { $0.displayName.lowercased() == idString.lowercased() }
    }

    /// Löst eine Short-ID (z.B. "g1") oder volle UUID zu einer GiftIdea auf.
    private func resolveGiftIdea(from idString: String?) -> GiftIdea? {
        guard let idString else { return nil }
        if let uuid = giftIdeaIdMap[idString] {
            return giftIdeas.first { $0.id == uuid }
        }
        if let uuid = UUID(uuidString: idString) {
            return giftIdeas.first { $0.id == uuid }
        }
        return nil
    }

    func processAction(_ action: ChatAction) async {
        guard let data = action.data else { return }

        switch action.type {
        case .createGiftIdea:
            guard let person = resolvePerson(from: data.personId) ?? resolvePerson(from: data.personName) else { return }
            pendingGiftIdeaTitle = data.giftTitle ?? ""
            pendingGiftIdeaNote = data.giftNote ?? ""
            pendingGiftIdeaPerson = person

        case .openSuggestions:
            guard let person = resolvePerson(from: data.personId) ?? resolvePerson(from: data.personName) else { return }
            pendingSuggestionsPerson = person

        case .updateGiftStatus:
            guard let idea = resolveGiftIdea(from: data.giftIdeaId),
                  let newStatusStr = data.newStatus,
                  let newStatus = GiftStatus(rawValue: newStatusStr) else { return }

            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yy"
            let dateString = formatter.string(from: Date())
            let oldStatus = idea.status
            idea.statusLog.append("\(dateString) - \(oldStatus.rawValue) \u{2192} \(newStatus.rawValue)")
            idea.status = newStatus
            HapticFeedback.success()

        case .query, .clarifyPerson, .offTopic, .none:
            break
        }
    }

    // MARK: - Welcome Chips

    var welcomeChips: [(label: String, message: String)] {
        let isGerman = Locale.current.language.languageCode?.identifier == "de"
        var chips: [(String, String)] = []

        // Nächster Geburtstag
        let today = Calendar.current.startOfDay(for: Date())
        if let nextPerson = people
            .compactMap({ person -> (PersonRef, Int)? in
                guard let days = BirthdayCalculator.daysUntilBirthday(for: person.birthday, from: today) else { return nil }
                return (person, days)
            })
            .sorted(by: { $0.1 < $1.1 })
            .first {
            let name = nextPerson.0.displayName
            chips.append((
                isGerman ? "Wann hat \(name) Geburtstag?" : "When is \(name)'s birthday?",
                isGerman ? "Wann hat \(name) Geburtstag?" : "When is \(name)'s birthday?"
            ))
        }

        // Geschenkidee vorschlagen
        if let person = people.first {
            chips.append((
                isGerman ? "Idee für \(person.displayName)" : "Idea for \(person.displayName)",
                isGerman ? "Schlage Geschenke für \(person.displayName) vor" : "Suggest gifts for \(person.displayName)"
            ))
        }

        // Allgemeine Chips
        chips.append((
            isGerman ? "Wer hat bald Geburtstag?" : "Who has a birthday soon?",
            isGerman ? "Wer hat in den nächsten 7 Tagen Geburtstag?" : "Who has a birthday in the next 7 days?"
        ))

        return chips
    }
}
