import SwiftUI

struct AppLockView: View {
    @State private var appLock = AppLockManager.shared

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppColor.accent)

            VStack(spacing: 8) {
                Text("App gesperrt")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Deine Geschenkideen sind geschützt")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button {
                Task { await appLock.unlock() }
            } label: {
                Label(String(localized: "Mit \(appLock.biometricName) entsperren"), systemImage: appLock.biometricIcon)
                    .font(.headline)
                    .frame(maxWidth: 280)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColor.accent)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .task {
            await appLock.unlock()
        }
    }
}
