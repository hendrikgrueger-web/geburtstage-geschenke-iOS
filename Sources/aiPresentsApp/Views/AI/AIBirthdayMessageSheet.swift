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

    var body: some View {
        NavigationStack {
            Form {
                // Person Details Card
                Section {
                    personDetailsCard
                }

                if isLoading {
                    loadingState
                } else if let error = errorMessage {
                    errorState(error)
                } else if let message = birthdayMessage {
                    messageContentView(message: message)
                } else {
                    generateSection
                }
            }
            .navigationTitle("Geburtstagsnachricht")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
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
        .toast(item: $toast)
    }

    private var personDetailsCard: some View {
        HStack(spacing: 16) {
            PersonAvatar(person: person, size: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(person.displayName)
                    .font(.headline)
                    .foregroundColor(AppColor.textPrimary)

                Text(person.relation)
                    .font(.subheadline)
                    .foregroundColor(AppColor.textSecondary)

                Text(birthdayInfo)
                    .font(.caption)
                    .foregroundColor(AppColor.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Image(systemName: "cake.fill")
                    .font(.title3)
                    .foregroundColor(.orange)

                Text(ageString)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppColor.textTertiary)
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
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.locale = .current
            return formatter.string(from: person.birthday)
        }
    }

    private var ageString: String {
        let age = BirthdayDateHelper.age(from: person.birthday, asOf: Date())
        if BirthdayDateHelper.isMilestoneAge(age: age) {
            return "\(age). 🎯"
        }
        return "\(age)."
    }

    private var loadingState: some View {
        Section {
            VStack(spacing: 16) {
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
                        .rotationEffect(.degrees(isLoading ? 360 : 0))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isLoading)
                }

                VStack(spacing: 4) {
                    Text("KI schreibt...")
                        .font(.headline)
                        .foregroundColor(AppColor.textPrimary)

                    Text("Einen Moment bitte...")
                        .font(.caption)
                        .foregroundColor(AppColor.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
        }
    }

    private func errorState(_ error: String) -> some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)

                Text("Fehler")
                    .font(.headline)
                    .foregroundColor(AppColor.textPrimary)

                Text(error)
                    .font(.subheadline)
                    .foregroundColor(AppColor.textSecondary)
                    .multilineTextAlignment(.center)

                Button("Erneut versuchen") {
                    generateMessage()
                }
                .buttonStyle(.borderedProminent)
                .buttonStyle(.pressable)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
        }
    }

    private func messageContentView(message: BirthdayMessage) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                // Greeting
                Text(message.greeting)
                    .font(.headline)
                    .foregroundColor(AppColor.textPrimary)

                // Body
                Text(message.body)
                    .font(.body)
                    .foregroundColor(AppColor.textSecondary)
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
                                .foregroundColor(AppColor.primary)
                            Text("In Zwischenablage kopieren")
                                .font(.subheadline)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("In Zwischenablage kopieren")
                    .accessibilityHint("Kopiert die gesamte Nachricht in die Zwischenablage")

                    // Share Button
                    Button(action: {
                        shareMessage(message)
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(AppColor.primary)
                            Text("Teilen")
                                .font(.subheadline)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Teilen")
                    .accessibilityHint("Teilt die Nachricht über das Share Sheet")

                    // Regenerate Button
                    Button(action: {
                        generateMessage()
                        HapticFeedback.medium()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.orange)
                            Text("Neue Nachricht generieren")
                                .font(.subheadline)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Neue Nachricht generieren")
                    .accessibilityHint("Generiert eine alternative Geburtstagsnachricht")
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Nachricht")
        } footer: {
            Text("💡 Die Nachricht wurde basierend auf Alter, Meilenstein und Sternzeichen personalisiert.")
                .font(.caption)
                .foregroundColor(AppColor.textSecondary)
        }
    }

    private var generateSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles.text.viewfinder")
                        .font(.title3)
                        .foregroundColor(.orange)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Persönliche Geburtstagsnachricht")
                            .font(.headline)
                            .foregroundColor(AppColor.textPrimary)

                        Text("Die KI erstellt eine herzliche Nachricht basierend auf Alter, Meilenstein und Sternzeichen.")
                            .font(.subheadline)
                            .foregroundColor(AppColor.textSecondary)
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
                .buttonStyle(.pressable)
            }
            .padding(.vertical, 4)
        } footer: {
            Text("💡 Tipp: Du kannst die Nachricht nach dem Generieren anpassen oder kopieren.")
                .font(.caption)
                .foregroundColor(AppColor.textSecondary)
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

        let p = person
        let name = senderName.isEmpty ? nil : senderName
        Task { @MainActor in
            do {
                let message = try await AIService.shared.generateBirthdayMessage(for: p, senderName: name)
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
