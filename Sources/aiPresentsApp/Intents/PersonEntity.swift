import AppIntents
import SwiftData
import Foundation

// MARK: - PersonEntity

/// AppEntity that represents a PersonRef for use in App Intents / Siri shortcuts.
/// Intents run in an isolated process, so we create a dedicated ModelContainer here.
struct PersonEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Kontakt")
    static let defaultQuery = PersonEntityQuery()

    var id: UUID
    var displayName: String
    var relation: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(displayName)",
            subtitle: "\(relation)"
        )
    }
}

// MARK: - PersonEntity + init from PersonRef

extension PersonEntity {
    init(from person: PersonRef) {
        self.id = person.id
        self.displayName = person.displayName
        self.relation = person.relation
    }
}

// MARK: - ModelContainer helper

/// Creates a fresh ModelContainer for use inside AppIntent processes.
/// Each call creates an independent container — intentional since intents run
/// in a separate process without access to the main app's container.
func makeIntentsModelContainer() throws -> ModelContainer {
    let schema = Schema([
        PersonRef.self,
        GiftIdea.self,
        GiftHistory.self,
        ReminderRule.self,
        SuggestionFeedback.self
    ])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    return try ModelContainer(for: schema, configurations: [config])
}

// MARK: - PersonEntityQuery

/// Handles all lookup and search operations for PersonEntity in App Intents.
struct PersonEntityQuery: EntityQuery, EntityStringQuery {

    // MARK: EntityQuery

    /// Fetch specific entities by their UUIDs (called by the system to resolve saved intents).
    func entities(for identifiers: [UUID]) async throws -> [PersonEntity] {
        let container = try makeIntentsModelContainer()
        let context = ModelContext(container)

        let allPersons: [PersonRef] = try context.fetch(FetchDescriptor<PersonRef>())
        return allPersons
            .filter { identifiers.contains($0.id) }
            .map { PersonEntity(from: $0) }
    }

    /// Returns all persons sorted by days until next birthday (ascending).
    /// Used for the default picker list in Shortcuts / Siri UI.
    func suggestedEntities() async throws -> [PersonEntity] {
        let container = try makeIntentsModelContainer()
        let context = ModelContext(container)

        let allPersons: [PersonRef] = try context.fetch(FetchDescriptor<PersonRef>())

        let sorted = allPersons.sorted { lhs, rhs in
            let lhsDays = BirthdayCalculator.daysUntilBirthday(for: lhs.birthday) ?? Int.max
            let rhsDays = BirthdayCalculator.daysUntilBirthday(for: rhs.birthday) ?? Int.max
            return lhsDays < rhsDays
        }

        return sorted.map { PersonEntity(from: $0) }
    }

    // MARK: EntityStringQuery

    /// Case-insensitive name search — called when the user types in the Shortcuts picker.
    func entities(matching string: String) async throws -> [PersonEntity] {
        let container = try makeIntentsModelContainer()
        let context = ModelContext(container)

        let allPersons: [PersonRef] = try context.fetch(FetchDescriptor<PersonRef>())
        let lowerQuery = string.lowercased()

        return allPersons
            .filter { $0.displayName.lowercased().contains(lowerQuery) }
            .map { PersonEntity(from: $0) }
    }
}
