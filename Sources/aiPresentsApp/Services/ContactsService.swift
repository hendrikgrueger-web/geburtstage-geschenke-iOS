import Foundation
import Contacts
import UIKit

// MARK: - ContactsServiceProtocol

/// Protocol für den Kontakte-Service — ermöglicht Dependency Injection und Testbarkeit.
@MainActor
protocol ContactsServiceProtocol {
    func requestPermission() async throws -> Bool
    func importBirthdays() async throws -> [PersonRef]
}

// MARK: - ContactsService

@MainActor
final class ContactsService: ContactsServiceProtocol {
    static let shared = ContactsService()

    private init() {}

    func requestPermission() async throws -> Bool {
        return try await CNContactStore().requestAccess(for: .contacts)
    }

    func importBirthdays() async throws -> [PersonRef] {
        guard CNContactStore.authorizationStatus(for: .contacts) == .authorized else {
            throw ContactsError.notAuthorized
        }

        // Kontakt-Daten inkl. Thumbnail extrahieren (off-MainActor)
        let contactData = try await fetchContactData()

        // Foto-Cache vorbefuellen, damit die Bilder beim ersten Render der
        // Liste sofort sichtbar sind und nicht erst per Cache-Miss async
        // nachgeladen werden muessen.
        for data in contactData {
            ContactPhotoService.shared.preloadFromImport(
                imageData: data.thumbnailData,
                for: data.identifier
            )
        }

        // Zurück auf MainActor: PersonRef-Objekte erstellen (SwiftData erfordert MainActor)
        var importedPeople: [PersonRef] = []
        for data in contactData {
            let person = PersonRef(
                contactIdentifier: data.identifier,
                displayName: data.displayName,
                birthday: data.birthday
            )
            person.birthYearKnown = data.birthYearKnown
            importedPeople.append(person)
        }

        if importedPeople.isEmpty {
            throw ContactsError.noBirthdaysFound
        }

        return importedPeople
    }

    /// Kontakt-Daten vom Gerät lesen — läuft NICHT auf dem Main Thread.
    private nonisolated func fetchContactData() async throws -> [ImportedContactData] {
        let store = CNContactStore()
        let keys = [CNContactGivenNameKey,
                    CNContactFamilyNameKey,
                    CNContactBirthdayKey,
                    CNContactIdentifierKey,
                    CNContactThumbnailImageDataKey] as [CNKeyDescriptor]

        let request = CNContactFetchRequest(keysToFetch: keys)

        var results: [ImportedContactData] = []

        try store.enumerateContacts(with: request) { contact, stop in
            guard let birthday = contact.birthday else { return }
            guard birthday.month != nil && birthday.day != nil else { return }

            var calendar = Calendar.current
            calendar.timeZone = TimeZone.current
            let yearKnown = birthday.year != nil
            var components = birthday
            components.timeZone = TimeZone.current
            if !yearKnown {
                components.year = 2000
            }
            guard let date = calendar.date(from: components) else { return }

            let displayName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
            guard !displayName.isEmpty else { return }

            results.append(ImportedContactData(
                identifier: contact.identifier,
                displayName: displayName,
                birthday: date,
                birthYearKnown: yearKnown,
                thumbnailData: contact.thumbnailImageData
            ))
        }

        return results
    }

    /// Sendable-Struct für Kontakt-Daten, die über Actor-Grenzen übergeben werden.
    private struct ImportedContactData: Sendable {
        let identifier: String
        let displayName: String
        let birthday: Date
        let birthYearKnown: Bool
        let thumbnailData: Data?
    }

    enum ContactsError: LocalizedError {
        case notAuthorized
        case noBirthdaysFound

        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return String(localized: "Zugriff auf Kontakte nicht erlaubt")
            case .noBirthdaysFound:
                return String(localized: "Keine Kontakte mit Geburtstagen gefunden")
            }
        }
    }
}
