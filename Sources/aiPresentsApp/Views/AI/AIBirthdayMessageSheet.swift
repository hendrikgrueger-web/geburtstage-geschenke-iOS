import SwiftUI
import SwiftData

struct AIBirthdayMessageSheet: View {
    @Environment(\.dismiss) private var dismiss

    let person: PersonRef

    @AppStorage("senderName") private var senderName: String = ""
    @State private var showingSenderNamePrompt = false
    @State private var senderNameInput: String = ""
    @State private var isLoading = false
    @State private var birthdayMessage: BirthdayMessage?
    @State private var errorMessage: String?
    @State private var showingShareSheet = false
    @State private var shareText: String = ""
    @State private var toast: ToastItem?
    @State private var showingConsentSheet = false
    private let consentManager = AIConsentManager.shared

    var body: some View {
        NavigationStack {
            Form {
                // Person Details Card
                Section {
                    personDetailsCard
                }

                if isLoading {
                    AILoadingView(style: .animated(
                        title: String(localized: "KI schreibt..."),
                        subtitle: String(localized: "Einen Moment bitte...")
                    ))
                } else if let error = errorMessage {
                    AIErrorView(
                        error: error,
                        needsConsent: needsConsent,
                        consentDescription: String(localized: "Für KI-Nachrichten wird eine Einwilligung zur anonymisierten Datenverarbeitung benötigt."),
                        onConsent: { showingConsentSheet = true },
                        onRetry: { generateMessage() }
                    )
                } else if let message = birthdayMessage {
                    messageContentView(message: message)
                } else {
                    generateSection
                }
            }
            .navigationTitle("Geburtstagsnachricht")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if !shareText.isEmpty {
                    ShareSheetView(items: [shareText])
                }
            }
            .alert("Dein Name", isPresented: $showingSenderNamePrompt) {
                TextField("z.B. Papa, Mama, Oma...", text: $senderNameInput)
                Button("Speichern") {
                    senderName = senderNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    generateMessage()
                }
                Button("Ohne Name fortfahren", role: .cancel) {
                    generateMessage()
                }
            } message: {
                Text("Mit welchem Namen möchtest du die Nachricht unterschreiben? Dieser Name wird nur lokal auf deinem Gerät gespeichert.")
            }
        }
        .sheet(isPresented: $showingConsentSheet) {
            AIConsentSheet(isPresented: $showingConsentSheet) {
                consentManager.aiEnabled = true
                errorMessage = nil
                generateMessage()
            }
        }
        .presentationDragIndicator(.visible)
        .toast(item: $toast)
    }

    private var personDetailsCard: some View {
        HStack(spacing: 16) {
            PersonAvatar(person: person, size: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(person.displayName)
                    .font(.headline)
                    .foregroundStyle(AppColor.textPrimary)

                Text(person.relation)
                    .font(.subheadline)
                    .foregroundStyle(AppColor.textSecondary)

                Text(birthdayInfo)
                    .font(.caption)
                    .foregroundStyle(AppColor.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Image(systemName: "cake.fill")
                    .font(.title3)
                    .foregroundStyle(AppColor.accent)

                if let ageString {
                    Text(ageString)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(AppColor.textTertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var birthdayInfo: String {
        let today = Calendar.current.startOfDay(for: Date())
        let daysUntil = BirthdayCalculator.daysUntilBirthday(for: person.birthday, from: today) ?? 0

        if daysUntil == 0 {
            return String(localized: "🎉 Heute!")
        } else if daysUntil == 1 {
            return String(localized: "Morgen")
        } else if daysUntil < 7 {
            return String(localized: "In \(daysUntil) Tagen")
        } else {
            return FormatterHelper.formatBirthday(person.birthday, birthYearKnown: person.birthYearKnown)
        }
    }

    private var ageString: String? {
        guard person.birthYearKnown else { return nil }
        let age = BirthdayDateHelper.age(from: person.birthday, asOf: Date())
        if BirthdayDateHelper.isMilestoneAge(age: age) {
            return "\(age). 🎯"
        }
        return "\(age)."
    }

    private var needsConsent: Bool {
        !consentManager.consentGiven || !consentManager.aiEnabled
    }

    private func messageContentView(message: BirthdayMessage) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                // Greeting
                Text(message.greeting)
                    .font(.headline)
                    .foregroundStyle(AppColor.textPrimary)

                // Body
                Text(message.body)
                    .font(.body)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineSpacing(4)

                Divider()

                // Action Buttons
                VStack(spacing: 12) {
                    // Copy Button
                    Button(action: {
                        copyMessage(message)
                    }) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                                .foregroundStyle(AppColor.primary)
                            Text("In Zwischenablage kopieren")
                                .font(.subheadline)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "In Zwischenablage kopieren"))
                    .accessibilityHint(String(localized: "Kopiert die gesamte Nachricht in die Zwischenablage"))

                    // Share Button
                    Button(action: {
                        shareMessage(message)
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(AppColor.primary)
                            Text("Teilen")
                                .font(.subheadline)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "Teilen"))
                    .accessibilityHint(String(localized: "Teilt die Nachricht über das Share Sheet"))

                    // Regenerate Button
                    Button(action: {
                        generateMessage()
                        HapticFeedback.medium()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(AppColor.accent)
                            Text("Neue Nachricht generieren")
                                .font(.subheadline)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "Neue Nachricht generieren"))
                    .accessibilityHint(String(localized: "Generiert eine alternative Geburtstagsnachricht"))
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Nachricht")
        } footer: {
            Label("Die Nachricht wurde basierend auf Alter, Meilenstein und Sternzeichen personalisiert.", systemImage: "lightbulb.fill")
                .font(.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
    }

    private var generateSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles.text.viewfinder")
                        .font(.title3)
                        .foregroundStyle(AppColor.accent)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Persönliche Geburtstagsnachricht")
                            .font(.headline)
                            .foregroundStyle(AppColor.textPrimary)

                        Text("Die KI erstellt eine herzliche Nachricht basierend auf Alter, Meilenstein und Sternzeichen.")
                            .font(.subheadline)
                            .foregroundStyle(AppColor.textSecondary)
                    }

                    Spacer()
                }

                Button(action: {
                    requestGenerateMessage()
                }) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Nachricht generieren")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.vertical, 4)
        } footer: {
            Label("Tipp: Du kannst die Nachricht nach dem Generieren anpassen oder kopieren.", systemImage: "lightbulb.fill")
                .font(.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
    }

    private func requestGenerateMessage() {
        // Beim ersten Mal nach Absender-Name fragen
        if senderName.isEmpty && !showingSenderNamePrompt {
            senderNameInput = ""
            showingSenderNamePrompt = true
            return
        }
        generateMessage()
    }

    private func generateMessage() {
        isLoading = true
        errorMessage = nil
        birthdayMessage = nil
        HapticFeedback.light()

        let currentPerson = person
        let name = senderName.isEmpty ? nil : senderName
        Task { @MainActor in
            do {
                let message = try await AIService.shared.generateBirthdayMessage(for: currentPerson, senderName: name)
                isLoading = false
                birthdayMessage = message
                HapticFeedback.success()
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                HapticFeedback.error()
            }
        }
    }

    private func copyMessage(_ message: BirthdayMessage) {
        let fullMessage = message.fullText
        UIPasteboard.general.string = fullMessage
        toast = ToastItem.success(String(localized: "Kopiert"), message: String(localized: "Nachricht in Zwischenablage kopiert"))
        HapticFeedback.success()
    }

    private func shareMessage(_ message: BirthdayMessage) {
        shareText = message.fullText
        showingShareSheet = true
        HapticFeedback.light()
    }
}
