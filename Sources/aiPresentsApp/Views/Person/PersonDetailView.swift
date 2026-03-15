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

    @State private var showingAddGiftIdea = false
    @State private var showingEditGiftIdea: GiftIdea?
    @State private var showingAddGiftHistory = false
    @State private var showingEditGiftHistory: GiftHistory?
    @State private var showingDeletePerson = false
    @State private var showingAISuggestions = false
    @State private var showingBirthdayMessage = false
    @State private var showingAIConsent = false
    @State private var pendingAIAction: AIAction? = nil
    @State private var giftSortOption: GiftSortOption = .status

    enum AIAction { case suggestions, birthdayMessage }
    @State private var giftStatusFilter: GiftStatusFilter = .all
    @State private var showingShareSheet = false
    @State private var shareText: String = ""
    @State private var showingEditRelation = false
    @State private var showingMarkAllAsGivenConfirmation = false
    @State private var toast: ToastItem?
    @State private var showingAddReceivedGift = false
    @State private var showingEditPerson = false
    @State private var showingPaywall = false
    @State private var editedName: String = ""
    @State private var editedBirthday: Date = Date()
    @State private var editedPersonRelation: String = ""

    enum GiftSortOption: String, CaseIterable {
        case status, budget, title, date

        var displayName: String {
            switch self {
            case .status: return String(localized: "Status")
            case .budget: return String(localized: "Budget")
            case .title: return String(localized: "Titel")
            case .date: return String(localized: "Datum")
            }
        }
    }

    enum GiftStatusFilter: String, CaseIterable {
        case all, idea, planned, purchased, given

        var displayName: String {
            switch self {
            case .all: return String(localized: "Alle")
            case .idea: return String(localized: "Ideen")
            case .planned: return String(localized: "Geplant")
            case .purchased: return String(localized: "Gekauft")
            case .given: return String(localized: "Verschenkt")
            }
        }
    }

    var body: some View {
        List {
            // Person Info
            Section {
                avatarRow

                HStack {
                    Text("Name")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(person.displayName)
                        .fontWeight(.medium)
                }

                HStack {
                    Text("Geburtstag")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(birthdayString)
                        .fontWeight(.medium)
                }

                HStack {
                    Text("Nächster Geburtstag")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(nextBirthdayInfo)
                        .fontWeight(.medium)
                        .foregroundStyle(daysUntilBirthday <= 7 ? AppColor.accent : Color.primary)
                }

                HStack {
                    Text("Beziehung")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        if subscriptionManager.hasFullAccess {
                            showingEditRelation = true
                            HapticFeedback.light()
                        } else {
                            showingPaywall = true
                        }
                    } label: {
                        HStack {
                            Text(person.relation)
                                .fontWeight(.medium)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }

                Toggle("Kein Geschenk nötig", isOn: Binding(
                    get: { person.skipGift },
                    set: { newValue in
                        person.skipGift = newValue
                        HapticFeedback.selectionChanged()
                    }
                ))
                .disabled(!subscriptionManager.hasFullAccess)
            }

            // MARK: - Hobbies & Interessen (fließen in KI-Prompt ein)
            Section {
                HobbiesChipView(
                    hobbies: Binding(
                        get: { person.hobbies },
                        set: { person.hobbies = $0 }
                    ),
                    isEditable: true
                )
            } header: {
                Text("Hobbies & Interessen")
            } footer: {
                Text("Wird für bessere KI-Vorschläge genutzt")
            }

            if !person.skipGift {
            // Gift Ideas
            Section {
                GiftSummaryView(person: person)

                if filteredGiftIdeas.isEmpty {
                    Button {
                        if subscriptionManager.hasFullAccess {
                            showingAddGiftIdea = true
                            HapticFeedback.light()
                        } else {
                            showingPaywall = true
                        }
                    } label: {
                        VStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(AppColor.primary)
                            Text("Geschenkidee hinzufügen")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .accessibilityLabel(String(localized: "Geschenkidee hinzufügen"))
                    .accessibilityHint(String(localized: "Fügt eine neue Geschenkidee hinzu"))
                } else {
                    ForEach(filteredGiftIdeas) { idea in
                        Button {
                            if subscriptionManager.hasFullAccess {
                                showingEditGiftIdea = idea
                            } else {
                                showingPaywall = true
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                GiftIdeaRow(idea: idea)
                                if !idea.statusLog.isEmpty {
                                    VStack(alignment: .leading, spacing: 2) {
                                        ForEach(idea.statusLog, id: \.self) { entry in
                                            Text(entry)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.leading, 4)
                                }
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                if subscriptionManager.hasFullAccess {
                                    advanceStatus(for: idea)
                                } else {
                                    showingPaywall = true
                                }
                            } label: {
                                Label("Vor", systemImage: "arrow.right.circle.fill")
                            }
                            .tint(AppColor.primary)
                            .accessibilityLabel(String(localized: "Status ändern"))
                            .accessibilityHint(String(localized: "Ändert den Status der Geschenkidee zum nächsten Schritt"))
                        }
                        .contextMenu {
                            Button {
                                shareText = idea.exportAsText()
                                showingShareSheet = true
                                HapticFeedback.light()
                            } label: {
                                Label("Teilen", systemImage: "square.and.arrow.up")
                            }
                            .accessibilityLabel(String(localized: "Geschenkidee teilen"))

                            Button {
                                duplicateGiftIdea(idea)
                            } label: {
                                Label("Duplizieren", systemImage: "doc.on.doc")
                            }
                            .accessibilityLabel(String(localized: "Geschenkidee duplizieren"))

                            Button {
                                if subscriptionManager.hasFullAccess {
                                    advanceStatus(for: idea)
                                } else {
                                    showingPaywall = true
                                }
                            } label: {
                                Label("Status vorwärts", systemImage: "arrow.right.circle.fill")
                            }
                            .accessibilityLabel(String(localized: "Status ändern"))

                            Button(role: .destructive) {
                                if let index = filteredGiftIdeas.firstIndex(where: { $0.id == idea.id }) {
                                    deleteGiftIdeas(at: IndexSet([index]))
                                }
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                            .accessibilityLabel(String(localized: "Geschenkidee löschen"))
                        }
                    }
                    .onDelete(perform: deleteGiftIdeas)

                    Button {
                        if subscriptionManager.hasFullAccess {
                            showingAddGiftIdea = true
                            HapticFeedback.medium()
                        } else {
                            showingPaywall = true
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(AppColor.primary)
                            Text("Idee hinzufügen")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .accessibilityLabel(String(localized: "Idee hinzufügen"))
                    .accessibilityHint(String(localized: "Fügt eine neue Geschenkidee hinzu"))
                }
            } header: {
                HStack(spacing: 6) {
                    Text("Geschenkideen")

                    Spacer()

                    // Status-Filter
                    Menu {
                        ForEach(GiftStatusFilter.allCases, id: \.self) { filter in
                            Button {
                                giftStatusFilter = filter
                                HapticFeedback.selectionChanged()
                            } label: {
                                if giftStatusFilter == filter {
                                    Label(filter.displayName, systemImage: "checkmark")
                                } else {
                                    Text(filter.displayName)
                                }
                            }
                        }
                    } label: {
                        controlPill(
                            icon: "line.3.horizontal.decrease",
                            label: giftStatusFilter == .all ? String(localized: "Filter") : giftStatusFilter.displayName,
                            isActive: giftStatusFilter != .all
                        )
                    }

                    // Sortierung
                    Menu {
                        ForEach(GiftSortOption.allCases, id: \.self) { option in
                            Button {
                                giftSortOption = option
                                HapticFeedback.selectionChanged()
                            } label: {
                                if giftSortOption == option {
                                    Label(option.displayName, systemImage: "checkmark")
                                } else {
                                    Text(option.displayName)
                                }
                            }
                        }
                    } label: {
                        controlPill(
                            icon: "arrow.up.arrow.down",
                            label: giftSortOption == .status ? String(localized: "Sortierung") : giftSortOption.displayName,
                            isActive: giftSortOption != .status
                        )
                    }

                }
            } footer: {
                if !filteredGiftIdeas.isEmpty && hasPurchasedGifts {
                    Button(action: { showingMarkAllAsGivenConfirmation = true }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppColor.success)
                            Text("Alle als verschenkt markieren")
                                .font(.subheadline)
                        }
                    }
                }
            }

            // KI-Assistent
            aiAssistantSection
            } // end if !person.skipGift

            // Gift History
            Section {
                if givenGiftHistory.isEmpty {
                    EmptyStateView(type: .noHistory, action: {
                        if subscriptionManager.hasFullAccess {
                            showingAddGiftHistory = true
                            HapticFeedback.light()
                        } else {
                            showingPaywall = true
                        }
                    })
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                } else {
                    ForEach(givenGiftHistory) { history in
                        Button {
                            if subscriptionManager.hasFullAccess {
                                showingEditGiftHistory = history
                            } else {
                                showingPaywall = true
                            }
                        } label: {
                            GiftHistoryRow(
                                history: history,
                                onShare: { shareGiftHistory(history) },
                                onReuseAsIdea: { copyToGiftIdea(history) }
                            )
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                copyToGiftIdea(history)
                            } label: {
                                Label("Als Idee", systemImage: "lightbulb.circle.fill")
                            }
                            .tint(AppColor.primary)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                if let index = givenGiftHistory.firstIndex(where: { $0.id == history.id }) {
                                    deleteGiftHistory(at: IndexSet([index]))
                                }
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                    }

                    Button {
                        if subscriptionManager.hasFullAccess {
                            showingAddGiftHistory = true
                            HapticFeedback.medium()
                        } else {
                            showingPaywall = true
                        }
                    } label: {
                        Label("Eintrag hinzufügen", systemImage: "plus.circle.fill")
                            .foregroundStyle(AppColor.primary)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .accessibilityLabel(String(localized: "Verschenktes Geschenk hinzufügen"))
                    .accessibilityHint(String(localized: "Fügt ein verschenktes Geschenk hinzu"))
                }
            } header: {
                Text("Verschenkt")
            } footer: {
                Text("In früheren Jahren verschenkt")
            }

            // MARK: - Erhaltene Geschenke (von dieser Person bekommen)
            Section {
                if receivedGiftHistory.isEmpty {
                    Text("Noch keine erhaltenen Geschenke")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(receivedGiftHistory) { history in
                        Button {
                            if subscriptionManager.hasFullAccess {
                                showingEditGiftHistory = history
                            } else {
                                showingPaywall = true
                            }
                        } label: {
                            GiftHistoryRow(
                                history: history,
                                onShare: { shareGiftHistory(history) },
                                onReuseAsIdea: nil
                            )
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                if let index = receivedGiftHistory.firstIndex(where: { $0.id == history.id }) {
                                    deleteReceivedGiftHistory(at: IndexSet([index]))
                                }
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                    }
                }

                Button {
                    if subscriptionManager.hasFullAccess {
                        showingAddReceivedGift = true
                        HapticFeedback.medium()
                    } else {
                        showingPaywall = true
                    }
                } label: {
                    Label("Eintrag hinzufügen", systemImage: "plus.circle.fill")
                        .foregroundStyle(AppColor.primary)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityLabel(String(localized: "Erhaltenes Geschenk hinzufügen"))
                .accessibilityHint(String(localized: "Fügt ein erhaltenes Geschenk hinzu"))
            } header: {
                Text("Von \(person.displayName) erhalten")
            }

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
            let purchasedCount = filteredGiftIdeas.filter { $0.status == .purchased }.count
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
                    if subscriptionManager.hasFullAccess {
                        editedName = person.displayName
                        editedBirthday = person.birthday
                        editedPersonRelation = person.relation
                        showingEditPerson = true
                        HapticFeedback.light()
                    } else {
                        showingPaywall = true
                    }
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
                        if subscriptionManager.hasFullAccess {
                            showingAddGiftIdea = true
                        } else {
                            showingPaywall = true
                        }
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
        // Relation-Picker Sheet — dedizierter Screen mit eigenen Typen + Swipe-to-Delete
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
        // Kontakt-Bearbeitung Sheet — Name, Geburtstag und Beziehung editieren
        .sheet(isPresented: $showingEditPerson) {
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
                            person.birthYearKnown = true  // Manuell eingegebenes Datum hat immer ein Jahr
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
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .toast(item: $toast)
    }

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

        guard subscriptionManager.hasFullAccess else {
            showingPaywall = true
            return
        }

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

    private func controlPill(icon: String, label: String, isActive: Bool) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(label)
                .font(.system(size: 11, weight: isActive ? .semibold : .regular))
        }
        .foregroundStyle(isActive ? AppColor.primary : Color.secondary)
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(
            isActive ? AppColor.primary.opacity(0.12) : Color.secondary.opacity(0.1),
            in: Capsule()
        )
    }

    private var avatarRow: some View {
        HStack {
            PersonAvatar(person: person, size: 60)

            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var filteredGiftIdeas: [GiftIdea] {
        let statusOrder: [GiftStatus] = [.idea, .planned, .purchased, .given]

        var ideas = giftIdeas

        // Apply status filter
        switch giftStatusFilter {
        case .all:
            break // Show all
        case .idea:
            ideas = ideas.filter { $0.status == .idea }
        case .planned:
            ideas = ideas.filter { $0.status == .planned }
        case .purchased:
            ideas = ideas.filter { $0.status == .purchased }
        case .given:
            ideas = ideas.filter { $0.status == .given }
        }

        return ideas.sorted { idea1, idea2 in
            switch giftSortOption {
            case .status:
                let index1 = statusOrder.firstIndex(of: idea1.status) ?? 0
                let index2 = statusOrder.firstIndex(of: idea2.status) ?? 0
                if index1 != index2 {
                    return index1 < index2
                }
                return idea1.title < idea2.title
            case .budget:
                return idea1.budgetMax > idea2.budgetMax
            case .title:
                return idea1.title < idea2.title
            case .date:
                return idea1.createdAt > idea2.createdAt
            }
        }
    }

    /// Geschenke, die wir dieser Person gegeben haben — absteigend nach Jahr sortiert.
    private var givenGiftHistory: [GiftHistory] {
        giftHistory
            .filter { $0.giftDirection == .given }
            .sorted { $0.year > $1.year }
    }

    /// Geschenke, die wir von dieser Person erhalten haben — absteigend nach Jahr sortiert.
    private var receivedGiftHistory: [GiftHistory] {
        giftHistory
            .filter { $0.giftDirection == .received }
            .sorted { $0.year > $1.year }
    }

    private var hasPurchasedGifts: Bool {
        filteredGiftIdeas.contains { $0.status == .purchased }
    }

    private var birthdayString: String {
        FormatterHelper.formatBirthday(person.birthday, birthYearKnown: person.birthYearKnown)
    }

    private var daysUntilBirthday: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return BirthdayCalculator.daysUntilBirthday(for: person.birthday, from: today) ?? 0
    }

    private var nextBirthdayInfo: String {
        if daysUntilBirthday == 0 {
            return "🎉 " + String(localized: "Heute!")
        } else if daysUntilBirthday == 1 {
            return String(localized: "Morgen")
        } else if daysUntilBirthday == 365 {
            return String(localized: "Nächstes Jahr")
        } else if daysUntilBirthday < 7 {
            return String(localized: "In \(daysUntilBirthday) Tagen")
        } else {
            return String(localized: "\(daysUntilBirthday) Tage")
        }
    }

    private func deleteGiftIdeas(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredGiftIdeas[index])
            }
            HapticFeedback.warning()
        }
        triggerWidgetUpdate()
    }

    private func deleteGiftHistory(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(givenGiftHistory[index])
            }
            HapticFeedback.warning()
        }
    }

    private func deleteReceivedGiftHistory(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(receivedGiftHistory[index])
            }
            HapticFeedback.warning()
        }
    }

    private func copyToGiftIdea(_ history: GiftHistory) {
        let newIdea = GiftIdea(
            personId: person.id,
            title: history.title,
            note: history.note.isEmpty ? String(localized: "Kopiert aus Geschenk-Verlauf (\(history.year))") : history.note,
            budgetMin: history.budget * 0.8,
            budgetMax: history.budget * 1.2,
            link: history.link,
            status: .idea,
            tags: [history.category]
        )
        modelContext.insert(newIdea)
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

    private func advanceStatus(for idea: GiftIdea) {
        let dateString = FormatterHelper.shortLogDateFormatter.string(from: Date())
        let oldStatus = idea.status

        switch idea.status {
        case .idea:
            idea.status = .planned
        case .planned:
            idea.status = .purchased
        case .purchased:
            idea.status = .given
        case .given:
            break
        }

        if oldStatus != idea.status {
            idea.statusLog.append("\(dateString) - \(statusDisplayName(oldStatus)) \u{2192} \(statusDisplayName(idea.status))")
            triggerWidgetUpdate()
        }
        HapticFeedback.medium()
    }

    private func markAllAsGiven() {
        let dateString = FormatterHelper.shortLogDateFormatter.string(from: Date())

        let purchasedGifts = filteredGiftIdeas.filter { $0.status == .purchased }
        for gift in purchasedGifts {
            gift.status = .given
            gift.statusLog.append("\(dateString) - \(String(localized: "Gekauft")) \u{2192} \(String(localized: "Verschenkt")) (\(String(localized: "Alle markiert")))")
        }
        triggerWidgetUpdate()
        HapticFeedback.success()
    }

    private func duplicateGiftIdea(_ idea: GiftIdea) {
        // Check if duplicate already exists
        let existingTitles = giftIdeas
            .map { $0.title.lowercased().trimmingCharacters(in: .whitespaces) }

        let titleWithoutCopy = idea.title
            .replacingOccurrences(of: " (Kopie)", with: "")
            .replacingOccurrences(of: " (Copy)", with: "")
            .trimmingCharacters(in: .whitespaces)

        // Generate unique title
        var newTitle = titleWithoutCopy
        var counter = 1
        while existingTitles.contains(newTitle.lowercased()) {
            counter += 1
            newTitle = "\(titleWithoutCopy) (\(counter))"
        }

        let newIdea = GiftIdea(
            personId: person.id,
            title: newTitle,
            note: idea.note,
            budgetMin: idea.budgetMin,
            budgetMax: idea.budgetMax,
            link: idea.link,
            status: .idea,
            tags: idea.tags
        )
        modelContext.insert(newIdea)
        triggerWidgetUpdate()
        HapticFeedback.success()
    }

    private func statusDisplayName(_ status: GiftStatus) -> String {
        switch status {
        case .idea: return String(localized: "Idee")
        case .planned: return String(localized: "Geplant")
        case .purchased: return String(localized: "Gekauft")
        case .given: return String(localized: "Verschenkt")
        }
    }

    private func shareGiftHistory(_ history: GiftHistory) {
        var text = "🎁 \(history.title) (\(history.year))\n"
        text += "📝 \(history.category)\n"

        if history.budget > 0 {
            text += "💰 \(Int(history.budget))€\n"
        }

        if !history.note.isEmpty {
            text += "📝 \(history.note)\n"
        }

        if !history.link.isEmpty {
            text += "🔗 \(history.link)\n"
        }

        shareText = text
        showingShareSheet = true
        toast = ToastItem.info(String(localized: "Teilen"), message: String(localized: "Teilen-Dialog geöffnet"))
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
            // iPad erfordert sourceView/sourceRect für Popover — sonst Crash
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
