import LocalAuthentication
import SwiftUI

@MainActor
@Observable
final class AppLockManager {
    static let shared = AppLockManager()

    private(set) var isLocked = false
    @ObservationIgnored
    @AppStorage("appLockEnabled") var isEnabled = false

    private init() {
        if isEnabled {
            isLocked = true
        }
    }

    var isBiometricAvailable: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    var biometricType: LABiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType
    }

    var biometricName: String {
        switch biometricType {
        case .none: String(localized: "Biometrie")
        case .faceID: String(localized: "Face ID")
        case .touchID: String(localized: "Touch ID")
        case .opticID: String(localized: "Optic ID")
        @unknown default: String(localized: "Biometrie")
        }
    }

    var biometricIcon: String {
        switch biometricType {
        case .none: "lock.shield"
        case .faceID: "faceid"
        case .touchID: "touchid"
        case .opticID: "opticid"
        @unknown default: "lock.shield"
        }
    }

    func unlock() async {
        let context = LAContext()
        context.localizedCancelTitle = String(localized: "Abbrechen")

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: String(localized: "Entsperre die App, um deine Geschenkideen zu sehen")
            )
            if success {
                isLocked = false
            }
        } catch {
            AppLogger.ui.warning("Biometric auth failed")
        }
    }

    func lockIfEnabled() {
        if isEnabled {
            isLocked = true
        }
    }
}
