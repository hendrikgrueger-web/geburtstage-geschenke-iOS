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

    private var promptContextFingerprint: [String] {
        let peopleFingerprint = people
            .sorted { $0.id.uuidString < $1.id.uuidString }
            .map {
                [
                    $0.id.uuidString,
                    $0.displayName,
                    $0.relation,
                    String($0.birthday.timeIntervalSince1970),
                    String($0.birthYearKnown),
                    String($0.skipGift),
                    $0.hobbies.joined(separator: ",")
                ].joined(separator: "|")
            }

        let giftIdeasFingerprint = giftIdeas
            .sorted { $0.id.uuidString < $1.id.uuidString }
            .map {
                [
                    $0.id.uuidString,
                    $0.personId.uuidString,
                    $0.title,
                    $0.status.rawValue
                ].joined(separator: "|")
            }

        let giftHistoryFingerprint = giftHistory
            .sorted { $0.id.uuidString < $1.id.uuidString }
            .map {
                [
                    $0.id.uuidString,
                    $0.personId.uuidString,
                    $0.title,
                    String($0.year)
                ].joined(separator: "|")
            }

        return peopleFingerprint + ["--gift-ideas--"] + giftIdeasFingerprint + ["--gift-history--"] + giftHistoryFingerprint
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
                    autoFocus: !ProcessInfo.processInfo.arguments.contains("--show-chat")
                )
            }
            .navigationTitle("KI-Assistent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .onDisappear {
            viewModel.cancelPendingRequests()
        }
        .onAppear {
            viewModel.configure(
                people: people,
                giftIdeas: giftIdeas,
                giftHistory: giftHistory,
                modelContext: modelContext
            )
        }
        .onChange(of: promptContextFingerprint) { _, _ in
            viewModel.refreshContext(
                people: people,
                giftIdeas: giftIdeas,
                giftHistory: giftHistory,
                modelContext: modelContext
            )
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
                .presentationDetents([.large])
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
                        let isLastAssistant = message.role == .assistant && message.id == viewModel.messages.last(where: { $0.role == .assistant })?.id
                        ChatBubbleView(
                            message: message,
                            clarifyOptions: isLastAssistant ? viewModel.mentionedPersons : [],
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

            // Privacy-Badge
            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.caption2)
                Text("Übertragen werden Vornamen und anonymisierte Eckdaten der Kontakte (Altersgruppe, Geschlecht) — nur für die Anfrage, nicht dauerhaft gespeichert (Zero Data Retention). Nachnamen und Geburtsdaten bleiben lokal.")
                    .font(.caption2)
            }
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())

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

        viewModel.sendMessage(text)
    }

    private func handleActionTap(_ action: ChatAction) {
        Task {
            await viewModel.processAction(action)
        }
    }

    private func handleClarifySelection(_ person: PersonRef) {
        viewModel.mentionedPersons = []
        // Vollnamen + Beziehung senden → System-Injection findet exakten Match
        inputText = "\(person.displayName) (\(person.relation))"
        sendMessage()
    }

    private func toggleRecording() {
        if isRecording {
            speechService.stopTranscribing()
            isRecording = false
            return
        }
        // Doppelklick-Guard: waehrend Permission-Dialog laeuft, kein zweiter Task
        guard !speechService.isTranscribing else { return }
        Task {
            do {
                try await speechService.startTranscribing { transcript in
                    Task { @MainActor in
                        inputText = transcript
                    }
                }
                isRecording = true
            } catch {
                isRecording = false
                AppLogger.ui.error("Spracheingabe fehlgeschlagen", error: error)
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
