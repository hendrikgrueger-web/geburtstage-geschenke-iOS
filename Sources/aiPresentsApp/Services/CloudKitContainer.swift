import Foundation
import SwiftData
import CloudKit

actor CloudKitContainer {
    static let shared = CloudKitContainer()

    private var container: ModelContainer?

    private init() {}

    func setupCloudKitContainer() throws -> ModelContainer {
        if let container = container {
            return container
        }

        let schema = Schema([
            PersonRef.self,
            GiftIdea.self,
            GiftHistory.self,
            ReminderRule.self
        ])

        let config = ModelConfiguration(
            identifier: "ai-presents-app",
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: .automatic
        )

        let modelContainer = try ModelContainer(
            for: schema,
            configurations: [config]
        )

        self.container = modelContainer
        return modelContainer
    }

    func isCloudKitEnabled() -> Bool {
        // Check if CloudKit is configured and available
        guard let container = container else {
            return false
        }

        // SwiftData with CloudKit automatically syncs when configured
        // We can check if there's a CloudKit identifier
        return container.configurations.contains { config in
            config.cloudKitDatabase != nil
        }
    }

    func enableCloudKit() throws {
        // Reconfigure with CloudKit enabled
        let schema = Schema([
            PersonRef.self,
            GiftIdea.self,
            GiftHistory.self,
            ReminderRule.self
        ])

        let config = ModelConfiguration(
            identifier: "ai-presents-app",
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: .automatic
        )

        container = try ModelContainer(for: schema, configurations: [config])
    }

    func disableCloudKit() throws {
        // Reconfigure with CloudKit disabled
        let schema = Schema([
            PersonRef.self,
            GiftIdea.self,
            GiftHistory.self,
            ReminderRule.self
        ])

        let config = ModelConfiguration(
            identifier: "ai-presents-app-local",
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: nil
        )

        container = try ModelContainer(for: schema, configurations: [config])
    }
}
