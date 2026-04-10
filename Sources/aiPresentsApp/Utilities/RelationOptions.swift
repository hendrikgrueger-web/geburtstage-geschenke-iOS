import Foundation

/// Zentrale Verwaltung aller Beziehungstypen (vordefiniert + benutzerdefiniert).
///
/// **Zweck:** Standardisiert die Beziehungskategorisierung in der App — wird primär in `PersonDetailView`,
/// `RelationPickerView` und SwiftData-Models (`PersonRef.relation`) verwendet.
///
/// **Persistierung:**
/// - Vordefinierte Typen: hardcodiert (8 Standard-Kategorien + "Sonstige"-Fallback)
/// - Benutzerdefinierte Typen: in UserDefaults (lokal) + NSUbiquitousKeyValueStore (iCloud-Sync)
/// - Bei Konflikt: iCloud hat Vorrang; lokale Werte werden ggf. in iCloud migriert
/// - Alle Typen (in Anzeige-Reihenfolge): `predefined.filter { != "Sonstige" } + custom + ["Sonstige"]`
///
/// **Lokalisierung:** `localizedDisplayName(for:)` returniert i18n-Werte für vordefinierte Typen,
/// custom-Typen werden unverändert angezeigt.
enum RelationOptions {
    // UserDefaults key für benutzerdefinierte Beziehungstypen
    private static let customKey = "customRelationTypes"
    // iCloud Key-Value-Store (gleicher Key für konsistente Sync-Semantik)
    // nonisolated(unsafe): NSUbiquitousKeyValueStore ist ein thread-sicherer Singleton — kein Data Race
    nonisolated(unsafe) private static let iCloudStore = NSUbiquitousKeyValueStore.default

    // MARK: - Predefined
    /// Standard-Beziehungstypen (8 vordefinierte + 1 universeller Fallback).
    /// "Sonstige" ist immer enthalten, dient als letzter Fallback für atypische Beziehungen.
    static let predefined: [String] = [
        "Partner/in",
        "Mutter",
        "Vater",
        "Schwester",
        "Bruder",
        "Freund/in",
        "Kollege/in",
        "Kind",
        "Sonstige"
    ]

    // MARK: - Custom (User-defined)
    /// Vom Nutzer selbst angelegte Beziehungstypen.
    ///
    /// **Lesen:** iCloud hat Vorrang. Wenn iCloud leer ist aber UserDefaults Werte hat,
    /// werden diese automatisch in iCloud migriert (einmalige Migration bei erstem Sync).
    ///
    /// **Schreiben:** Wird in beide Stores geschrieben (UserDefaults + iCloud), damit
    /// auch offline-Änderungen zuverlässig synchronisiert werden.
    static var custom: [String] {
        get {
            let iCloudValues = iCloudStore.array(forKey: customKey) as? [String] ?? []
            let localValues = UserDefaults.standard.stringArray(forKey: customKey) ?? []

            if !iCloudValues.isEmpty {
                // iCloud hat Daten — als Quelle nutzen, lokal aktuell halten
                if iCloudValues != localValues {
                    UserDefaults.standard.set(iCloudValues, forKey: customKey)
                }
                return iCloudValues
            } else if !localValues.isEmpty {
                // Lokale Daten vorhanden, iCloud noch leer → Migration in iCloud
                iCloudStore.set(localValues, forKey: customKey)
                iCloudStore.synchronize()
                return localValues
            }
            return []
        }
        set {
            UserDefaults.standard.set(newValue, forKey: customKey)
            iCloudStore.set(newValue, forKey: customKey)
            iCloudStore.synchronize()
        }
    }

    // MARK: - iCloud Sync

    /// Lazy Observer-Token — wird beim ersten Aufruf von `startICloudSync()` initialisiert.
    /// Horcht auf externe iCloud-Änderungen und aktualisiert UserDefaults entsprechend.
    // nonisolated(unsafe): Lazy-Init über static let ist thread-sicher durch Swift-Garantien
    nonisolated(unsafe) private static let iCloudObserver: NSObjectProtocol? = {
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { notification in
            guard
                let changedKeys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String],
                changedKeys.contains("customRelationTypes")
            else { return }

            let iCloudValues = NSUbiquitousKeyValueStore.default.array(forKey: "customRelationTypes") as? [String] ?? []
            // Duplikat-sicheres Merge: iCloud-Werte sind authorativ, aber wir deduplizieren
            let merged = Array(NSOrderedSet(array: iCloudValues).compactMap { $0 as? String })
            UserDefaults.standard.set(merged, forKey: "customRelationTypes")
        }
    }()

    /// Startet den iCloud-Sync für benutzerdefinierte Beziehungstypen.
    /// Muss einmalig beim App-Start aufgerufen werden (z.B. in `aiPresentsApp.init()`).
    static func startICloudSync() {
        _ = iCloudObserver  // Lazy-Observer initialisieren
        iCloudStore.synchronize()
    }

    // MARK: - Combined
    /// Vollständige Liste aller Typen in Anzeige-Reihenfolge:
    /// vordefinierte (ohne "Sonstige") + eigene + "Sonstige" am Ende.
    static var all: [String] {
        predefined.filter { $0 != "Sonstige" } + custom + ["Sonstige"]
    }

    /// Fügt einen eigenen Typ hinzu (dedupliziert, getrimmt).
    /// Ist `relation` leer, identisch mit einem vordefinierten oder bereits vorhanden, passiert nichts.
    static func addCustom(_ relation: String) {
        let trimmed = relation.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              !predefined.contains(trimmed),
              !custom.contains(trimmed) else { return }
        var types = custom
        types.append(trimmed)
        custom = types
    }

    /// Entfernt einen eigenen Typ aus der Liste.
    static func removeCustom(_ relation: String) {
        custom = custom.filter { $0 != relation }
    }

    /// Prüft, ob ein Wert in der vordefinierten Liste enthalten ist.
    /// - Parameter value: Zu prüfender Beziehungstyp
    /// - Returns: `true` wenn vordefiniert, `false` für eigene Beziehungen (z.B. "Oma", "Onkel")
    static func isPredefined(_ value: String) -> Bool {
        predefined.contains(value)
    }

    // MARK: - Localization
    /// Gibt den lokalisierten Anzeigenamen zurück.
    /// - Parameter relation: Beziehungstyp (vordefiniert oder custom)
    /// - Returns: Lokalisierter Text für vordefinierte Typen, unverändert für custom-Typen
    static func localizedDisplayName(for relation: String) -> String {
        switch relation {
        case "Partner/in": return String(localized: "Partner/in")
        case "Mutter": return String(localized: "Mutter")
        case "Vater": return String(localized: "Vater")
        case "Schwester": return String(localized: "Schwester")
        case "Bruder": return String(localized: "Bruder")
        case "Freund/in": return String(localized: "Freund/in")
        case "Kollege/in": return String(localized: "Kollege/in")
        case "Kind": return String(localized: "Kind")
        case "Sonstige": return String(localized: "Sonstige")
        default: return relation  // Custom-Typen werden unverändert angezeigt
        }
    }
}
