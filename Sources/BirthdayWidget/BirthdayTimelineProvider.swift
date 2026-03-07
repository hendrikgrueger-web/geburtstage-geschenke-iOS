import WidgetKit

struct BirthdayTimelineEntry: TimelineEntry {
    let date: Date
    let birthdays: [WidgetBirthdayEntry]
}

struct BirthdayTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> BirthdayTimelineEntry {
        BirthdayTimelineEntry(date: Date(), birthdays: Self.sampleData)
    }

    func getSnapshot(in context: Context, completion: @escaping (BirthdayTimelineEntry) -> Void) {
        if context.isPreview {
            completion(BirthdayTimelineEntry(date: Date(), birthdays: Self.sampleData))
        } else {
            let entries = WidgetDataReader.readEntries()
            completion(BirthdayTimelineEntry(date: Date(), birthdays: entries))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BirthdayTimelineEntry>) -> Void) {
        let entries = WidgetDataReader.readEntries()
        let calendar = Calendar.current

        // Erstelle Einträge für die nächsten 7 Tage (Countdown aktualisiert sich täglich)
        var timelineEntries: [BirthdayTimelineEntry] = []

        for dayOffset in 0..<7 {
            guard let entryDate = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: Date())) else {
                continue
            }

            // Passe daysUntil für zukünftige Tage an und filtere vergangene Geburtstage
            let adjustedBirthdays = entries.compactMap { birthday -> WidgetBirthdayEntry? in
                let adjusted = birthday.daysUntil - dayOffset
                guard adjusted >= 0 else { return nil }
                return WidgetBirthdayEntry(
                    id: birthday.id,
                    displayName: birthday.displayName,
                    daysUntil: adjusted,
                    nextAge: birthday.nextAge,
                    relation: birthday.relation,
                    giftStatus: birthday.giftStatus,
                    skipGift: birthday.skipGift
                )
            }
            .sorted { $0.daysUntil < $1.daysUntil }

            timelineEntries.append(BirthdayTimelineEntry(date: entryDate, birthdays: adjustedBirthdays))
        }

        // Nächste Mitternacht als Refresh-Zeitpunkt
        let nextMidnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        let timeline = Timeline(entries: timelineEntries, policy: .after(nextMidnight))
        completion(timeline)
    }

    // Sample-Daten für Preview und Placeholder
    static let sampleData: [WidgetBirthdayEntry] = [
        WidgetBirthdayEntry(id: UUID(), displayName: "Anna Müller", daysUntil: 3, nextAge: 30, relation: "Freund/in", giftStatus: "purchased", skipGift: false),
        WidgetBirthdayEntry(id: UUID(), displayName: "Max Schmidt", daysUntil: 12, nextAge: 45, relation: "Kollege/in", giftStatus: "ideas:2", skipGift: false),
        WidgetBirthdayEntry(id: UUID(), displayName: "Lisa Weber", daysUntil: 28, nextAge: 25, relation: "Schwester", giftStatus: "none", skipGift: false),
        WidgetBirthdayEntry(id: UUID(), displayName: "Tom Fischer", daysUntil: 35, nextAge: 52, relation: "Vater", giftStatus: "planned", skipGift: false),
        WidgetBirthdayEntry(id: UUID(), displayName: "Sarah Koch", daysUntil: 42, nextAge: 33, relation: "Freund/in", giftStatus: "none", skipGift: false),
        WidgetBirthdayEntry(id: UUID(), displayName: "Jan Bauer", daysUntil: 51, nextAge: 28, relation: "Bruder", giftStatus: "ideas:1", skipGift: false),
    ]
}
