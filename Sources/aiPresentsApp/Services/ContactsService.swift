import Foundation
import Contacts

class ContactsService: ObservableObject {
    static let shared = ContactsService()

    private let store = CNContactStore()

    private init() {}

    func requestPermission() async throws -> Bool {
        let status = await store.requestAccess(for: .contacts)
        return status.granted
    }

    func importBirthdays() async throws -> [PersonRef] {
        guard CNContactStore.authorizationStatus(for: .contacts) == .authorized else {
            throw ContactsError.notAuthorized
        }

        let keys = [CNContactGivenNameKey,
                    CNContactFamilyNameKey,
                    CNContactBirthdayKey,
                    CNContactIdentifierKey] as [CNKeyDescriptor]

        let request = CNContactFetchRequest(keysToFetch: keys)

        var importedPeople: [PersonRef] = []

        try store.enumerateContacts(with: request) { contact, stop in
            guard let birthday = contact.birthday else { return }

            let calendar = Calendar.current
            var components = birthday
            components.year = 2000 // Dummy year for date creation
            if let date = calendar.date(from: components) {
                let displayName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)

                let person = PersonRef(
                    contactIdentifier: contact.identifier,
                    displayName: displayName,
                    birthday: date
                )

                importedPeople.append(person)
            }
        }

        return importedPeople
    }

    enum ContactsError: LocalizedError {
        case notAuthorized

        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "Zugriff auf Kontakte nicht erlaubt"
            }
        }
    }
}
