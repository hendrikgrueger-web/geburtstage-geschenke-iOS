import XCTest
@testable import aiPresentsApp

final class RelationOptionsTests: XCTestCase {

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        // Sicherstellen, dass custom-Typen leer starten (lokal + iCloud)
        UserDefaults.standard.removeObject(forKey: "customRelationTypes")
        NSUbiquitousKeyValueStore.default.removeObject(forKey: "customRelationTypes")
    }

    override func tearDown() {
        // Custom-Typen aufräumen nach jedem Test (lokal + iCloud)
        UserDefaults.standard.removeObject(forKey: "customRelationTypes")
        NSUbiquitousKeyValueStore.default.removeObject(forKey: "customRelationTypes")
        super.tearDown()
    }

    // MARK: - Predefined

    func testPredefined_contains9Types() {
        XCTAssertEqual(RelationOptions.predefined.count, 9,
                       "Should have 8 predefined + 'Sonstige' = 9")
    }

    func testPredefined_containsAllExpectedTypes() {
        let expected = ["Partner/in", "Mutter", "Vater", "Schwester", "Bruder",
                       "Freund/in", "Kollege/in", "Kind", "Sonstige"]
        for type in expected {
            XCTAssertTrue(RelationOptions.predefined.contains(type),
                         "Predefined should contain '\(type)'")
        }
    }

    func testPredefined_sonstigeIsLast() {
        XCTAssertEqual(RelationOptions.predefined.last, "Sonstige",
                       "'Sonstige' should be the last predefined type")
    }

    func testPredefined_isImmutable() {
        let first = RelationOptions.predefined
        let second = RelationOptions.predefined
        XCTAssertEqual(first, second, "Predefined should always return the same list")
    }

    // MARK: - isPredefined

    func testIsPredefined_trueFoKnownTypes() {
        XCTAssertTrue(RelationOptions.isPredefined("Mutter"))
        XCTAssertTrue(RelationOptions.isPredefined("Vater"))
        XCTAssertTrue(RelationOptions.isPredefined("Sonstige"))
        XCTAssertTrue(RelationOptions.isPredefined("Partner/in"))
    }

    func testIsPredefined_falseForCustomType() {
        XCTAssertFalse(RelationOptions.isPredefined("Oma"))
        XCTAssertFalse(RelationOptions.isPredefined("Onkel"))
        XCTAssertFalse(RelationOptions.isPredefined(""))
    }

    // MARK: - Custom (addCustom / removeCustom)

    func testCustom_initiallyEmpty() {
        XCTAssertEqual(RelationOptions.custom, [],
                       "Custom should be empty initially")
    }

    func testAddCustom_addsType() {
        RelationOptions.addCustom("Oma")
        XCTAssertTrue(RelationOptions.custom.contains("Oma"))
    }

    func testAddCustom_removeCustom_roundtrip() {
        RelationOptions.addCustom("Onkel")
        XCTAssertTrue(RelationOptions.custom.contains("Onkel"))

        RelationOptions.removeCustom("Onkel")
        XCTAssertFalse(RelationOptions.custom.contains("Onkel"))
    }

    func testAddCustom_multipleTypes() {
        RelationOptions.addCustom("Oma")
        RelationOptions.addCustom("Onkel")
        RelationOptions.addCustom("Cousine")

        XCTAssertEqual(RelationOptions.custom.count, 3)
        XCTAssertTrue(RelationOptions.custom.contains("Oma"))
        XCTAssertTrue(RelationOptions.custom.contains("Onkel"))
        XCTAssertTrue(RelationOptions.custom.contains("Cousine"))
    }

    func testAddCustom_duplicateIgnored() {
        RelationOptions.addCustom("Oma")
        RelationOptions.addCustom("Oma")

        XCTAssertEqual(RelationOptions.custom.count, 1,
                       "Duplicate should not be added")
    }

    func testAddCustom_emptyStringIgnored() {
        RelationOptions.addCustom("")
        XCTAssertEqual(RelationOptions.custom.count, 0,
                       "Empty string should not be added")
    }

    func testAddCustom_whitespaceOnlyIgnored() {
        RelationOptions.addCustom("   ")
        XCTAssertEqual(RelationOptions.custom.count, 0,
                       "Whitespace-only string should not be added")
    }

    func testAddCustom_trimmedWhitespace() {
        RelationOptions.addCustom("  Oma  ")
        XCTAssertTrue(RelationOptions.custom.contains("Oma"),
                      "Added type should be trimmed")
    }

    func testAddCustom_predefinedTypeIgnored() {
        RelationOptions.addCustom("Mutter")
        XCTAssertEqual(RelationOptions.custom.count, 0,
                       "Predefined type should not be added as custom")
    }

    func testAddCustom_sonstigeIgnored() {
        RelationOptions.addCustom("Sonstige")
        XCTAssertEqual(RelationOptions.custom.count, 0,
                       "'Sonstige' is predefined and should not be added as custom")
    }

    func testRemoveCustom_nonexistentType_noEffect() {
        RelationOptions.addCustom("Oma")
        RelationOptions.removeCustom("Onkel")
        XCTAssertEqual(RelationOptions.custom.count, 1,
                       "Removing non-existent type should have no effect")
    }

    func testRemoveCustom_fromEmptyList_noEffect() {
        RelationOptions.removeCustom("Oma")
        XCTAssertEqual(RelationOptions.custom.count, 0)
    }

    // MARK: - all (Combined)

    func testAll_withNoCustom_hasPredefinedWithoutSonstigePlusSonstigeAtEnd() {
        let all = RelationOptions.all
        let predefinedWithoutSonstige = RelationOptions.predefined.filter { $0 != "Sonstige" }

        // Erste 8 sollten predefined (ohne "Sonstige") sein
        XCTAssertEqual(Array(all.prefix(predefinedWithoutSonstige.count)), predefinedWithoutSonstige)
        // Letzter sollte "Sonstige" sein
        XCTAssertEqual(all.last, "Sonstige")
    }

    func testAll_withCustom_insertsBeforeSonstige() {
        RelationOptions.addCustom("Oma")
        RelationOptions.addCustom("Onkel")

        let all = RelationOptions.all
        XCTAssertEqual(all.last, "Sonstige", "'Sonstige' should always be last")

        guard let omaIndex = all.firstIndex(of: "Oma"),
              let sonstigeIndex = all.firstIndex(of: "Sonstige") else {
            XCTFail("Oma and Sonstige should both be in 'all'")
            return
        }

        XCTAssertTrue(omaIndex < sonstigeIndex, "Custom types should appear before 'Sonstige'")
    }

    func testAll_containsAllPredefinedTypes() {
        for type in RelationOptions.predefined {
            XCTAssertTrue(RelationOptions.all.contains(type),
                         "'all' should contain predefined type '\(type)'")
        }
    }

    func testAll_sonstigeAppearsExactlyOnce() {
        RelationOptions.addCustom("Oma")
        let sonstigeCount = RelationOptions.all.filter { $0 == "Sonstige" }.count
        XCTAssertEqual(sonstigeCount, 1, "'Sonstige' should appear exactly once in 'all'")
    }

    func testAll_countMatches() {
        RelationOptions.addCustom("Oma")
        RelationOptions.addCustom("Onkel")

        let expectedCount = RelationOptions.predefined.count - 1 + 2 + 1
        // predefined ohne "Sonstige" (8) + 2 custom + "Sonstige" (1) = 11
        XCTAssertEqual(RelationOptions.all.count, expectedCount)
    }

    // MARK: - localizedDisplayName

    func testLocalizedDisplayName_predefinedTypes_returnNonEmpty() {
        for type in RelationOptions.predefined {
            let name = RelationOptions.localizedDisplayName(for: type)
            XCTAssertFalse(name.isEmpty,
                          "Localized name for '\(type)' should not be empty")
        }
    }

    func testLocalizedDisplayName_customType_returnsUnchanged() {
        let custom = "Schwiegermutter"
        let name = RelationOptions.localizedDisplayName(for: custom)
        XCTAssertEqual(name, custom,
                       "Custom type should be returned unchanged")
    }

    func testLocalizedDisplayName_emptyString_returnsEmpty() {
        let name = RelationOptions.localizedDisplayName(for: "")
        XCTAssertEqual(name, "", "Empty string should return empty")
    }

    func testLocalizedDisplayName_unknownType_returnsAsIs() {
        let name = RelationOptions.localizedDisplayName(for: "Nachbar")
        XCTAssertEqual(name, "Nachbar",
                       "Unknown type should be returned as-is (custom fallback)")
    }

    // MARK: - Persistierung (UserDefaults)

    func testCustom_persistsAcrossReads() {
        RelationOptions.addCustom("Tante")

        // Nochmal lesen — sollte noch da sein
        let customs = RelationOptions.custom
        XCTAssertTrue(customs.contains("Tante"),
                      "Custom type should persist in UserDefaults")
    }

    func testCustom_removalPersists() {
        RelationOptions.addCustom("Tante")
        RelationOptions.removeCustom("Tante")

        let customs = RelationOptions.custom
        XCTAssertFalse(customs.contains("Tante"),
                       "Removed custom type should not appear after re-read")
    }

    // MARK: - iCloud Sync

    func testAddCustom_writesToICloudStore() {
        RelationOptions.addCustom("Oma")

        let iCloudValues = (NSUbiquitousKeyValueStore.default.array(forKey: "customRelationTypes") as? [String]) ?? []
        XCTAssertTrue(iCloudValues.contains("Oma"),
                      "Custom type should be written to NSUbiquitousKeyValueStore")
    }

    func testRemoveCustom_removesFromICloudStore() {
        RelationOptions.addCustom("Oma")
        RelationOptions.removeCustom("Oma")

        let iCloudValues = (NSUbiquitousKeyValueStore.default.array(forKey: "customRelationTypes") as? [String]) ?? []
        XCTAssertFalse(iCloudValues.contains("Oma"),
                       "Removed custom type should not appear in iCloud store")
    }

    func testCustom_iCloudTakesPriorityOverLocal() {
        // Nur lokal setzen (simuliert alte UserDefaults-Daten ohne iCloud)
        UserDefaults.standard.set(["LocalOnly"], forKey: "customRelationTypes")
        // iCloud hat anderen Wert (simuliert Sync von anderem Gerät)
        NSUbiquitousKeyValueStore.default.set(["FromICloud"], forKey: "customRelationTypes")

        let customs = RelationOptions.custom
        XCTAssertTrue(customs.contains("FromICloud"),
                      "iCloud value should take priority over local UserDefaults")
        XCTAssertFalse(customs.contains("LocalOnly"),
                       "Local-only value should not appear when iCloud has data")
    }

    func testCustom_localMigratedToICloudWhenICloudEmpty() {
        // Nur lokal setzen, iCloud leer lassen (Migration-Szenario)
        UserDefaults.standard.set(["LocalTante"], forKey: "customRelationTypes")
        // iCloud explizit leer lassen (bereits durch setUp gesetzt)

        let customs = RelationOptions.custom
        XCTAssertTrue(customs.contains("LocalTante"),
                      "Local types should be returned when iCloud is empty")

        // Nach dem Lesen sollte iCloud befüllt worden sein (Migration)
        let iCloudValues = (NSUbiquitousKeyValueStore.default.array(forKey: "customRelationTypes") as? [String]) ?? []
        XCTAssertTrue(iCloudValues.contains("LocalTante"),
                      "Local types should be migrated to iCloud on first read")
    }

    func testCustom_deduplication_noDuplicatesAfterMerge() {
        // Beide Stores mit überlappenden Werten füllen
        NSUbiquitousKeyValueStore.default.set(["Oma", "Oma", "Tante"], forKey: "customRelationTypes")
        UserDefaults.standard.set(["Oma", "Onkel"], forKey: "customRelationTypes")

        // iCloud hat Priorität — Oma ist doppelt drin, Tante ist neu
        let customs = RelationOptions.custom
        let omaCount = customs.filter { $0 == "Oma" }.count
        XCTAssertGreaterThan(customs.count, 0, "Should have custom types")
        // Nach dem Observer-Merge (manuell simuliert via iCloudObserver-Logik) sollte kein Duplikat entstehen
        // Hier testen wir, dass der iCloud-Store selbst keine Duplikate produziert wenn er authorativ ist
        XCTAssertEqual(omaCount, 1,
                       "Duplicates in iCloud store should be deduplicated by the merge logic")
    }

    func testStartICloudSync_doesNotCrash() {
        // startICloudSync() mehrfach aufzurufen sollte problemlos sein
        XCTAssertNoThrow(RelationOptions.startICloudSync(),
                         "startICloudSync() should not throw")
        XCTAssertNoThrow(RelationOptions.startICloudSync(),
                         "Calling startICloudSync() twice should not crash")
    }
}
