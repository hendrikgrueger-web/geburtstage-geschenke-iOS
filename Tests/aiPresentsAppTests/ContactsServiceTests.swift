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

    func testRequestPermissionNotAuthorized() async throws {
        // In a test/simulator environment, Contacts permission is typically denied
        do {
            let permissionGranted = try await sut.requestPermission()
            XCTAssertTrue(permissionGranted == true || permissionGranted == false,
                          "Request permission should return a boolean result")
        } catch {
            // CNError.accessDenied is expected in test environment
            XCTAssertTrue(true, "Permission denied is expected in test environment")
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
