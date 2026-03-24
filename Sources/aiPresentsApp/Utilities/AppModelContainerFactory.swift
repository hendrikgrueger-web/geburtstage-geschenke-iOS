import Foundation
import SwiftData

struct AppModelStoreDescriptor: Sendable, Equatable {
    let name: String
    let isStoredInMemoryOnly: Bool
    let allowsSave: Bool
    let usesCloudKit: Bool
}

enum AppModelContainerFactory {
    enum StorageMode: Sendable, Equatable {
        case primary
        case localFallback
        case recovery
    }

    struct CreationResult {
        let container: ModelContainer
        let descriptor: AppModelStoreDescriptor
        let storageMode: StorageMode

        var containerCreationFailed: Bool {
            storageMode == .recovery
        }
    }

    static let iCloudSyncEnabledKey = "iCloudSyncEnabled"
    static let schema = Schema([
        PersonRef.self,
        GiftIdea.self,
        GiftHistory.self,
        ReminderRule.self,
        SuggestionFeedback.self
    ])

    static func primaryDescriptor(userDefaults: UserDefaults = .standard) -> AppModelStoreDescriptor {
        AppModelStoreDescriptor(
            name: "ai-presents-app",
            isStoredInMemoryOnly: false,
            allowsSave: true,
            usesCloudKit: userDefaults.object(forKey: iCloudSyncEnabledKey) as? Bool ?? true
        )
    }

    static let localFallbackDescriptor = AppModelStoreDescriptor(
        name: "ai-presents-app-local",
        isStoredInMemoryOnly: false,
        allowsSave: true,
        usesCloudKit: false
    )

    static let recoveryDescriptor = AppModelStoreDescriptor(
        name: "ai-presents-app-recovery",
        isStoredInMemoryOnly: true,
        allowsSave: true,
        usesCloudKit: false
    )

    static func create(userDefaults: UserDefaults = .standard) throws -> CreationResult {
        do {
            return try makeCreationResult(
                descriptor: primaryDescriptor(userDefaults: userDefaults),
                storageMode: .primary
            )
        } catch {
            AppLogger.data.error("ModelContainer (CloudKit) fehlgeschlagen, versuche lokal", error: error)
        }

        do {
            return try makeCreationResult(
                descriptor: localFallbackDescriptor,
                storageMode: .localFallback
            )
        } catch {
            AppLogger.data.error("Auch lokaler ModelContainer fehlgeschlagen — In-Memory-Fallback", error: error)
        }

        return try makeCreationResult(
            descriptor: recoveryDescriptor,
            storageMode: .recovery
        )
    }

    private static func makeCreationResult(
        descriptor: AppModelStoreDescriptor,
        storageMode: StorageMode
    ) throws -> CreationResult {
        CreationResult(
            container: try ModelContainer(for: schema, configurations: [makeConfiguration(descriptor: descriptor)]),
            descriptor: descriptor,
            storageMode: storageMode
        )
    }

    private static func makeConfiguration(descriptor: AppModelStoreDescriptor) -> ModelConfiguration {
        ModelConfiguration(
            descriptor.name,
            schema: schema,
            isStoredInMemoryOnly: descriptor.isStoredInMemoryOnly,
            allowsSave: descriptor.allowsSave,
            cloudKitDatabase: descriptor.usesCloudKit ? .automatic : .none
        )
    }
}
