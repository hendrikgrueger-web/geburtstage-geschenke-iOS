import SwiftUI
import SwiftData

/// KI-Chat Sheet — konversationeller Einstiegspunkt für alle KI-Interaktionen.
/// Kombiniert Personen-Suche und KI-Chat in einer Oberfläche.
struct AIChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var people: [PersonRef]
    @Query private var giftIdeas: [GiftIdea]
    @Query private var giftHistory: [GiftHistory]

    /// Callback wenn ein Kontakt aus der Suche ausgewählt wird.
    var onPersonSelected: ((PersonRef) -> Void)?

    @State private var viewModel = AIChatViewModel()
    @State private var inputText = ""
    @State private var showingConsentSheet = false
    @State private var isRecording = false
    @State private var speechService = SpeechRecognitionService()

    /// Personen die zum aktuellen Suchtext passen.
    private var searchResults: [PersonRef] {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, viewModel.messages.isEmpty else { return [] }
        let lower = trimmed.lowercased()
        return people.filter {
            $0.displayName.lowercased().contains(lower) ||
            $0.relation.lowercased().contains(lower)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                chatContent
                Divider()
                ChatInputBar(
                    text: $inputText,
                    isLoading: viewModel.isLoading,
                    onSend: sendMessage,
                    onMicTap: toggleRecording,
                    isRecording: isRecording,
                    autoFocus: true
                )
            }
            .navigationTitle("KI-Assistent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .onAppear {
            viewModel.configure(
                people: people,
                giftIdeas: giftIdeas,
                giftHistory: giftHistory,
                modelContext: modelContext
            )
        }
        .onChange(of: people) { _, newVal in
            viewModel.configure(people: newVal, giftIdeas: giftIdeas, giftHistory: giftHistory, modelContext: modelContext)
        }
        .onChange(of: giftIdeas) { _, newVal in
            viewModel.configure(people: people, giftIdeas: newVal, giftHistory: giftHistory, modelContext: modelContext)
        }
        .onChange(of: giftHistory) { _, newVal in
            viewModel.configure(people: people, giftIdeas: giftIdeas, giftHistory: newVal, modelContext: modelContext)
        }
        .sheet(item: $viewModel.pendingGiftIdeaPerson) { person in
            AddGiftIdeaSheet(
                person: person,
                prefillTitle: viewModel.pendingGiftIdeaTitle,
                prefillNote: viewModel.pendingGiftIdeaNote
            )
        }
        .sheet(item: $viewModel.pendingSuggestionsPerson) { person in
            AIGiftSuggestionsSheet(person: person)
        }
        .sheet(isPresented: $showingConsentSheet) {
            AIConsentSheet(isPresented: $showingConsentSheet) {
                // Nach Consent: Nachricht erneut senden
                if !inputText.isEmpty {
                    sendMessage()
                }
            }
        }
    }

    // MARK: - Chat Content

    private var chatContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if viewModel.messages.isEmpty && searchResults.isEmpty {
                        welcomeView
                    }

                    // Suchergebnisse anzeigen
                    if !searchResults.isEmpty {
                        searchResultsView
                    }

                    ForEach(viewModel.messages) { message in
                        ChatBubbleView(
                            message: message,
                            clarifyOptions: message.action?.type == .clarifyPerson ? viewModel.clarifyOptions : [],
                            onActionTap: { action in
                                handleActionTap(action)
                            },
                            onClarifyTap: { person in
                                handleClarifySelection(person)
                            }
                        )
                        .id(message.id)
                    }

                    if viewModel.isLoading {
                        TypingIndicatorView()
                            .id("typing")
                    }
                }
                .padding(.vertical, 16)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: viewModel.isLoading) { _, loading in
                if loading {
                    scrollToBottom(proxy: proxy)
                }
            }
        }
    }

    // MARK: - Welcome

    private var welcomeView: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 40)

            ZStack {
                Circle()
                    .fill(AppColor.secondary.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "sparkles")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(AppColor.secondary)
            }

            VStack(spacing: 8) {
                Text("Hallo!")
                    .font(.title2.bold())
                Text("Ich helfe dir bei Geschenkideen und Geburtstagen.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Beispiel-Chips
            FlowLayout(spacing: 8) {
                ForEach(viewModel.welcomeChips, id: \.message) { chip in
                    Button {
                        inputText = chip.message
                        sendMessage()
                    } label: {
                        Text(chip.label)
                            .font(.subheadline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(AppColor.secondary.opacity(0.1))
                            .foregroundStyle(AppColor.secondary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private func sendMessage() {
        // Spracheingabe stoppen falls aktiv
        if isRecording {
            speechService.stopTranscribing()
            isRecording = false
        }

        let text = inputText
        inputText = ""

        // Consent prüfen — Chat braucht v2
        guard AIConsentManager.shared.canUseChat else {
            if !AIConsentManager.shared.consentGiven || AIConsentManager.shared.needsChatConsentUpgrade {
                inputText = text // Text wiederherstellen
                showingConsentSheet = true
                return
            }
            // API-Key fehlt
            viewModel.messages.append(ChatMessage(
                role: .assistant,
                content: String(localized: "KI-Features sind nicht verfügbar. Bitte konfiguriere den API-Key.")
            ))
            return
        }

        Task {
            await viewModel.sendMessage(text)
        }
    }

    private func handleActionTap(_ action: ChatAction) {
        Task {
            await viewModel.processAction(action)
        }
    }

    private func handleClarifySelection(_ person: PersonRef) {
        viewModel.clarifyOptions = []
        inputText = person.displayName
        sendMessage()
    }

    private func toggleRecording() {
        if isRecording {
            speechService.stopTranscribing()
            isRecording = false
        } else {
            Task {
                do {
                    isRecording = true
                    try await speechService.startTranscribing { transcript in
                        Task { @MainActor in
                            inputText = transcript
                        }
                    }
                } catch {
                    isRecording = false
                    AppLogger.ui.error("Spracheingabe fehlgeschlagen", error: error)
                }
            }
        }
    }

    // MARK: - Search Results

    private var searchResultsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Kontakte")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)

            ForEach(searchResults.prefix(5)) { person in
                Button {
                    dismiss()
                    onPersonSelected?(person)
                } label: {
                    HStack(spacing: 12) {
                        PersonAvatar(person: person, size: 36)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(person.displayName)
                                .font(.body)
                                .foregroundStyle(AppColor.textPrimary)
                            Text(person.relation)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if let days = BirthdayCalculator.daysUntilBirthday(
                            for: person.birthday,
                            from: Calendar.current.startOfDay(for: Date())
                        ) {
                            BirthdayCountdownBadge(daysUntil: days)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.3)) {
            if viewModel.isLoading {
                proxy.scrollTo("typing", anchor: .bottom)
            } else if let lastMessage = viewModel.messages.last {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}
