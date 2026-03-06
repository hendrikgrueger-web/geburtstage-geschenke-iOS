import Foundation

/// Vordefinierte Beziehungstypen für die Zuordnung von Personen.
/// Wird im Relation-Picker (PersonDetailView, ContactsImportView) verwendet.
/// Benutzerdefinierte Werte sind über "Sonstige" + Freitextfeld möglich.
enum RelationOptions {
    /// Standard-Beziehungstypen, die im Picker angezeigt werden.
    /// "Sonstige" dient als Fallback für benutzerdefinierte Eingaben.
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

    /// Prüft, ob ein Wert in der vordefinierten Liste enthalten ist.
    /// Gibt `false` zurück bei benutzerdefinierten Beziehungen (z.B. "Oma", "Onkel").
    static func isPredefined(_ value: String) -> Bool {
        predefined.contains(value)
    }

    /// Maps German canonical DB values to localized display strings.
    /// Custom (non-predefined) values are returned as-is.
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
        default: return relation
        }
    }
}
