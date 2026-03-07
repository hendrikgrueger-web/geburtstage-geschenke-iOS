import Foundation

/// Zentrale Verwaltung aller Beziehungstypen (vordefiniert + benutzerdefiniert).
///
/// **Zweck:** Standardisiert die Beziehungskategorisierung in der App — wird primär in `PersonDetailView`,
/// `RelationPickerView` und SwiftData-Models (`PersonRef.relation`) verwendet.
///
/// **Persistierung:**
/// - Vordefinierte Typen: hardcodiert (8 Standard-Kategorien + "Sonstige"-Fallback)
/// - Benutzerdefinierte Typen: in UserDefaults unter Schlüssel `"customRelationTypes"` gespeichert
/// - Alle Typen (in Anzeige-Reihenfolge): `predefined.filter { != "Sonstige" } + custom + ["Sonstige"]`
///
/// **Lokalisierung:** `localizedDisplayName(for:)` returniert i18n-Werte für vordefinierte Typen,
/// custom-Typen werden unverändert angezeigt.
enum RelationOptions {
    // UserDefaults key für benutzerdefinierte Beziehungstypen
    private static let customKey = "customRelationTypes"

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
    /// Vom Nutzer selbst angelegte Beziehungstypen, persistiert in UserDefaults.
    /// Lese-/Schreibzugriff via Property-Getter/-Setter.
    static var custom: [String] {
        get { UserDefaults.standard.stringArray(forKey: customKey) ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: customKey) }
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
