import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var showingOnboarding = true

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "gift.fill",
            title: "Nie wieder vergessen",
            description: "Behalte alle Geburtstage im Blick und plane Geschenke stressfrei."
        ),
        OnboardingPage(
            icon: "lightbulb.fill",
            title: "Geschenkideen sammeln",
            description: "Speichere Ideen und setze Budgets für jeden Kontakt."
        ),
        OnboardingPage(
            icon: "bell.fill",
            title: "Smarte Erinnerungen",
            description: "Wende rechtzeitig erinnert, damit du perfekt vorbereitet bist."
        ),
        OnboardingPage(
            icon: "sparkles",
            title: "KI-Vorschläge",
            description: "Lass dir kreative Geschenkideen basierend auf Interessen generieren."
        )
    ]

    var body: some View {
        if showingOnboarding {
            ZStack {
                AppColor.background.ignoresSafeArea()

                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                VStack {
                    Spacer()

                    Button {
                        withAnimation {
                            showingOnboarding = false
                            HapticFeedback.success()
                            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                        }
                    } label: {
                        Text(currentPage == pages.count - 1 ? "Loslegen" : "Überspringen")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColor.primary)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                    .buttonStyle(.pressable)
                }
            }
        } else {
            EmptyView()
        }
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
                .foregroundColor(AppColor.primary)
                .symbolEffect(.bounce, options: .repeating, isActive: true)

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(AppColor.textPrimary)

                Text(page.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(AppColor.textSecondary)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
    }
}
