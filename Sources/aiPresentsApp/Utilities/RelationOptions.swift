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
}
