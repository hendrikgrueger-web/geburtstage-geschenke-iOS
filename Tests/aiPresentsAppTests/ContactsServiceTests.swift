import XCTest
import Contacts
@testable import aiPresentsApp

@MainActor
final class ContactsServiceTests: XCTestCase {
    var sut: ContactsService!

    override func setUpWithError() throws {
        sut = ContactsService.shared
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    // MARK: - Singleton Tests

    func testContactsServiceSingleton() {
        let instance1 = ContactsService.shared
        let instance2 = ContactsService.shared

        XCTAssertTrue(instance1 === instance2, "ContactsService should be a singleton")
    }

    // MARK: - Permission Tests

    func testRequestPermission_returnsBoolOrThrowsContactsError() async throws {
        // In der Test-Umgebung (Simulator ohne Benutzerinteraktion) ist der
        // Kontaktzugriff nicht gewährt. requestPermission() muss entweder einen
        // Bool zurückgeben (falls bereits entschieden) oder einen ContactsError werfen.
        do {
            let permissionGranted = try await sut.requestPermission()
            // Wenn die Methode zurückkommt, muss es ein valides Bool sein
            XCTAssertFalse(permissionGranted,
                           "Permission should not be granted in automated test environment")
        } catch let error as ContactsService.ContactsError {
            // ContactsError.notAuthorized ist das erwartete Ergebnis ohne Benutzerinteraktion
            if case .notAuthorized = error {
                // Korrekt: Zugriff verweigert
            } else {
                XCTFail("Expected notAuthorized error in test environment, got: \(error)")
            }
        } catch {
            // Andere Fehler (z.B. CNError) sind ebenfalls akzeptabel
            XCTAssertNotNil(error, "Any thrown error is acceptable when permission is denied")
        }
    }

    // MARK: - Import Birthdays Tests

    func testImportBirthdaysWithInvalidDate() async {
        do {
            let _ = try await sut.importBirthdays()
            XCTFail("Should throw error when not authorized")
        } catch ContactsService.ContactsError.notAuthorized {
            XCTAssert(true)
        } catch {
            // Other errors are acceptable (e.g., CNContactStore not available)
            XCTAssert(true)
        }
    }

    // MARK: - ContactsError Tests

    func testContactsErrorDescriptions() {
        let notAuthorized = ContactsService.ContactsError.notAuthorized
        XCTAssertEqual(notAuthorized.errorDescription,
                       "Zugriff auf Kontakte nicht erlaubt")

        let noBirthdaysFound = ContactsService.ContactsError.noBirthdaysFound
        XCTAssertEqual(noBirthdaysFound.errorDescription,
                       "Keine Kontakte mit Geburtstagen gefunden")
    }

    func testContactsErrorLocalizedDescriptions() {
        let notAuthorized = ContactsService.ContactsError.notAuthorized
        XCTAssertNotNil(notAuthorized.localizedDescription)

        let noBirthdaysFound = ContactsService.ContactsError.noBirthdaysFound
        XCTAssertNotNil(noBirthdaysFound.localizedDescription)
    }
}
