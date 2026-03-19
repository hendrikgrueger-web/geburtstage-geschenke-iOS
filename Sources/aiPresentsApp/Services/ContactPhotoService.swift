import Contacts
import UIKit

/// Lädt Kontaktfotos on-demand aus dem Adressbuch und cached sie im Memory.
/// Fotos werden NICHT in SwiftData gespeichert — sie können sich ändern und sind zu groß.
///
/// **Thread-Safety:** Cache-Zugriff und -Schreiben laufen auf dem MainActor.
/// Der teure CNContactStore-I/O wird im Hintergrund erledigt und das Ergebnis
/// danach auf dem MainActor in den Cache geschrieben (kein Main-Thread-Block).
@MainActor
final class ContactPhotoService: ObservableObject {
    static let shared = ContactPhotoService()

    private let cache: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        c.countLimit = 200
        return c
    }()
    private var noPhotoIdentifiers: Set<String> = []
    /// Verhindert parallele Lade-Requests für dieselbe ID.
    private var loadingIdentifiers: Set<String> = []

    private init() {}

    /// Gibt das gecachte Kontaktfoto zurück, oder `nil` wenn noch nicht geladen.
    /// Bei einem Cache-Miss wird ein asynchroner Ladevorgang gestartet;
    /// wenn das Foto ankommt, published `objectWillChange` damit Views neu rendern.
    func photo(for contactIdentifier: String) -> UIImage? {
        if let cached = cache.object(forKey: contactIdentifier as NSString) {
            return cached
        }
        if noPhotoIdentifiers.contains(contactIdentifier) {
            return nil
        }
        // Demo-Kontakte: Gebundelte Fotos synchron laden (nur Datei-I/O, akzeptabel)
        if contactIdentifier.hasPrefix("demo-") {
            if let image = loadDemoPhoto(for: contactIdentifier) {
                cache.setObject(image, forKey: contactIdentifier as NSString)
                return image
            }
            noPhotoIdentifiers.insert(contactIdentifier)
            return nil
        }
        // Cache-Miss: asynchron im Hintergrund laden, um den Main Thread nicht zu blockieren
        guard !loadingIdentifiers.contains(contactIdentifier) else { return nil }
        loadingIdentifiers.insert(contactIdentifier)

        Task.detached(priority: .userInitiated) {
            let image = await Self.fetchPhoto(for: contactIdentifier)
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.loadingIdentifiers.remove(contactIdentifier)
                if let image {
                    self.cache.setObject(image, forKey: contactIdentifier as NSString)
                } else {
                    self.noPhotoIdentifiers.insert(contactIdentifier)
                }
                self.objectWillChange.send()
            }
        }
        return nil
    }

    /// Cache leeren (z.B. bei App-Wechsel aus dem Hintergrund).
    func clearCache() {
        cache.removeAllObjects()
        noPhotoIdentifiers.removeAll()
        loadingIdentifiers.removeAll()
    }

    private func loadDemoPhoto(for identifier: String) -> UIImage? {
        guard let url = Bundle.main.url(forResource: identifier, withExtension: "jpg"),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }

    /// Führt den CNContactStore-Fetch im Hintergrund durch (nonisolated → kein Main-Thread-Block).
    private static nonisolated func fetchPhoto(for identifier: String) async -> UIImage? {
        guard CNContactStore.authorizationStatus(for: .contacts) == .authorized else {
            return nil
        }
        let store = CNContactStore()
        let keys = [CNContactThumbnailImageDataKey] as [CNKeyDescriptor]
        guard let contact = try? store.unifiedContact(withIdentifier: identifier, keysToFetch: keys),
              let data = contact.thumbnailImageData else {
            return nil
        }
        return UIImage(data: data)
    }
}
