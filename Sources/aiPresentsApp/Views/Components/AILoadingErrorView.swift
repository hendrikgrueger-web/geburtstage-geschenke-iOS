import SwiftUI

// MARK: - AILoadingView

/// Loading-Indikator für KI-Operationen.
/// Zwei Varianten: `.simple` (ProgressView-Spinner) und `.animated` (rotierender Circle).
struct AILoadingView: View {
    enum Style {
        /// Einfacher System-ProgressView mit einer Nachricht darunter.
        case simple(message: String)
        /// Animierter Circle mit Titel und Untertitel.
        case animated(title: String, subtitle: String)
    }

    let style: Style

    /// Für die Rotationsanimation des animierten Circles.
    @State private var isAnimating = false

    var body: some View {
        Section {
            VStack(spacing: style.verticalSpacing) {
                switch style {
                case .simple(let message):
                    ProgressView()
                        .controlSize(.large)

                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(AppColor.textSecondary)

                case .animated(let title, let subtitle):
                    ZStack {
                        Circle()
                            .stroke(AppColor.primary.opacity(0.2), lineWidth: 4)
                            .frame(width: 80, height: 80)

                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(
                                AppColor.primary,
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(isAnimating ? 360 : 0))
                            .animation(
                                .linear(duration: 1).repeatForever(autoreverses: false),
                                value: isAnimating
                            )
                    }
                    .onAppear { isAnimating = true }

                    VStack(spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(AppColor.textPrimary)

                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, style.verticalPadding)
        }
    }
}

private extension AILoadingView.Style {
    var verticalSpacing: CGFloat {
        switch self {
        case .simple: return 12
        case .animated: return 16
        }
    }

    var verticalPadding: CGFloat {
        switch self {
        case .simple: return 24
        case .animated: return 0 // bereits durch .padding() im Section-Content gehandhabt
        }
    }
}

// MARK: - AIErrorView

/// Fehler-Anzeige für KI-Operationen.
/// Zeigt entweder einen Consent-Hinweis (wenn `needsConsent == true`) oder
/// eine generische Fehlermeldung mit Retry-Button.
struct AIErrorView: View {
    let error: String
    let needsConsent: Bool
    let consentDescription: String
    let onConsent: () -> Void
    let onRetry: (() -> Void)?

    /// Convenience-Init mit Standard-Consent-Beschreibung.
    init(
        error: String,
        needsConsent: Bool,
        consentDescription: String = String(localized: "Für KI-Features wird eine Einwilligung zur anonymisierten Datenverarbeitung benötigt."),
        onConsent: @escaping () -> Void,
        onRetry: (() -> Void)? = nil
    ) {
        self.error = error
        self.needsConsent = needsConsent
        self.consentDescription = consentDescription
        self.onConsent = onConsent
        self.onRetry = onRetry
    }

    var body: some View {
        Section {
            VStack(spacing: 16) {
                if needsConsent {
                    consentContent
                } else {
                    errorContent
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
        }
    }

    private var consentContent: some View {
        Group {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 50))
                .foregroundStyle(AppColor.primary)

            Text("Einwilligung erforderlich")
                .font(.headline)
                .foregroundStyle(AppColor.textPrimary)

            Text(consentDescription)
                .font(.subheadline)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)

            Button(action: onConsent) {
                HStack {
                    Image(systemName: "checkmark.shield")
                    Text("Einwilligung erteilen")
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var errorContent: some View {
        Group {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(AppColor.accent)

            Text("Fehler")
                .font(.headline)
                .foregroundStyle(AppColor.textPrimary)

            Text(error)
                .font(.subheadline)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)

            if let onRetry {
                Button(String(localized: "Erneut versuchen"), action: onRetry)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}
