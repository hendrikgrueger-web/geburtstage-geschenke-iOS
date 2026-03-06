import WidgetKit
import SwiftUI

struct BirthdayWidget: Widget {
    let kind: String = "BirthdayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BirthdayTimelineProvider()) { entry in
            BirthdayWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Geburtstage")
        .description("Zeigt die nächsten Geburtstage mit Geschenk-Status.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct BirthdayWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: BirthdayTimelineEntry

    var body: some View {
        switch family {
        case .systemLarge:
            BirthdayWidgetLargeView(entry: entry)
        default:
            BirthdayWidgetMediumView(entry: entry)
        }
    }
}

@main
struct BirthdayWidgetBundle: WidgetBundle {
    var body: some Widget {
        BirthdayWidget()
    }
}

// MARK: - Previews

#Preview("Medium", as: .systemMedium) {
    BirthdayWidget()
} timeline: {
    BirthdayTimelineEntry(date: Date(), birthdays: BirthdayTimelineProvider.sampleData)
}

#Preview("Large", as: .systemLarge) {
    BirthdayWidget()
} timeline: {
    BirthdayTimelineEntry(date: Date(), birthdays: BirthdayTimelineProvider.sampleData)
}

#Preview("Empty", as: .systemMedium) {
    BirthdayWidget()
} timeline: {
    BirthdayTimelineEntry(date: Date(), birthdays: [])
}
