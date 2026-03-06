import SwiftUI
import SwiftData

/// KI-Chat Sheet — konversationeller Einstiegspunkt für alle KI-Interaktionen.
struct AIChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var people: [PersonRef]
    @Query private var giftIdeas: [GiftIdea]
    @Query private var giftHistory: [GiftHistory]

    @State private var viewModel = AIChatViewModel()
    @State private var inputText = ""
    @State private var showingConsentSheet = false
    @State private var isRecording = false
    @State private var speechService = SpeechRecognitionService()

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
                    isRecording: isRecording
                )
            }
            .navigationTitle("KI-Assistent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel(String(localized: "Schließen"))
                }
            }
        }
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
                    if viewModel.messages.isEmpty {
                        welcomeView
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
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "sparkles")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(.purple)
            }

            VStack(spacing: 8) {
                Text("Hallo!")
                    .font(.title2.bold())
                Text("Ich helfe dir bei Geschenkideen und Geburtstagen.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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
                            .background(Color.purple.opacity(0.1))
                            .foregroundColor(.purple)
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
