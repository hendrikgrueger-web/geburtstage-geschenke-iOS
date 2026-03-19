import XCTest
@testable import aiPresentsApp

// MARK: - ChatResponseJSON Parsing Tests

/// Tests für das JSON-Parsing der KI-Chat-Antworten — die komplexeste Parsing-Logik der App.
final class ChatResponseJSONParsingTests: XCTestCase {

    // MARK: - Vollständige Antwort mit Action

    func testParseResponse_createGiftIdea_allFields() throws {
        let json = """
        {
            "message": "Wie wäre es mit einem Buch für deine Schwester?",
            "action": {
                "type": "create_gift_idea",
                "person_id": "p1",
                "person_name": "Schwester",
                "gift_title": "Buch",
                "gift_note": "Liebt Fantasy-Romane"
            }
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let response = try JSONDecoder().decode(ChatResponseJSON.self, from: data)

        XCTAssertEqual(response.message, "Wie wäre es mit einem Buch für deine Schwester?")
        XCTAssertNotNil(response.action)
        XCTAssertEqual(response.action?.type, "create_gift_idea")
        XCTAssertEqual(response.action?.personId, "p1")
        XCTAssertEqual(response.action?.personName, "Schwester")
        XCTAssertEqual(response.action?.giftTitle, "Buch")
        XCTAssertEqual(response.action?.giftNote, "Liebt Fantasy-Romane")
    }

    func testParseResponse_updateGiftStatus() throws {
        let json = """
        {
            "message": "Status auf gekauft gesetzt!",
            "action": {
                "type": "update_gift_status",
                "gift_idea_id": "g3",
                "new_status": "purchased"
            }
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let response = try JSONDecoder().decode(ChatResponseJSON.self, from: data)

        XCTAssertEqual(response.action?.type, "update_gift_status")
        XCTAssertEqual(response.action?.giftIdeaId, "g3")
        XCTAssertEqual(response.action?.newStatus, "purchased")
        XCTAssertNil(response.action?.personId, "update_gift_status sollte keine personId haben")
    }

    func testParseResponse_openSuggestions() throws {
        let json = """
        {
            "message": "Hier sind Vorschläge für Anna!",
            "action": {
                "type": "open_suggestions",
                "person_id": "p5",
                "person_name": "Anna"
            }
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let response = try JSONDecoder().decode(ChatResponseJSON.self, from: data)

        XCTAssertEqual(response.action?.type, "open_suggestions")
        XCTAssertEqual(response.action?.personId, "p5")
        XCTAssertEqual(response.action?.personName, "Anna")
    }

    func testParseResponse_clarifyPerson() throws {
        let json = """
        {
            "message": "Welchen Thomas meinst du?",
            "action": {"type": "clarify_person"}
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let response = try JSONDecoder().decode(ChatResponseJSON.self, from: data)

        XCTAssertEqual(response.action?.type, "clarify_person")
        XCTAssertNil(response.action?.personId)
    }

    func testParseResponse_offTopic() throws {
        let json = """
        {
            "message": "Das kann ich leider nicht. Frag mich lieber: Wer hat bald Geburtstag?",
            "action": {"type": "off_topic"}
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let response = try JSONDecoder().decode(ChatResponseJSON.self, from: data)

        XCTAssertEqual(response.action?.type, "off_topic")
    }

    // MARK: - Antwort ohne Action

    func testParseResponse_actionNull() throws {
        let json = """
        {"message": "Ich verstehe die Frage nicht.", "action": null}
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let response = try JSONDecoder().decode(ChatResponseJSON.self, from: data)

        XCTAssertEqual(response.message, "Ich verstehe die Frage nicht.")
        XCTAssertNil(response.action)
    }

    func testParseResponse_actionNone() throws {
        let json = """
        {"message": "Anna hat am 15. April Geburtstag.", "action": {"type": "none"}}
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let response = try JSONDecoder().decode(ChatResponseJSON.self, from: data)

        XCTAssertEqual(response.action?.type, "none")
    }

    func testParseResponse_queryAction() throws {
        let json = """
        {"message": "In den nächsten 7 Tagen hat niemand Geburtstag.", "action": {"type": "query"}}
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let response = try JSONDecoder().decode(ChatResponseJSON.self, from: data)

        XCTAssertEqual(response.action?.type, "query")
    }

    // MARK: - Malformed / Edge Cases

    func testParseResponse_malformedJSON_throws() {
        let json = "{ broken json"
        let data = json.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(ChatResponseJSON.self, from: data))
    }

    func testParseResponse_emptyString_throws() {
        let data = "".data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(ChatResponseJSON.self, from: data))
    }

    func testParseResponse_missingMessageKey_throws() {
        let json = """
        {"action": {"type": "none"}}
        """
        let data = json.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(ChatResponseJSON.self, from: data),
                             "Fehlende 'message' sollte Fehler werfen")
    }

    func testParseResponse_extraFields_ignored() throws {
        let json = """
        {"message": "Test", "action": {"type": "none"}, "extra_field": 42}
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let response = try JSONDecoder().decode(ChatResponseJSON.self, from: data)
        XCTAssertEqual(response.message, "Test")
    }

    func testParseResponse_unicodeMessage() throws {
        let json = """
        {"message": "🎁 Hier sind Ideen für deinen Bruder! 🎂", "action": {"type": "none"}}
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let response = try JSONDecoder().decode(ChatResponseJSON.self, from: data)
        XCTAssertTrue(response.message.contains("🎁"))
        XCTAssertTrue(response.message.contains("🎂"))
    }

    func testParseResponse_emptyMessage() throws {
        let json = """
        {"message": "", "action": null}
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let response = try JSONDecoder().decode(ChatResponseJSON.self, from: data)
        XCTAssertEqual(response.message, "")
    }

    func testParseResponse_longMessage() throws {
        let longText = String(repeating: "Geschenkidee. ", count: 500)
        let json = """
        {"message": "\(longText)", "action": {"type": "none"}}
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let response = try JSONDecoder().decode(ChatResponseJSON.self, from: data)
        XCTAssertTrue(response.message.count > 1000)
    }

    // MARK: - Action mit optionalen Feldern (nil)

    func testParseResponse_actionWithOnlyType() throws {
        let json = """
        {"message": "OK", "action": {"type": "create_gift_idea"}}
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let response = try JSONDecoder().decode(ChatResponseJSON.self, from: data)

        XCTAssertEqual(response.action?.type, "create_gift_idea")
        XCTAssertNil(response.action?.personId)
        XCTAssertNil(response.action?.personName)
        XCTAssertNil(response.action?.giftTitle)
        XCTAssertNil(response.action?.giftNote)
        XCTAssertNil(response.action?.newStatus)
        XCTAssertNil(response.action?.giftIdeaId)
    }

    func testParseResponse_actionWithPartialFields() throws {
        let json = """
        {
            "message": "Gespeichert!",
            "action": {
                "type": "create_gift_idea",
                "person_id": "p2",
                "gift_title": "Kinogutschein"
            }
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let response = try JSONDecoder().decode(ChatResponseJSON.self, from: data)

        XCTAssertEqual(response.action?.personId, "p2")
        XCTAssertEqual(response.action?.giftTitle, "Kinogutschein")
        XCTAssertNil(response.action?.personName, "Fehlende optionale Felder sollten nil sein")
        XCTAssertNil(response.action?.giftNote)
    }
}

// MARK: - ChatActionJSON CodingKeys Tests

final class ChatActionJSONCodingKeyTests: XCTestCase {

    func testCodingKeys_snakeCase() throws {
        let json = """
        {
            "type": "create_gift_idea",
            "person_id": "p1",
            "person_name": "Anna",
            "gift_title": "Buch",
            "gift_note": "Fantasy",
            "new_status": "planned",
            "gift_idea_id": "g5"
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let action = try JSONDecoder().decode(ChatActionJSON.self, from: data)

        XCTAssertEqual(action.type, "create_gift_idea")
        XCTAssertEqual(action.personId, "p1")
        XCTAssertEqual(action.personName, "Anna")
        XCTAssertEqual(action.giftTitle, "Buch")
        XCTAssertEqual(action.giftNote, "Fantasy")
        XCTAssertEqual(action.newStatus, "planned")
        XCTAssertEqual(action.giftIdeaId, "g5")
    }

    func testCodingKeys_camelCaseRejected() {
        // ChatActionJSON nutzt snake_case CodingKeys — camelCase sollte nil liefern
        let json = """
        {
            "type": "query",
            "personId": "p1"
        }
        """
        let data = json.data(using: .utf8)!
        let action = try? JSONDecoder().decode(ChatActionJSON.self, from: data)

        // personId wird als nil dekodiert, da der CodingKey "person_id" erwartet
        XCTAssertNil(action?.personId, "camelCase 'personId' sollte nicht auf person_id mappen")
    }

    func testEncodeDecode_roundTrip() throws {
        let original = ChatActionJSON(
            type: "open_suggestions",
            personId: "p3",
            personName: "Max",
            giftTitle: nil,
            giftNote: nil,
            newStatus: nil,
            giftIdeaId: nil
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ChatActionJSON.self, from: encoded)

        XCTAssertEqual(decoded.type, original.type)
        XCTAssertEqual(decoded.personId, original.personId)
        XCTAssertEqual(decoded.personName, original.personName)
    }
}

// MARK: - ChatMessage Struct Tests

final class ChatMessageTests: XCTestCase {

    func testInit_defaults() {
        let msg = ChatMessage(role: .user, content: "Hallo")

        XCTAssertEqual(msg.role, .user)
        XCTAssertEqual(msg.content, "Hallo")
        XCTAssertNil(msg.action, "Default-Action sollte nil sein")
        XCTAssertNotEqual(msg.id, UUID(), "ID sollte generiert werden")
    }

    func testInit_withAction() {
        let action = ChatAction(
            type: .createGiftIdea,
            data: ActionData(
                personId: "p1",
                personName: "Anna",
                giftTitle: "Buch",
                giftNote: nil,
                newStatus: nil,
                giftIdeaId: nil
            )
        )
        let msg = ChatMessage(role: .assistant, content: "Gespeichert!", action: action)

        XCTAssertNotNil(msg.action)
        XCTAssertEqual(msg.action?.type, .createGiftIdea)
        XCTAssertEqual(msg.action?.data?.giftTitle, "Buch")
    }

    func testRoles() {
        let user = ChatMessage(role: .user, content: "Test")
        let assistant = ChatMessage(role: .assistant, content: "Antwort")
        let system = ChatMessage(role: .system, content: "System")

        XCTAssertEqual(user.role, .user)
        XCTAssertEqual(assistant.role, .assistant)
        XCTAssertEqual(system.role, .system)
    }

    func testRole_rawValues() {
        XCTAssertEqual(ChatMessage.Role.user.rawValue, "user")
        XCTAssertEqual(ChatMessage.Role.assistant.rawValue, "assistant")
        XCTAssertEqual(ChatMessage.Role.system.rawValue, "system")
    }

    func testUniqueIDs() {
        let msg1 = ChatMessage(role: .user, content: "Eins")
        let msg2 = ChatMessage(role: .user, content: "Eins")

        XCTAssertNotEqual(msg1.id, msg2.id, "Zwei Nachrichten sollten unterschiedliche IDs haben")
    }

    func testCustomID() {
        let customId = UUID()
        let msg = ChatMessage(id: customId, role: .user, content: "Test")

        XCTAssertEqual(msg.id, customId)
    }

    func testTimestamp_isReasonable() {
        let before = Date()
        let msg = ChatMessage(role: .user, content: "Test")
        let after = Date()

        XCTAssertGreaterThanOrEqual(msg.timestamp, before)
        XCTAssertLessThanOrEqual(msg.timestamp, after)
    }
}

// MARK: - ChatAction Tests

final class ChatActionTests: XCTestCase {

    func testActionType_allCases() {
        let allRawValues = [
            "create_gift_idea", "query", "update_gift_status",
            "open_suggestions", "clarify_person", "off_topic", "none"
        ]
        for raw in allRawValues {
            XCTAssertNotNil(
                ChatAction.ActionType(rawValue: raw),
                "ActionType sollte '\(raw)' parsen können"
            )
        }
    }

    func testActionType_invalidRawValue() {
        XCTAssertNil(ChatAction.ActionType(rawValue: "unknown_action"))
        XCTAssertNil(ChatAction.ActionType(rawValue: ""))
        XCTAssertNil(ChatAction.ActionType(rawValue: "createGiftIdea"))
    }

    func testActionType_codable() throws {
        let original = ChatAction.ActionType.createGiftIdea
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ChatAction.ActionType.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func testActionData_allNil() {
        let data = ActionData(
            personId: nil,
            personName: nil,
            giftTitle: nil,
            giftNote: nil,
            newStatus: nil,
            giftIdeaId: nil
        )
        XCTAssertNil(data.personId)
        XCTAssertNil(data.giftTitle)
    }

    func testActionData_allFilled() {
        let data = ActionData(
            personId: "p1",
            personName: "Anna",
            giftTitle: "Buch",
            giftNote: "Fantasy-Roman",
            newStatus: "purchased",
            giftIdeaId: "g5"
        )
        XCTAssertEqual(data.personId, "p1")
        XCTAssertEqual(data.personName, "Anna")
        XCTAssertEqual(data.giftTitle, "Buch")
        XCTAssertEqual(data.giftNote, "Fantasy-Roman")
        XCTAssertEqual(data.newStatus, "purchased")
        XCTAssertEqual(data.giftIdeaId, "g5")
    }
}

// MARK: - AIService.extractJSON Extended Tests

@MainActor
final class ExtractJSONTests: XCTestCase {

    func testExtractJSON_plainJSON() {
        let input = """
        {"message":"test","action":null}
        """
        let result = AIService.extractJSON(from: input)
        XCTAssertEqual(result, input.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    func testExtractJSON_jsonCodeBlock() {
        let input = """
        ```json
        {"message":"test"}
        ```
        """
        let result = AIService.extractJSON(from: input)
        XCTAssertEqual(result, "{\"message\":\"test\"}")
    }

    func testExtractJSON_bareCodeBlock() {
        let input = """
        ```
        {"key":"val"}
        ```
        """
        let result = AIService.extractJSON(from: input)
        XCTAssertEqual(result, "{\"key\":\"val\"}")
    }

    func testExtractJSON_noJSON_returnsOriginal() {
        let input = "Das ist kein JSON"
        let result = AIService.extractJSON(from: input)
        XCTAssertEqual(result, input)
    }

    func testExtractJSON_nestedCodeBlock_multiline() {
        let input = """
        ```json
        {
            "message": "Hier sind 3 Ideen",
            "action": {
                "type": "create_gift_idea",
                "person_id": "p1"
            }
        }
        ```
        """
        let result = AIService.extractJSON(from: input)
        XCTAssertTrue(result.contains("\"message\": \"Hier sind 3 Ideen\""))
        XCTAssertTrue(result.contains("\"person_id\": \"p1\""))
        XCTAssertFalse(result.contains("```"))
    }

    func testExtractJSON_leadingTrailingWhitespace() {
        let input = "\n\n  {\"a\":1}  \n\n"
        let result = AIService.extractJSON(from: input)
        XCTAssertEqual(result, "{\"a\":1}")
    }

    func testExtractJSON_emptyString() {
        let result = AIService.extractJSON(from: "")
        XCTAssertEqual(result, "")
    }

    func testExtractJSON_onlyBackticks() {
        let input = "```\n```"
        let result = AIService.extractJSON(from: input)
        // Zwischen den Backticks ist nichts — leeres Ergebnis
        XCTAssertTrue(result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}

// MARK: - AIService.decodeGiftSuggestions Extended Tests

@MainActor
final class DecodeGiftSuggestionsTests: XCTestCase {

    func testDecode_validFiveSuggestions() {
        let json = """
        {"suggestions":[
            {"title":"Buch","reason":"Liebt lesen"},
            {"title":"Parfüm","reason":"Mag Düfte"},
            {"title":"Konzertkarten","reason":"Musikfan"},
            {"title":"Kochkurs","reason":"Kocht gerne"},
            {"title":"Reisegutschein","reason":"Reist viel"}
        ]}
        """
        let data = json.data(using: .utf8)!
        let suggestions = AIService.decodeGiftSuggestions(from: data)

        XCTAssertNotNil(suggestions)
        XCTAssertEqual(suggestions?.count, 5)
        XCTAssertEqual(suggestions?[0].title, "Buch")
        XCTAssertEqual(suggestions?[0].reason, "Liebt lesen")
        XCTAssertEqual(suggestions?[4].title, "Reisegutschein")
    }

    func testDecode_emptyArray() {
        let json = """
        {"suggestions":[]}
        """
        let data = json.data(using: .utf8)!
        let suggestions = AIService.decodeGiftSuggestions(from: data)

        XCTAssertNotNil(suggestions)
        XCTAssertEqual(suggestions?.count, 0)
    }

    func testDecode_missingSuggestionsKey_returnsNil() {
        let json = """
        {"ideas":[{"title":"Buch","reason":"Test"}]}
        """
        let data = json.data(using: .utf8)!
        let suggestions = AIService.decodeGiftSuggestions(from: data)

        XCTAssertNil(suggestions, "Falscher Key 'ideas' statt 'suggestions' sollte nil liefern")
    }

    func testDecode_invalidJSON_returnsNil() {
        let data = "not json at all".data(using: .utf8)!
        let suggestions = AIService.decodeGiftSuggestions(from: data)

        XCTAssertNil(suggestions)
    }

    func testDecode_markdownWrapped() {
        let json = """
        ```json
        {"suggestions":[{"title":"Schal","reason":"Winter naht"}]}
        ```
        """
        let data = json.data(using: .utf8)!
        let suggestions = AIService.decodeGiftSuggestions(from: data)

        XCTAssertNotNil(suggestions)
        XCTAssertEqual(suggestions?.count, 1)
        XCTAssertEqual(suggestions?.first?.title, "Schal")
    }

    func testDecode_uniqueIDs() {
        let json = """
        {"suggestions":[
            {"title":"A","reason":"1"},
            {"title":"B","reason":"2"}
        ]}
        """
        let data = json.data(using: .utf8)!
        let suggestions = AIService.decodeGiftSuggestions(from: data)

        XCTAssertNotNil(suggestions)
        let ids = suggestions!.map { $0.id }
        XCTAssertEqual(Set(ids).count, ids.count, "Jede Suggestion sollte eine eindeutige ID haben")
    }

    func testDecode_emptyData() {
        let data = Data()
        let suggestions = AIService.decodeGiftSuggestions(from: data)
        XCTAssertNil(suggestions)
    }

    func testDecode_unicodeContent() {
        let json = """
        {"suggestions":[{"title":"Bücher über Ägypten 📚","reason":"Liebt Geschichte & Reisen 🌍"}]}
        """
        let data = json.data(using: .utf8)!
        let suggestions = AIService.decodeGiftSuggestions(from: data)

        XCTAssertNotNil(suggestions)
        XCTAssertTrue(suggestions?.first?.title.contains("Ägypten") == true)
    }
}

// MARK: - AIService.decodeBirthdayMessage Extended Tests

@MainActor
final class DecodeBirthdayMessageTests: XCTestCase {

    func testDecode_validMessage() {
        let json = """
        {"greeting":"Lieber Max,","body":"Alles Gute zum Geburtstag! Ich wünsche dir einen wundervollen Tag."}
        """
        let data = json.data(using: .utf8)!
        let message = AIService.decodeBirthdayMessage(from: data)

        XCTAssertNotNil(message)
        XCTAssertEqual(message?.greeting, "Lieber Max,")
        XCTAssertEqual(message?.body, "Alles Gute zum Geburtstag! Ich wünsche dir einen wundervollen Tag.")
    }

    func testDecode_withSenderName() {
        let json = """
        {"greeting":"Liebe Anna,","body":"Herzlichen Glückwunsch!"}
        """
        let data = json.data(using: .utf8)!
        let message = AIService.decodeBirthdayMessage(from: data, senderName: "Hendrik")

        XCTAssertNotNil(message)
        XCTAssertEqual(message?.greeting, "Liebe Anna,")
        XCTAssertTrue(message?.body.hasSuffix("\n\nHendrik") == true,
                     "Body sollte mit Sender-Name enden")
    }

    func testDecode_withoutSenderName() {
        let json = """
        {"greeting":"Hi Tom,","body":"Happy Birthday!"}
        """
        let data = json.data(using: .utf8)!
        let message = AIService.decodeBirthdayMessage(from: data, senderName: nil)

        XCTAssertNotNil(message)
        XCTAssertEqual(message?.body, "Happy Birthday!")
        XCTAssertFalse(message?.body.contains("\n\n") == true,
                      "Ohne senderName sollte kein Zeilenumbruch angehängt werden")
    }

    func testDecode_emptySenderName() {
        let json = """
        {"greeting":"Hi,","body":"Alles Gute!"}
        """
        let data = json.data(using: .utf8)!
        let message = AIService.decodeBirthdayMessage(from: data, senderName: "")

        XCTAssertNotNil(message)
        // Leerer senderName ist nicht nil, also wird "\n\n" angehängt
        XCTAssertTrue(message?.body.hasSuffix("\n\n") == true)
    }

    func testDecode_invalidJSON_returnsNil() {
        let data = "not json".data(using: .utf8)!
        let message = AIService.decodeBirthdayMessage(from: data)
        XCTAssertNil(message)
    }

    func testDecode_missingGreetingKey_returnsNil() {
        let json = """
        {"anrede":"Lieber Max,","body":"Alles Gute!"}
        """
        let data = json.data(using: .utf8)!
        let message = AIService.decodeBirthdayMessage(from: data)
        XCTAssertNil(message, "Falscher Key 'anrede' statt 'greeting' sollte nil liefern")
    }

    func testDecode_markdownWrapped() {
        let json = """
        ```json
        {"greeting":"Hallo!","body":"Feier schön!"}
        ```
        """
        let data = json.data(using: .utf8)!
        let message = AIService.decodeBirthdayMessage(from: data)

        XCTAssertNotNil(message)
        XCTAssertEqual(message?.greeting, "Hallo!")
    }

    func testDecode_fullText() {
        let json = """
        {"greeting":"Liebe Oma,","body":"Alles Liebe zum Geburtstag!"}
        """
        let data = json.data(using: .utf8)!
        let message = AIService.decodeBirthdayMessage(from: data)

        XCTAssertEqual(message?.fullText, "Liebe Oma,\n\nAlles Liebe zum Geburtstag!")
    }

    func testDecode_fullTextWithSender() {
        let json = """
        {"greeting":"Lieber Papa,","body":"Alles Gute!"}
        """
        let data = json.data(using: .utf8)!
        let message = AIService.decodeBirthdayMessage(from: data, senderName: "Dein Sohn")

        XCTAssertEqual(message?.fullText, "Lieber Papa,\n\nAlles Gute!\n\nDein Sohn")
    }

    func testDecode_emptyData() {
        let data = Data()
        let message = AIService.decodeBirthdayMessage(from: data)
        XCTAssertNil(message)
    }
}

// MARK: - End-to-End: extractJSON → decode Pipeline Tests

@MainActor
final class JSONPipelineTests: XCTestCase {

    /// Simuliert den echten Pfad: KI antwortet mit Markdown-wrapped JSON → extractJSON → decode
    func testPipeline_chatResponse_fromMarkdown() throws {
        let rawAIOutput = """
        ```json
        {"message":"Wie wäre es mit einem Puzzle?","action":{"type":"create_gift_idea","person_id":"p2","gift_title":"1000-Teile Puzzle"}}
        ```
        """

        let extracted = AIService.extractJSON(from: rawAIOutput)
        let data = try XCTUnwrap(extracted.data(using: .utf8))
        let response = try JSONDecoder().decode(ChatResponseJSON.self, from: data)

        XCTAssertEqual(response.message, "Wie wäre es mit einem Puzzle?")
        XCTAssertEqual(response.action?.type, "create_gift_idea")
        XCTAssertEqual(response.action?.giftTitle, "1000-Teile Puzzle")
    }

    func testPipeline_giftSuggestions_fromMarkdown() {
        let rawAIOutput = """
        ```
        {"suggestions":[{"title":"Yoga-Matte","reason":"Für die tägliche Yoga-Praxis"}]}
        ```
        """

        let data = rawAIOutput.data(using: .utf8)!
        let suggestions = AIService.decodeGiftSuggestions(from: data)

        XCTAssertEqual(suggestions?.count, 1)
        XCTAssertEqual(suggestions?.first?.title, "Yoga-Matte")
    }

    func testPipeline_birthdayMessage_fromMarkdown() {
        let rawAIOutput = """
        ```json
        {"greeting":"Liebe Schwester,","body":"Möge dein neues Lebensjahr voller Freude sein!"}
        ```
        """

        let data = rawAIOutput.data(using: .utf8)!
        let message = AIService.decodeBirthdayMessage(from: data, senderName: "Dein Bruder")

        XCTAssertNotNil(message)
        XCTAssertTrue(message?.fullText.contains("Dein Bruder") == true)
    }

    /// KI gibt manchmal nur die message ohne Markdown zurück — Fallback-Pfad
    func testPipeline_chatResponse_plainText_fallback() {
        let rawAIOutput = "Das ist keine JSON-Antwort, sondern nur Text."

        let extracted = AIService.extractJSON(from: rawAIOutput)
        let data = extracted.data(using: .utf8)!
        let response = try? JSONDecoder().decode(ChatResponseJSON.self, from: data)

        // Sollte fehlschlagen — der Caller (callOpenRouterChat) fängt das ab
        // und gibt ChatResponseJSON(message: rawText, action: nil) zurück
        XCTAssertNil(response, "Nicht-JSON sollte nicht als ChatResponseJSON parsbar sein")
    }
}
