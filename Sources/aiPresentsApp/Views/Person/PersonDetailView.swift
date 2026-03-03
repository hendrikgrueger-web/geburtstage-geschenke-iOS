import SwiftUI
import SwiftData

struct PersonDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let person: PersonRef

    @Query private var giftIdeas: [GiftIdea]
    @Query private var giftHistory: [GiftHistory]

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
    @State private var editedRelation: String = ""
    @State private var showingMarkAllAsGivenConfirmation = false
    @State private var toast: ToastItem?
    @State private var showingEditPerson = false
    @State private var editedName: String = ""
    @State private var editedBirthday: Date = Date()
    @State private var editedPersonRelation: String = ""

    enum GiftSortOption: String, CaseIterable {
        case status = "Status"
        case budget = "Budget"
        case title = "Titel"
        case date = "Datum"
    }

    enum GiftStatusFilter: String, CaseIterable {
        case all = "Alle"
        case idea = "Ideen"
        case planned = "Geplant"
        case purchased = "Gekauft"
        case given = "Verschenkt"
    }

    var body: some View {
        List {
            // Person Info
            Section {
                avatarRow

                HStack {
                    Text("Name")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(person.displayName)
                        .fontWeight(.medium)
                }

                HStack {
                    Text("Geburtstag")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(birthdayString)
                        .fontWeight(.medium)
                }

                HStack {
                    Text("Nächster Geburtstag")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(nextBirthdayInfo)
                        .fontWeight(.medium)
                        .foregroundColor(daysUntilBirthday <= 7 ? .orange : .primary)
                }

                HStack {
                    Text("Beziehung")
                        .foregroundColor(.secondary)
                    Spacer()
                    Button {
                        editedRelation = person.relation
                        showingEditRelation = true
                        HapticFeedback.light()
                    } label: {
                        HStack {
                            Text(person.relation)
                                .fontWeight(.medium)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
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
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Informationen zu \(person.displayName)")

            if !person.skipGift {
            // Gift Ideas
            Section {
                GiftSummaryView(person: person)

                if filteredGiftIdeas.isEmpty {
                    EmptyStateView(type: .noGiftIdeas, action: {
                        showingAddGiftIdea = true
                        HapticFeedback.light()
                    })
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                } else {
                    ForEach(filteredGiftIdeas) { idea in
                        Button {
                            showingEditGiftIdea = idea
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
                                advanceStatus(for: idea)
                            } label: {
                                Label("Vor", systemImage: "arrow.right.circle.fill")
                            }
                            .tint(AppColor.primary)
                            .accessibilityLabel("Status ändern")
                            .accessibilityHint("Ändert den Status der Geschenkidee zum nächsten Schritt")
                        }
                        .contextMenu {
                            Button {
                                shareText = idea.exportAsText()
                                showingShareSheet = true
                                HapticFeedback.light()
                            } label: {
                                Label("Teilen", systemImage: "square.and.arrow.up")
                            }
                            .accessibilityLabel("Geschenkidee teilen")

                            Button {
                                duplicateGiftIdea(idea)
                            } label: {
                                Label("Duplizieren", systemImage: "doc.on.doc")
                            }
                            .accessibilityLabel("Geschenkidee duplizieren")

                            Button {
                                advanceStatus(for: idea)
                            } label: {
                                Label("Status vorwärts", systemImage: "arrow.right.circle.fill")
                            }
                            .accessibilityLabel("Status ändern")

                            Button(role: .destructive) {
                                if let index = filteredGiftIdeas.firstIndex(where: { $0.id == idea.id }) {
                                    deleteGiftIdeas(at: IndexSet([index]))
                                }
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                            .accessibilityLabel("Geschenkidee löschen")
                        }
                    }
                    .onDelete(perform: deleteGiftIdeas)
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
                                    Label(filter.rawValue, systemImage: "checkmark")
                                } else {
                                    Text(filter.rawValue)
                                }
                            }
                        }
                    } label: {
                        controlPill(
                            icon: "line.3.horizontal.decrease",
                            label: giftStatusFilter == .all ? "Filter" : giftStatusFilter.rawValue,
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
                                    Label(option.rawValue, systemImage: "checkmark")
                                } else {
                                    Text(option.rawValue)
                                }
                            }
                        }
                    } label: {
                        controlPill(
                            icon: "arrow.up.arrow.down",
                            label: giftSortOption == .status ? "Sortierung" : giftSortOption.rawValue,
                            isActive: giftSortOption != .status
                        )
                    }

                    Button(action: {
                        showingAddGiftIdea = true
                        HapticFeedback.medium()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(AppColor.primary)
                    }
                }
            } footer: {
                if !filteredGiftIdeas.isEmpty && hasPurchasedGifts {
                    Button(action: { showingMarkAllAsGivenConfirmation = true }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppColor.success)
                            Text("Alle als verschenkt markieren")
                                .font(.subheadline)
                        }
                    }
                }
            }

            // Apple Intelligence
            appleIntelligenceSection
            } // end if !person.skipGift

            // Gift History
            Section {
                if filteredGiftHistory.isEmpty {
                    EmptyStateView(type: .noHistory, action: {
                        showingAddGiftHistory = true
                        HapticFeedback.light()
                    })
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                } else {
                    ForEach(filteredGiftHistory) { history in
                        Button {
                            showingEditGiftHistory = history
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
                                if let index = filteredGiftHistory.firstIndex(where: { $0.id == history.id }) {
                                    deleteGiftHistory(at: IndexSet([index]))
                                }
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Geschenke-Verlauf")
                    Spacer()
                    Button(action: { showingAddGiftHistory = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            } footer: {
                Text("In früheren Jahren verschenkt")
            }

            // Danger Zone
            Section {
                Button(role: .destructive) {
                    showingDeletePerson = true
                } label: {
                    HStack {
                        Text("Kontakt löschen")
                        Spacer()
                        Image(systemName: "trash")
                    }
                }
                .accessibleButton(label: "Kontakt löschen", hint: "Löscht \(person.displayName) und alle Geschenkideen permanent")
            }
        }
        .sheet(isPresented: $showingAddGiftIdea) {
            AddGiftIdeaSheet(person: person)
        }
        .sheet(item: $showingEditGiftIdea) { idea in
            EditGiftIdeaSheet(person: person, idea: idea)
        }
        .sheet(isPresented: $showingAddGiftHistory) {
            AddGiftHistorySheet(person: person)
        }
        .sheet(item: $showingEditGiftHistory) { history in
            EditGiftHistorySheet(person: person, history: history)
        }
        .sheet(isPresented: $showingAISuggestions) {
            AIGiftSuggestionsSheet(person: person)
        }
        .sheet(isPresented: $showingBirthdayMessage) {
            AIBirthdayMessageSheet(person: person)
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
        .alert("Kontakt löschen?", isPresented: $showingDeletePerson) {
            Button("Abbrechen", role: .cancel) { }
            Button("Löschen", role: .destructive) {
                deletePerson()
            }
        } message: {
            Text("Das löscht \(person.displayName) und alle zugehörigen Geschenkideen.")
        }
        .navigationTitle(person.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Bearbeiten") {
                    editedName = person.displayName
                    editedBirthday = person.birthday
                    editedPersonRelation = person.relation
                    showingEditPerson = true
                    HapticFeedback.light()
                }
                .accessibilityLabel("Bearbeiten")
                .accessibilityHint("Öffnet das Formular zum Bearbeiten von Name, Geburtstag und Beziehung")
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        shareText = person.exportAllGiftIdeasAsText()
                        showingShareSheet = true
                        HapticFeedback.light()
                    } label: {
                        Label("Teilen", systemImage: "square.and.arrow.up")
                    }
                    .accessibleButton(label: "Teilen", hint: "Teilt alle Geschenkideen")

                    Button {
                        exportAsCSV()
                    } label: {
                        Label("Als CSV exportieren", systemImage: "doc.text")
                    }
                    .accessibleButton(label: "CSV exportieren", hint: "Exportiert Geschenkideen als CSV-Datei")

                    Divider()

                    Button {
                        showingAddGiftIdea = true
                    } label: {
                        Label("Neue Idee", systemImage: "plus")
                    }
                    .accessibleButton(label: "Neue Idee", hint: "Fügt eine neue Geschenkidee hinzu")
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Optionen")
                .accessibilityHint("Doppeltippen für weitere Optionen")
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if !shareText.isEmpty {
                ShareSheetView(items: [shareText])
            }
        }
        .sheet(isPresented: $showingEditRelation) {
            NavigationStack {
                Form {
                    Section {
                        TextField("Beziehung", text: $editedRelation)
                            .textInputAutocapitalization(.sentences)
                    } footer: {
                        Text("z.B. Familie, Freunde, Kollegen")
                    }
                }
                .navigationTitle("Beziehung bearbeiten")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Abbrechen") {
                            showingEditRelation = false
                        }
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Speichern") {
                            person.relation = editedRelation
                            HapticFeedback.success()
                            showingEditRelation = false
                        }
                        .disabled(editedRelation.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
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
                        .environment(\.locale, Locale(identifier: "de_DE"))
                    }

                    Section("Beziehung") {
                        TextField("z.B. Familie, Freunde, Kollegen", text: $editedPersonRelation)
                            .textInputAutocapitalization(.sentences)
                    }
                }
                .navigationTitle("Kontakt bearbeiten")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Abbrechen") {
                            showingEditPerson = false
                        }
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Speichern") {
                            let trimmedName = editedName.trimmingCharacters(in: .whitespaces)
                            if !trimmedName.isEmpty {
                                person.displayName = trimmedName
                            }
                            person.birthday = editedBirthday
                            let trimmedRelation = editedPersonRelation.trimmingCharacters(in: .whitespaces)
                            if !trimmedRelation.isEmpty {
                                person.relation = trimmedRelation
                            }
                            HapticFeedback.success()
                            showingEditPerson = false
                        }
                        .disabled(editedName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
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

    private var appleIntelligenceSection: some View {
        Section {
            Button(action: {
                handleAIButtonTap(.suggestions)
            }) {
                aiActionRow(
                    icon: "sparkles",
                    color: .orange,
                    title: "Geschenkideen vorschlagen",
                    subtitle: "5 personalisierte Vorschläge"
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Geschenkideen vorschlagen")
            .accessibilityHint("Generiert 5 personalisierte Geschenkideen mit KI-Assistent")

            Button(action: {
                handleAIButtonTap(.birthdayMessage)
            }) {
                aiActionRow(
                    icon: "text.quote",
                    color: .blue,
                    title: "Geburtstagsnachricht erstellen",
                    subtitle: "Herzlicher Text zum Geburtstag"
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Geburtstagsnachricht erstellen")
            .accessibilityHint("Erstellt eine personalisierte Geburtstagsnachricht mit KI-Assistent")
        } header: {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("KI-Assistent")
            }
        } footer: {
            HStack(alignment: .top, spacing: 4) {
                Image(systemName: "lock.shield.fill")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 1)
                Text(aiFooterText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var aiFooterText: String {
        if !AIService.isAPIKeyConfigured {
            return "Demo-Modus — kein API-Key konfiguriert"
        } else if AIConsentManager.shared.consentGiven && AIConsentManager.shared.aiEnabled {
            return "Einwilligung erteilt · Cloud-Verarbeitung via OpenRouter"
        } else if AIConsentManager.shared.consentGiven && !AIConsentManager.shared.aiEnabled {
            return "KI deaktiviert · Einstellungen → KI-Assistent"
        } else {
            return "Einwilligung erforderlich · Tippe für Details"
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
                toast = ToastItem.warning("KI deaktiviert", message: "KI-Assistent ist in den Einstellungen deaktiviert.")
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

        var ideas = giftIdeas.filter { $0.personId == person.id }

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

    private var filteredGiftHistory: [GiftHistory] {
        giftHistory
            .filter { $0.personId == person.id }
            .sorted { $0.year > $1.year }
    }

    private var hasPurchasedGifts: Bool {
        filteredGiftIdeas.contains { $0.status == .purchased }
    }

    private var birthdayString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: person.birthday)
    }

    private var daysUntilBirthday: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return BirthdayCalculator.daysUntilBirthday(for: person.birthday, from: today) ?? 0
    }

    private var nextBirthdayInfo: String {
        if daysUntilBirthday == 0 {
            return "🎉 Heute!"
        } else if daysUntilBirthday == 1 {
            return "Morgen"
        } else if daysUntilBirthday == 365 {
            return "Nächstes Jahr"
        } else if daysUntilBirthday < 7 {
            return "In \(daysUntilBirthday) Tagen"
        } else {
            return "\(daysUntilBirthday) Tage"
        }
    }

    private func deleteGiftIdeas(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredGiftIdeas[index])
            }
            HapticFeedback.warning()
        }
    }

    private func deleteGiftHistory(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredGiftHistory[index])
            }
            HapticFeedback.warning()
        }
    }

    private func copyToGiftIdea(_ history: GiftHistory) {
        let newIdea = GiftIdea(
            personId: person.id,
            title: history.title,
            note: history.note.isEmpty ? "Kopiert aus Geschenk-Verlauf (\(history.year))" : history.note,
            budgetMin: history.budget * 0.8,
            budgetMax: history.budget * 1.2,
            link: history.link,
            status: .idea,
            tags: [history.category]
        )
        modelContext.insert(newIdea)
        HapticFeedback.success()
    }

    private func deletePerson() {
        withAnimation {
            modelContext.delete(person)
            HapticFeedback.error()
        }
        dismiss()
    }

    private func advanceStatus(for idea: GiftIdea) {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        let dateString = formatter.string(from: Date())
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
        }
        HapticFeedback.medium()
    }

    private func markAllAsGiven() {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        let dateString = formatter.string(from: Date())

        let purchasedGifts = filteredGiftIdeas.filter { $0.status == .purchased }
        for gift in purchasedGifts {
            gift.status = .given
            gift.statusLog.append("\(dateString) - Gekauft \u{2192} Verschenkt (Alle markiert)")
        }
        HapticFeedback.success()
    }

    private func duplicateGiftIdea(_ idea: GiftIdea) {
        // Check if duplicate already exists
        let existingTitles = giftIdeas
            .filter { $0.personId == person.id }
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
        HapticFeedback.success()
    }

    private func statusDisplayName(_ status: GiftStatus) -> String {
        switch status {
        case .idea: return "Idee"
        case .planned: return "Geplant"
        case .purchased: return "Gekauft"
        case .given: return "Verschenkt"
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
        toast = ToastItem.info("Teilen", message: "Teilen-Dialog geöffnet")
    }

    private func exportAsCSV() {
        let csvContent = person.exportGiftIdeasAsCSV()

        if !csvContent.isEmpty {
            let fileName = "geschenkideen-\(person.displayName.replacingOccurrences(of: " ", with: "_")).csv"
            if let url = saveCSVToDocuments(content: csvContent, fileName: fileName) {
                shareCSV(url: url)
                toast = ToastItem.success("Export erfolgreich", message: "CSV-Datei wurde erstellt")
            } else {
                toast = ToastItem.error("Export fehlgeschlagen", message: "Datei konnte nicht gespeichert werden")
                HapticFeedback.error()
            }
        } else {
            toast = ToastItem.warning("Keine Daten", message: "Keine Geschenkideen zum Exportieren vorhanden")
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

    private func shareCSV(url: URL) {
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }

        HapticFeedback.success()
    }
}
