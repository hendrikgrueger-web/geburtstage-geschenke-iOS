import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "gift.fill",
            title: String(localized: "Nie wieder vergessen"),
            description: String(localized: "Behalte alle Geburtstage im Blick und plane Geschenke stressfrei.")
        ),
        OnboardingPage(
            icon: "lightbulb.fill",
            title: String(localized: "Geschenkideen sammeln"),
            description: String(localized: "Speichere Ideen und setze Budgets für jeden Kontakt.")
        ),
        OnboardingPage(
            icon: "bell.fill",
            title: String(localized: "Smarte Erinnerungen"),
            description: String(localized: "Werde rechtzeitig erinnert, damit du perfekt vorbereitet bist.")
        ),
        OnboardingPage(
            icon: "sparkles",
            title: String(localized: "KI-Vorschläge"),
            description: String(localized: "Lass dir kreative Geschenkideen basierend auf Interessen generieren.")
        )
    ]

    // Letzte Seite ist die iCloud-Auswahl
    private var isICloudPage: Bool { currentPage == pages.count }
    private var isLastContentPage: Bool { currentPage == pages.count - 1 }

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
                iCloudOnboardingPage
                    .tag(pages.count)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .accessibilityValue(String(localized: "Seite \(currentPage + 1) von \(pages.count + 1)"))

            if !isICloudPage {
                VStack {
                    Spacer()
                    Button {
                        withAnimation {
                            currentPage = isLastContentPage ? pages.count : currentPage + 1
                        }
                        HapticFeedback.selectionChanged()
                    } label: {
                        Text(String(localized: "Weiter"))
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColor.primary)
                            .clipShape(.rect(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                    .buttonStyle(.pressable)
                    .accessibilityLabel(String(localized: "Weiter"))
                    .accessibilityHint(String(localized: "Nächste Onboarding-Seite"))
                }
            }
        }
    }

    private var iCloudOnboardingPage: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "icloud.fill")
                .font(.system(size: 80))
                .foregroundStyle(AppColor.primary)

            VStack(spacing: 16) {
                Text("iCloud Sync")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColor.textPrimary)

                Text("Sollen deine Geburtstage und Geschenkideen automatisch auf all deinen Apple-Geräten verfügbar sein?")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppColor.textSecondary)
                    .padding(.horizontal)
            }

            VStack(spacing: 12) {
                Button {
                    UserDefaults.standard.set(true, forKey: "iCloudSyncEnabled")
                    completeOnboarding()
                } label: {
                    HStack {
                        Image(systemName: "icloud.fill")
                        Text("iCloud Sync aktivieren")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColor.primary)
                    .foregroundStyle(.white)
                    .clipShape(.rect(cornerRadius: 12))
                }
                .buttonStyle(.pressable)
                .accessibilityLabel(String(localized: "iCloud Sync aktivieren"))
                .accessibilityHint(String(localized: "Daten werden auf allen deinen Apple-Geräten synchronisiert"))

                Button {
                    UserDefaults.standard.set(false, forKey: "iCloudSyncEnabled")
                    completeOnboarding()
                } label: {
                    Text("Nur lokal speichern")
                        .font(.subheadline)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .accessibilityLabel(String(localized: "Nur lokal speichern"))
                .accessibilityHint(String(localized: "Daten werden nur auf diesem Gerät gespeichert"))
            }
            .padding(.horizontal)

            Text("Du kannst das jederzeit in den Einstellungen ändern.")
                .font(.caption)
                .foregroundStyle(AppColor.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
        }
        .padding()
    }

    private func completeOnboarding() {
        HapticFeedback.success()
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundStyle(AppColor.primary)
                .accessibilityHidden(true)

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppColor.textPrimary)

                Text(page.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppColor.textSecondary)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
        .accessibilityElement(children: .combine)
    }
}
