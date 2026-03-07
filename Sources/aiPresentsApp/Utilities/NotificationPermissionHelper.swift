import Foundation
import UserNotifications
import SwiftUI

/// Helper for managing notification permissions with proper async/await support
@MainActor
final class NotificationPermissionHelper: ObservableObject {
    // MARK: - Published Properties
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var isEnabled: Bool = false
    @Published var isLoading: Bool = false

    // MARK: - Singleton
    static let shared = NotificationPermissionHelper()

    private init() {
        Task {
            await checkCurrentStatus()
        }
    }

    // MARK: - Status Check

    /// Check the current notification authorization status
    func checkCurrentStatus() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        await MainActor.run {
            authorizationStatus = settings.authorizationStatus
            isEnabled = settings.authorizationStatus == .authorized
        }
    }

    // MARK: - Permission Request

    /// Request notification permission with optional explanation
    /// - Parameter shouldShowRationale: Whether to show a custom rationale before system prompt
    /// - Returns: True if permission was granted
    @discardableResult
    func requestPermission(shouldShowRationale: Bool = false) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        // If already authorized, return true
        if authorizationStatus == .authorized {
            return true
        }

        // If previously denied, user needs to go to settings
        if authorizationStatus == .denied {
            return false
        }

        do {
            let center = UNUserNotificationCenter.current()
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])

            await checkCurrentStatus()

            if granted {
                AppLogger.notifications.info("Notification permission granted")
            } else {
                AppLogger.notifications.warning("Notification permission denied")
            }

            return granted
        } catch {
            AppLogger.notifications.error("Failed to request notification permission", error: error)
            return false
        }
    }

    // MARK: - Open Settings

    /// Open system settings for notification permissions
    func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL) { success in
                if success {
                    AppLogger.ui.info("Opened system settings for notifications")
                } else {
                    AppLogger.ui.warning("Failed to open system settings")
                }
            }
        }
    }

    // MARK: - Utility Properties

    /// Whether permission was previously denied
    var isDenied: Bool {
        authorizationStatus == .denied
    }

    /// Whether permission has not been requested yet
    var isNotDetermined: Bool {
        authorizationStatus == .notDetermined
    }

    /// Whether permission is granted
    var isAuthorized: Bool {
        authorizationStatus == .authorized
    }

    /// User-friendly status description
    var statusDescription: String {
        switch authorizationStatus {
        case .notDetermined:
            return String(localized: "Nicht angefragt")
        case .denied:
            return String(localized: "Abgelehnt")
        case .authorized:
            return String(localized: "Aktiviert")
        case .provisional:
            return String(localized: "Provisorisch")
        case .ephemeral:
            return String(localized: "Ephemeral")
        @unknown default:
            return String(localized: "Unbekannt")
        }
    }

    /// User-friendly action message
    var actionMessage: String {
        switch authorizationStatus {
        case .notDetermined:
            return String(localized: "Erhalte Benachrichtigungen für Geburtstage")
        case .denied:
            return String(localized: "Benachrichtigungen in den Einstellungen aktivieren")
        case .authorized:
            return String(localized: "Benachrichtigungen aktiv")
        default:
            return String(localized: "Status unbekannt")
        }
    }

    /// Icon name for status
    var statusIcon: String {
        switch authorizationStatus {
        case .notDetermined:
            return "questionmark.circle"
        case .denied:
            return "exclamationmark.triangle.fill"
        case .authorized:
            return "checkmark.circle.fill"
        default:
            return "bell.slash"
        }
    }

    /// Color for status
    var statusColor: Color {
        switch authorizationStatus {
        case .notDetermined:
            return .gray
        case .denied:
            return .orange
        case .authorized:
            return .green
        default:
            return .gray
        }
    }
}

// MARK: - SwiftUI View Modifier

extension View {
    /// Adds a notification permission check on appear
    func checkNotificationPermission() -> some View {
        self.onAppear {
            Task {
                await NotificationPermissionHelper.shared.checkCurrentStatus()
            }
        }
    }
}

// MARK: - Notification Permission View

struct NotificationPermissionView: View {
    @StateObject private var helper = NotificationPermissionHelper.shared
    @State private var showingSettings = false

    let title: String
    let message: String
    let onPermissionGranted: (() -> Void)?
    let onPermissionDenied: (() -> Void)?

    init(
        title: String = "Benachrichtigungen",
        message: String = "Erhalte Erinnerungen für anstehende Geburtstage",
        onPermissionGranted: (() -> Void)? = nil,
        onPermissionDenied: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.onPermissionGranted = onPermissionGranted
        self.onPermissionDenied = onPermissionDenied
    }

    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: helper.statusIcon)
                .font(.system(size: 60))
                .foregroundStyle(helper.statusColor)

            // Title and message
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Status indicator
            HStack(spacing: 8) {
                Image(systemName: helper.statusIcon)
                    .foregroundStyle(helper.statusColor)

                Text(helper.statusDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
            .clipShape(.rect(cornerRadius: 8))

            // Action button
            Button(action: handleAction) {
                if helper.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(actionButtonTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppColor.primary)
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 12))
            .disabled(helper.isLoading)

            // Settings link (if denied)
            if helper.isDenied {
                Button(action: {
                    showingSettings = true
                    HapticFeedback.light()
                }) {
                    Text("In Einstellungen öffnen")
                        .font(.caption)
                        .foregroundStyle(AppColor.primary)
                }
            }
        }
        .padding(24)
        .alert("Einstellungen öffnen?", isPresented: $showingSettings) {
            Button("Abbrechen", role: .cancel) { }
            Button("Öffnen") {
                helper.openSettings()
            }
        } message: {
            Text("Möchtest du die Systemeinstellungen für Benachrichtigungen öffnen?")
        }
    }

    private var actionButtonTitle: String {
        if helper.isLoading {
            return String(localized: "Laden...")
        }

        switch helper.authorizationStatus {
        case .notDetermined:
            return String(localized: "Aktivieren")
        case .denied:
            return String(localized: "Einstellungen öffnen")
        case .authorized:
            return String(localized: "Aktiviert ✓")
        default:
            return String(localized: "Status prüfen")
        }
    }

    private func handleAction() {
        HapticFeedback.medium()

        Task {
            if helper.isDenied {
                helper.openSettings()
            } else if helper.isNotDetermined {
                let granted = await helper.requestPermission()
                await MainActor.run {
                    if granted {
                        onPermissionGranted?()
                    } else {
                        onPermissionDenied?()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Permission Not Determined") {
    NotificationPermissionView()
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Permission Authorized") {
    struct PreviewWrapper: View {
        @StateObject private var helper = NotificationPermissionHelper.shared

        var body: some View {
            NotificationPermissionView()
                .padding()
                .background(Color(.systemGroupedBackground))
                .onAppear {
                    // Simulate authorized status for preview
                    helper.authorizationStatus = .authorized
                    helper.isEnabled = true
                }
        }
    }

    return PreviewWrapper()
}

#Preview("Permission Denied") {
    struct PreviewWrapper: View {
        @StateObject private var helper = NotificationPermissionHelper.shared

        var body: some View {
            NotificationPermissionView()
                .padding()
                .background(Color(.systemGroupedBackground))
                .onAppear {
                    // Simulate denied status for preview
                    helper.authorizationStatus = .denied
                    helper.isEnabled = false
                }
        }
    }

    return PreviewWrapper()
}
