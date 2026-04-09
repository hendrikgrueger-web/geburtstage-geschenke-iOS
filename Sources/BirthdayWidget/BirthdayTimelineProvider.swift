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
        var calendar = Calendar.current
        calendar.timeZone = .current
        let today = calendar.startOfDay(for: Date())

        // 30-Tage-Fenster: Widget bleibt korrekt auch ohne App-Öffnung über Wochen.
        // daysUntil wird pro Timeline-Position dynamisch aus nextBirthdayDate berechnet —
        // kein veralteter Integer-Snapshot mehr.
        var timelineEntries: [BirthdayTimelineEntry] = []

        for dayOffset in 0..<30 {
            guard let entryDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else {
                continue
            }

            let adjustedBirthdays = entries.compactMap { birthday -> WidgetBirthdayEntry? in
                let days = calendar.dateComponents([.day], from: entryDate, to: birthday.nextBirthdayDate).day ?? -1
                guard days >= 0 else { return nil }
                return birthday
            }
            .sorted { lhs, rhs in
                let lhsDays = calendar.dateComponents([.day], from: entryDate, to: lhs.nextBirthdayDate).day ?? 0
                let rhsDays = calendar.dateComponents([.day], from: entryDate, to: rhs.nextBirthdayDate).day ?? 0
                return lhsDays < rhsDays
            }

            timelineEntries.append(BirthdayTimelineEntry(date: entryDate, birthdays: adjustedBirthdays))
        }

        // Refresh nach 30 Tagen — bis dahin liefert die Timeline immer korrekte Werte
        let refreshDate = calendar.date(byAdding: .day, value: 30, to: today) ?? today
        let timeline = Timeline(entries: timelineEntries, policy: .after(refreshDate))
        completion(timeline)
    }

    // Sample-Daten für Preview und Placeholder — relative Dates für immer korrekte Vorschauen
    static let sampleData: [WidgetBirthdayEntry] = {
        let calendar = Calendar.current
        let now = Date()
        func date(inDays days: Int) -> Date {
            calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: now)) ?? now
        }
        return [
            WidgetBirthdayEntry(id: UUID(), displayName: "Anna Müller", nextBirthdayDate: date(inDays: 3), nextAge: 30, relation: "Freund/in", giftStatus: "purchased", skipGift: false),
            WidgetBirthdayEntry(id: UUID(), displayName: "Max Schmidt", nextBirthdayDate: date(inDays: 12), nextAge: 45, relation: "Kollege/in", giftStatus: "ideas:2", skipGift: false),
            WidgetBirthdayEntry(id: UUID(), displayName: "Lisa Weber", nextBirthdayDate: date(inDays: 28), nextAge: 25, relation: "Schwester", giftStatus: "none", skipGift: false),
            WidgetBirthdayEntry(id: UUID(), displayName: "Tom Fischer", nextBirthdayDate: date(inDays: 35), nextAge: 52, relation: "Vater", giftStatus: "planned", skipGift: false),
            WidgetBirthdayEntry(id: UUID(), displayName: "Sarah Koch", nextBirthdayDate: date(inDays: 42), nextAge: 33, relation: "Freund/in", giftStatus: "none", skipGift: false),
            WidgetBirthdayEntry(id: UUID(), displayName: "Jan Bauer", nextBirthdayDate: date(inDays: 51), nextAge: 28, relation: "Bruder", giftStatus: "ideas:1", skipGift: false),
        ]
    }()
}
