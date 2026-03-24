import XCTest
@testable import aiPresentsApp

@MainActor
final class AIChatPromptCachingTests: XCTestCase {
    func testRefreshContextRebuildsPromptAfterGiftStatusChange() {
        let person = makePerson(name: "Anna Beispiel")
        let idea = GiftIdea(personId: person.id, title: "Buch", status: .idea)
        let viewModel = AIChatViewModel()

        viewModel.configure(
            people: [person],
            giftIdeas: [idea],
            giftHistory: [],
            modelContext: nil
        )

        let initialPrompt = viewModel.systemPromptForTesting()
        XCTAssertFalse(viewModel.promptNeedsRebuildForTesting)
        XCTAssertTrue(initialPrompt.contains("Buch[idea]"))

        idea.status = .purchased
        viewModel.refreshContext(
            people: [person],
            giftIdeas: [idea],
            giftHistory: [],
            modelContext: nil
        )

        XCTAssertTrue(viewModel.promptNeedsRebuildForTesting)
        let refreshedPrompt = viewModel.systemPromptForTesting()
        XCTAssertTrue(refreshedPrompt.contains("Buch[purchased]"))
    }

    func testProcessActionInvalidatesPromptCacheForUpdatedGiftStatus() async {
        let person = makePerson(name: "Max Beispiel")
        let idea = GiftIdea(personId: person.id, title: "Konzertticket", status: .idea)
        let viewModel = AIChatViewModel()

        viewModel.configure(
            people: [person],
            giftIdeas: [idea],
            giftHistory: [],
            modelContext: nil
        )

        let initialPrompt = viewModel.systemPromptForTesting()
        XCTAssertTrue(initialPrompt.contains("Konzertticket[idea]"))

        let action = ChatAction(
            type: .updateGiftStatus,
            data: ActionData(
                personId: nil,
                personName: nil,
                giftTitle: nil,
                giftNote: nil,
                newStatus: GiftStatus.purchased.rawValue,
                giftIdeaId: "g1"
            )
        )

        await viewModel.processAction(action)

        XCTAssertTrue(viewModel.promptNeedsRebuildForTesting)
        let updatedPrompt = viewModel.systemPromptForTesting()
        XCTAssertTrue(updatedPrompt.contains("Konzertticket[purchased]"))
    }

    func testRefreshContextRebuildsPromptAfterPersonMetadataChange() {
        let person = makePerson(name: "Lena Beispiel", relation: "Freundin")
        let viewModel = AIChatViewModel()

        viewModel.configure(
            people: [person],
            giftIdeas: [],
            giftHistory: [],
            modelContext: nil
        )

        let initialPrompt = viewModel.systemPromptForTesting()
        XCTAssertTrue(initialPrompt.contains("Freundin"))

        person.relation = "Schwester"
        person.hobbies = ["Lesen", "Kochen"]
        viewModel.refreshContext(
            people: [person],
            giftIdeas: [],
            giftHistory: [],
            modelContext: nil
        )

        let updatedPrompt = viewModel.systemPromptForTesting()
        XCTAssertTrue(updatedPrompt.contains("Schwester"))
        XCTAssertTrue(updatedPrompt.contains("Lesen,Kochen"))
    }

    private func makePerson(name: String, relation: String = "Freund") -> PersonRef {
        PersonRef(
            contactIdentifier: UUID().uuidString,
            displayName: name,
            birthday: Calendar.current.date(from: DateComponents(year: 1990, month: 4, day: 15))!,
            relation: relation
        )
    }
}
