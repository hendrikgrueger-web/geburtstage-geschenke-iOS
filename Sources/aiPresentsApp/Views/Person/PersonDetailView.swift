import SwiftUI
import SwiftData

struct PersonDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    let person: PersonRef

    @Query private var giftIdeas: [GiftIdea]
    @Query private var giftHistory: [GiftHistory]

    init(person: PersonRef) {
        self.person = person
        let personId = person.id
        _giftIdeas = Query(filter: #Predicate<GiftIdea> { $0.personId == personId })
        _giftHistory = Query(filter: #Predicate<GiftHistory> { $0.personId == personId })
    }

    // MARK: - Sheet State

    @State private var showingAddGiftIdea = false
    @State private var showingEditGiftIdea: GiftIdea?
    @State private var showingAddGiftHistory = false
    @State private var showingEditGiftHistory: GiftHistory?
    @State private var showingDeletePerson = false
    @State private var showingAISuggestions = false
    @State private var showingBirthdayMessage = false
    @State private var showingAIConsent = false
    @State private var pendingAIAction: AIAction? = nil
    @State private var showingShareSheet = false
    @State private var shareText: String = ""
    @State private var showingEditRelation = false
    @State private var showingMarkAllAsGivenConfirmation = false
    @State private var toast: ToastItem?
    @State private var showingAddReceivedGift = false
    @State private var showingEditPerson = false
    @State private var editedName: String = ""
    @State private var editedBirthday: Date = Date()
    @State private var editedPersonRelation: String = ""

    // MARK: - Gift Ideas State

    @State private var giftSortOption: GiftSortOption = .status
    @State private var giftStatusFilter: GiftStatusFilter = .all

    enum AIAction { case suggestions, birthdayMessage }

    // MARK: - Body

    var body: some View {
        List {
            PersonDetailHeaderSection(
                person: person,
                showingEditRelation: $showingEditRelation
            )

            PersonDetailHobbiesSection(person: person)

            if !person.skipGift {
                PersonDetailGiftIdeasSection(
                    person: person,
                    giftIdeas: giftIdeas,
                    giftSortOption: $giftSortOption,
                    giftStatusFilter: $giftStatusFilter,
                    showingAddGiftIdea: $showingAddGiftIdea,
                    showingEditGiftIdea: $showingEditGiftIdea,
                    showingShareSheet: $showingShareSheet,
                    shareText: $shareText,
                    showingMarkAllAsGivenConfirmation: $showingMarkAllAsGivenConfirmation,
                    toast: $toast
                )

                aiAssistantSection
            }

            PersonDetailGiftHistorySection(
                person: person,
                giftHistory: giftHistory,
                showingAddGiftHistory: $showingAddGiftHistory,
                showingAddReceivedGift: $showingAddReceivedGift,
                showingEditGiftHistory: $showingEditGiftHistory,
                showingShareSheet: $showingShareSheet,
                shareText: $shareText,
                toast: $toast
            )

            // Danger Zone
            Section {
                Button(role: .destructive) {
                    showingDeletePerson = true
                } label: {
                    HStack {
                        Text("Aus App entfernen")
                        Spacer()
                        Image(systemName: "trash")
                    }
                }
                .accessibleButton(label: String(localized: "Aus App entfernen"), hint: String(localized: "Entfernt \(person.displayName) aus der App. Der iOS-Kontakt bleibt unverändert."))
            }
        }
        // MARK: - Sheets
        .sheet(isPresented: $showingAddGiftIdea) {
            AddGiftIdeaSheet(person: person)
                .presentationDetents([.medium, .large])
        }
        .sheet(item: $showingEditGiftIdea) { idea in
            EditGiftIdeaSheet(person: person, idea: idea)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingAddGiftHistory) {
            AddGiftHistorySheet(person: person)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingAddReceivedGift) {
            AddGiftHistorySheet(person: person, direction: .received)
                .presentationDetents([.medium, .large])
        }
        .sheet(item: $showingEditGiftHistory) { history in
            EditGiftHistorySheet(person: person, history: history)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingAISuggestions) {
            AIGiftSuggestionsSheet(person: person)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingBirthdayMessage) {
            AIBirthdayMessageSheet(person: person)
                .presentationDetents([.medium, .large])
        }
        .alert("Alle als verschenkt markieren?", isPresented: $showingMarkAllAsGivenConfirmation) {
            Button("Abbrechen", role: .cancel) { }
            Button("Markieren") {
                markAllAsGiven()
            }
        } message: {
            let purchasedCount = giftIdeas.filter { $0.status == .purchased }.count
            Text("\(purchasedCount) Geschenk\(purchasedCount == 1 ? "" : "e") werden als verschenkt markiert.")
        }
        .alert("Aus App entfernen?", isPresented: $showingDeletePerson) {
            Button("Abbrechen", role: .cancel) { }
            Button("Entfernen", role: .destructive) {
                deletePerson()
            }
        } message: {
            Text("\(person.displayName) wird nur aus dieser App entfernt. Dein iOS-Kontakt bleibt unverändert.")
        }
        .navigationTitle(person.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Bearbeiten") {
                    editedName = person.displayName
                    editedBirthday = person.birthday
                    editedPersonRelation = person.relation
                    showingEditPerson = true
                    HapticFeedback.light()
                }
                .accessibilityLabel(String(localized: "Bearbeiten"))
                .accessibilityHint(String(localized: "Öffnet das Formular zum Bearbeiten von Name, Geburtstag und Beziehung"))
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        shareText = person.exportAllGiftIdeasAsText()
                        showingShareSheet = true
                        HapticFeedback.light()
                    } label: {
                        Label("Teilen", systemImage: "square.and.arrow.up")
                    }
                    .accessibleButton(label: String(localized: "Teilen"), hint: String(localized: "Teilt alle Geschenkideen"))

                    Button {
                        exportAsCSV()
                    } label: {
                        Label("Als CSV exportieren", systemImage: "doc.text")
                    }
                    .accessibleButton(label: String(localized: "CSV exportieren"), hint: String(localized: "Exportiert Geschenkideen als CSV-Datei"))

                    Divider()

                    Button {
                        showingAddGiftIdea = true
                    } label: {
                        Label("Neue Idee", systemImage: "plus")
                    }
                    .accessibleButton(label: String(localized: "Neue Idee"), hint: String(localized: "Fügt eine neue Geschenkidee hinzu"))
                    .keyboardShortcut("i", modifiers: .command)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel(String(localized: "Optionen"))
                .accessibilityHint(String(localized: "Doppeltippen für weitere Optionen"))
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if !shareText.isEmpty {
                ShareSheetView(items: [shareText])
            }
        }
        .sheet(isPresented: $showingEditRelation) {
            NavigationStack {
                RelationPickerView(selectedRelation: Binding(
                    get: { person.relation },
                    set: { newValue in
                        person.relation = newValue
                        HapticFeedback.success()
                        triggerWidgetUpdate()
                        showingEditRelation = false
                    }
                ))
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Abbrechen") {
                            showingEditRelation = false
                        }
                    }
                }
            }
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingEditPerson) {
            editPersonSheet
        }
        .sheet(isPresented: $showingAIConsent) {
            AIConsentSheet(isPresented: $showingAIConsent) {
                if let action = pendingAIAction {
                    switch action {
                    case .suggestions:
                        showingAISuggestions = true
                    case .birthdayMessage:
                        showingBirthdayMessage = true
                    }
                    pendingAIAction = nil
                }
            }
        }
        .toast(item: $toast)
    }

    // MARK: - Edit Person Sheet

    private var editPersonSheet: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Vorname Nachname", text: $editedName)
                        .textInputAutocapitalization(.words)
                }

                Section("Geburtstag") {
                    DatePicker(
                        "Datum",
                        selection: $editedBirthday,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .environment(\.locale, .current)
                }

                Section("Beziehung") {
                    NavigationLink {
                        RelationPickerView(selectedRelation: $editedPersonRelation)
                    } label: {
                        HStack {
                            Text("Beziehung")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(RelationOptions.localizedDisplayName(for: editedPersonRelation))
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Kontakt bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") {
                        showingEditPerson = false
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Speichern") {
                        let trimmedName = editedName.trimmingCharacters(in: .whitespaces)
                        if !trimmedName.isEmpty {
                            person.displayName = trimmedName
                        }
                        person.birthday = editedBirthday
                        person.birthYearKnown = true
                        person.relation = editedPersonRelation
                        HapticFeedback.success()
                        triggerWidgetUpdate()
                        showingEditPerson = false
                    }
                    .disabled(editedName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: - AI Assistant Section

    private var aiAssistantSection: some View {
        Section {
            Button(action: {
                handleAIButtonTap(.suggestions)
            }) {
                aiActionRow(
                    icon: "sparkles",
                    color: AppColor.accent,
                    title: String(localized: "Geschenkideen vorschlagen"),
                    subtitle: String(localized: "5 personalisierte Vorschläge")
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "Geschenkideen vorschlagen"))
            .accessibilityHint(String(localized: "Generiert 5 personalisierte Geschenkideen mit KI-Assistent"))

            Button(action: {
                handleAIButtonTap(.birthdayMessage)
            }) {
                aiActionRow(
                    icon: "text.quote",
                    color: AppColor.primary,
                    title: String(localized: "Geburtstagsnachricht erstellen"),
                    subtitle: String(localized: "Herzlicher Text zum Geburtstag")
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "Geburtstagsnachricht erstellen"))
            .accessibilityHint(String(localized: "Erstellt eine personalisierte Geburtstagsnachricht mit KI-Assistent"))
        } header: {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundStyle(AppColor.secondary)
                Text("KI-Assistent")
            }
        } footer: {
            HStack(alignment: .top, spacing: 4) {
                Image(systemName: "lock.shield.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 1)
                Text(aiFooterText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - AI Helpers

    private var aiFooterText: String {
        if !AIService.isAPIKeyConfigured {
            return String(localized: "API-Key nicht konfiguriert")
        } else if AIConsentManager.shared.consentGiven && AIConsentManager.shared.aiEnabled {
            return String(localized: "Einwilligung erteilt · Cloud-Verarbeitung via OpenRouter")
        } else if AIConsentManager.shared.consentGiven && !AIConsentManager.shared.aiEnabled {
            return String(localized: "KI deaktiviert · Einstellungen → KI-Assistent")
        } else {
            return String(localized: "Einwilligung erforderlich · Tippe für Details")
        }
    }

    private func handleAIButtonTap(_ action: AIAction) {
        HapticFeedback.medium()

        if AIConsentManager.shared.consentGiven {
            if AIConsentManager.shared.aiEnabled {
                switch action {
                case .suggestions:
                    showingAISuggestions = true
                case .birthdayMessage:
                    showingBirthdayMessage = true
                }
            } else {
                toast = ToastItem.warning(String(localized: "KI deaktiviert"), message: String(localized: "KI-Assistent ist in den Einstellungen deaktiviert."))
            }
        } else {
            pendingAIAction = action
            showingAIConsent = true
        }
    }

    private func aiActionRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.gradient)
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(AppColor.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Actions

    private func markAllAsGiven() {
        let dateString = FormatterHelper.shortLogDateFormatter.string(from: Date())

        let purchasedGifts = giftIdeas.filter { $0.status == .purchased }
        for gift in purchasedGifts {
            gift.status = .given
            gift.statusLog.append("\(dateString) - \(String(localized: "Gekauft")) \u{2192} \(String(localized: "Verschenkt")) (\(String(localized: "Alle markiert")))")
        }
        triggerWidgetUpdate()
        HapticFeedback.success()
    }

    private func deletePerson() {
        withAnimation {
            modelContext.delete(person)
            HapticFeedback.warning()
        }
        triggerWidgetUpdate()
        dismiss()
    }

    private func exportAsCSV() {
        let csvContent = person.exportGiftIdeasAsCSV()

        if !csvContent.isEmpty {
            let fileName = "geschenkideen-\(person.displayName.replacingOccurrences(of: " ", with: "_")).csv"
            if let url = saveCSVToDocuments(content: csvContent, fileName: fileName) {
                shareCSV(url: url)
                toast = ToastItem.success(String(localized: "Export erfolgreich"), message: String(localized: "CSV-Datei wurde erstellt"))
            } else {
                toast = ToastItem.error(String(localized: "Export fehlgeschlagen"), message: String(localized: "Datei konnte nicht gespeichert werden"))
                HapticFeedback.error()
            }
        } else {
            toast = ToastItem.warning(String(localized: "Keine Daten"), message: String(localized: "Keine Geschenkideen zum Exportieren vorhanden"))
            HapticFeedback.error()
        }
    }

    private func saveCSVToDocuments(content: String, fileName: String) -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            AppLogger.ui.error("Failed to access Documents directory for CSV export")
            return nil
        }

        let fileURL = documentsDirectory.appendingPathComponent(fileName)

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            AppLogger.ui.debug("CSV saved successfully: \(fileURL.path)")
            return fileURL
        } catch {
            AppLogger.ui.error("Failed to save CSV: \(fileName)", error: error)
            return nil
        }
    }

    private func triggerWidgetUpdate() {
        WidgetDataService.shared.updateWidgetData(from: modelContext)
    }

    private func shareCSV(url: URL) {
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootViewController.view
                popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX, y: rootViewController.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            rootViewController.present(activityVC, animated: true)
        }

        HapticFeedback.success()
    }
}
