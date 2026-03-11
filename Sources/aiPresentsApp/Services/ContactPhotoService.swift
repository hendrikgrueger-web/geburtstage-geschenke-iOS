import Contacts
import UIKit

/// Lädt Kontaktfotos on-demand aus dem Adressbuch und cached sie im Memory.
/// Fotos werden NICHT in SwiftData gespeichert — sie können sich ändern und sind zu groß.
@MainActor
final class ContactPhotoService {
    static let shared = ContactPhotoService()

    private var cache: [String: UIImage] = [:]
    private var noPhotoIdentifiers: Set<String> = []

    private init() {}

    /// Gibt das Kontaktfoto für den gegebenen contactIdentifier zurück, oder nil.
    func photo(for contactIdentifier: String) -> UIImage? {
        if let cached = cache[contactIdentifier] {
            return cached
        }
        if noPhotoIdentifiers.contains(contactIdentifier) {
            return nil
        }
        // Demo-Kontakte: Gebundelte Fotos laden
        if contactIdentifier.hasPrefix("demo-") {
            if let image = loadDemoPhoto(for: contactIdentifier) {
                cache[contactIdentifier] = image
                return image
            }
        }
        // Lazy load beim ersten Zugriff
        let image = loadPhoto(for: contactIdentifier)
        if let image {
            cache[contactIdentifier] = image
        } else {
            noPhotoIdentifiers.insert(contactIdentifier)
        }
        return image
    }

    /// Cache leeren (z.B. bei App-Wechsel aus dem Hintergrund).
    func clearCache() {
        cache.removeAll()
        noPhotoIdentifiers.removeAll()
    }

    private func loadDemoPhoto(for identifier: String) -> UIImage? {
        guard let url = Bundle.main.url(forResource: identifier, withExtension: "jpg"),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }

    private nonisolated func loadPhoto(for identifier: String) -> UIImage? {
        let store = CNContactStore()
        guard CNContactStore.authorizationStatus(for: .contacts) == .authorized else {
            return nil
        }
        let keys = [CNContactThumbnailImageDataKey] as [CNKeyDescriptor]
        guard let contact = try? store.unifiedContact(withIdentifier: identifier, keysToFetch: keys),
              let data = contact.thumbnailImageData else {
            return nil
        }
        return UIImage(data: data)
    }
}
