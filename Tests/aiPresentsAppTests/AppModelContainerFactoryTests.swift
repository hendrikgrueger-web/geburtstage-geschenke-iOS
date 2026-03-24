import XCTest
@testable import aiPresentsApp

final class AppModelContainerFactoryTests: XCTestCase {
    func testPrimaryDescriptorUsesCloudKitWhenPreferenceEnabled() {
        let defaults = makeDefaults()
        defaults.set(true, forKey: AppModelContainerFactory.iCloudSyncEnabledKey)

        let descriptor = AppModelContainerFactory.primaryDescriptor(userDefaults: defaults)

        XCTAssertEqual(descriptor.name, "ai-presents-app")
        XCTAssertFalse(descriptor.isStoredInMemoryOnly)
        XCTAssertTrue(descriptor.allowsSave)
        XCTAssertTrue(descriptor.usesCloudKit)
    }

    func testPrimaryDescriptorDisablesCloudKitWhenPreferenceDisabled() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppModelContainerFactory.iCloudSyncEnabledKey)

        let descriptor = AppModelContainerFactory.primaryDescriptor(userDefaults: defaults)

        XCTAssertFalse(descriptor.usesCloudKit)
    }

    func testFallbackDescriptorsRemainLocalAndDistinct() {
        XCTAssertEqual(AppModelContainerFactory.localFallbackDescriptor.name, "ai-presents-app-local")
        XCTAssertFalse(AppModelContainerFactory.localFallbackDescriptor.isStoredInMemoryOnly)
        XCTAssertFalse(AppModelContainerFactory.localFallbackDescriptor.usesCloudKit)

        XCTAssertEqual(AppModelContainerFactory.recoveryDescriptor.name, "ai-presents-app-recovery")
        XCTAssertTrue(AppModelContainerFactory.recoveryDescriptor.isStoredInMemoryOnly)
        XCTAssertFalse(AppModelContainerFactory.recoveryDescriptor.usesCloudKit)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "AppModelContainerFactoryTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
