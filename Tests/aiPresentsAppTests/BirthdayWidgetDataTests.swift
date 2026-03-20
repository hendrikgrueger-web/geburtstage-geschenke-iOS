import XCTest
import SwiftData
@testable import aiPresentsApp

/// Tests for BirthdayWidgetData utility
/// Verifies widget data preparation for efficient widget timelines
final class BirthdayWidgetDataTests: XCTestCase {

    var modelContext: ModelContext!

    override func setUpWithError() throws {
        throw XCTSkip("SwiftData ModelContainer conflicts with TEST_HOST app container")
        let schema = Schema([PersonRef.self, GiftIdea.self, GiftHistory.self, SuggestionFeedback.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(container)
    }

    override func tearDown() {
        modelContext = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func createPerson(
        name: String,
        relation: String,
        birthday: Date
    ) -> PersonRef {
        let person = PersonRef(contactIdentifier: "",
            displayName: name,
            birthday: birthday,
            relation: relation
        )
        modelContext.insert(person)
        return person
    }

    private func createBirthday(day: Int, month: Int, year: Int) -> Date {
        var components = DateComponents()
        components.day = day
        components.month = month
        components.year = year
        return Calendar.current.date(from: components)!
    }

    // MARK: - Widget Data Fetching Tests

    func testFetchWidgetData_EmptyDatabase() {
        // Arrange & Act
        let summary = BirthdayWidgetData.fetchWidgetData(from: modelContext)

        // Assert
        XCTAssertEqual(summary.todayCount, 0, "Should have no birthdays today")
        XCTAssertEqual(summary.weekCount, 0, "Should have no birthdays this week")
        XCTAssertEqual(summary.monthCount, 0, "Should have no birthdays this month")
        XCTAssertNil(summary.nextBirthday, "Should have no next birthday")
        XCTAssertTrue(summary.upcomingBirthdays.isEmpty, "Should have no upcoming birthdays")
    }

    func testFetchWidgetData_TodayBirthday() {
        // Arrange
        let today = Calendar.current.startOfDay(for: Date())
        let birthday = createBirthday(day: Calendar.current.component(.day, from: today), month: Calendar.current.component(.month, from: today), year: 1990)
        createPerson(name: "Max Müller", relation: "Bruder", birthday: birthday)

        // Act
        let summary = BirthdayWidgetData.fetchWidgetData(from: modelContext)

        // Assert
        XCTAssertEqual(summary.todayCount, 1, "Should have 1 birthday today")
        XCTAssertEqual(summary.weekCount, 1, "Should have 1 birthday this week")
        XCTAssertEqual(summary.monthCount, 1, "Should have 1 birthday this month")
        XCTAssertNotNil(summary.nextBirthday, "Should have a next birthday")
        XCTAssertTrue(summary.nextBirthday?.isToday ?? false, "Next birthday should be today")
    }

    func testFetchWidgetData_TomorrowBirthday() {
        // Arrange
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let components = Calendar.current.dateComponents([.day, .month], from: tomorrow)
        let birthday = createBirthday(day: components.day!, month: components.month!, year: 1990)
        createPerson(name: "Anna Schmidt", relation: "Schwester", birthday: birthday)

        // Act
        let summary = BirthdayWidgetData.fetchWidgetData(from: modelContext)

        // Assert
        XCTAssertEqual(summary.todayCount, 0, "Should have no birthdays today")
        XCTAssertEqual(summary.weekCount, 1, "Should have 1 birthday this week")
        XCTAssertEqual(summary.monthCount, 1, "Should have 1 birthday this month")
        XCTAssertNotNil(summary.nextBirthday, "Should have a next birthday")
        XCTAssertEqual(summary.nextBirthday?.daysUntil, 1, "Next birthday should be in 1 day")
    }

    func testFetchWidgetData_WeekBirthday() {
        // Arrange
        let nextWeek = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
        let components = Calendar.current.dateComponents([.day, .month], from: nextWeek)
        let birthday = createBirthday(day: components.day!, month: components.month!, year: 1990)
        createPerson(name: "Thomas Weber", relation: "Kollege", birthday: birthday)

        // Act
        let summary = BirthdayWidgetData.fetchWidgetData(from: modelContext)

        // Assert
        XCTAssertEqual(summary.todayCount, 0, "Should have no birthdays today")
        XCTAssertEqual(summary.weekCount, 1, "Should have 1 birthday this week")
        XCTAssertEqual(summary.monthCount, 1, "Should have 1 birthday this month")
        XCTAssertNotNil(summary.nextBirthday, "Should have a next birthday")
        XCTAssertEqual(summary.nextBirthday?.daysUntil, 5, "Next birthday should be in 5 days")
    }

    func testFetchWidgetData_MonthBirthday() {
        // Arrange
        let nextMonth = Calendar.current.date(byAdding: .day, value: 20, to: Date())!
        let components = Calendar.current.dateComponents([.day, .month], from: nextMonth)
        let birthday = createBirthday(day: components.day!, month: components.month!, year: 1990)
        createPerson(name: "Lisa Braun", relation: "Freundin", birthday: birthday)

        // Act
        let summary = BirthdayWidgetData.fetchWidgetData(from: modelContext)

        // Assert
        XCTAssertEqual(summary.todayCount, 0, "Should have no birthdays today")
        XCTAssertEqual(summary.weekCount, 0, "Should have no birthdays this week")
        XCTAssertEqual(summary.monthCount, 1, "Should have 1 birthday this month")
        XCTAssertNotNil(summary.nextBirthday, "Should have a next birthday")
    }

    func testFetchWidgetData_Beyond30Days() {
        // Arrange
        let beyond30 = Calendar.current.date(byAdding: .day, value: 35, to: Date())!
        let components = Calendar.current.dateComponents([.day, .month], from: beyond30)
        let birthday = createBirthday(day: components.day!, month: components.month!, year: 1990)
        createPerson(name: "Peter Klein", relation: "Onkel", birthday: birthday)

        // Act
        let summary = BirthdayWidgetData.fetchWidgetData(from: modelContext)

        // Assert
        XCTAssertEqual(summary.monthCount, 0, "Should not include birthdays beyond 30 days")
        XCTAssertNil(summary.nextBirthday, "Should have no upcoming birthdays within 30 days")
        XCTAssertTrue(summary.upcomingBirthdays.isEmpty, "Should have no upcoming birthdays")
    }

    func testFetchWidgetData_MultipleBirthdaysSorted() {
        // Arrange
        let today = Calendar.current.startOfDay(for: Date())
        let todayBirthday = createBirthday(day: Calendar.current.component(.day, from: today), month: Calendar.current.component(.month, from: today), year: 1990)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let tomorrowComponents = Calendar.current.dateComponents([.day, .month], from: tomorrow)
        let tomorrowBirthday = createBirthday(day: tomorrowComponents.day!, month: tomorrowComponents.month!, year: 1990)
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let nextWeekComponents = Calendar.current.dateComponents([.day, .month], from: nextWeek)
        let nextWeekBirthday = createBirthday(day: nextWeekComponents.day!, month: nextWeekComponents.month!, year: 1990)

        createPerson(name: "Anna Schmidt", relation: "Schwester", birthday: todayBirthday)
        createPerson(name: "Max Müller", relation: "Bruder", birthday: nextWeekBirthday)
        createPerson(name: "Lisa Braun", relation: "Freundin", birthday: tomorrowBirthday)

        // Act
        let summary = BirthdayWidgetData.fetchWidgetData(from: modelContext)

        // Assert
        XCTAssertEqual(summary.todayCount, 1, "Should have 1 birthday today")
        XCTAssertEqual(summary.weekCount, 3, "Should have 3 birthdays this week")
        XCTAssertEqual(summary.monthCount, 3, "Should have 3 birthdays this month")
        XCTAssertEqual(summary.upcomingBirthdays.count, 3, "Should have 3 upcoming birthdays")
        XCTAssertEqual(summary.upcomingBirthdays[0].daysUntil, 0, "First birthday should be today")
        XCTAssertEqual(summary.upcomingBirthdays[1].daysUntil, 1, "Second birthday should be tomorrow")
        XCTAssertEqual(summary.upcomingBirthdays[2].daysUntil, 7, "Third birthday should be in 7 days")
    }

    func testFetchWidgetData_Limit() {
        // Arrange
        for i in 0..<10 {
            let date = Calendar.current.date(byAdding: .day, value: i, to: Date())!
            let components = Calendar.current.dateComponents([.day, .month], from: date)
            let birthday = createBirthday(day: components.day!, month: components.month!, year: 1990)
            createPerson(name: "Person \(i)", relation: "Bekannter", birthday: birthday)
        }

        // Act
        let summary = BirthdayWidgetData.fetchWidgetData(from: modelContext, limit: 5)

        // Assert
        XCTAssertEqual(summary.upcomingBirthdays.count, 5, "Should limit to 5 birthdays")
        XCTAssertEqual(summary.monthCount, 5, "monthCount is derived from limited entries")
    }

    // MARK: - Today's Birthdays Tests

    func testFetchTodayBirthdays_EmptyDatabase() {
        // Arrange & Act
        let todayBirthdays = BirthdayWidgetData.fetchTodayBirthdays(from: modelContext)

        // Assert
        XCTAssertTrue(todayBirthdays.isEmpty, "Should have no birthdays today")
    }

    func testFetchTodayBirthdays_SingleBirthday() {
        // Arrange
        let today = Calendar.current.startOfDay(for: Date())
        let birthday = createBirthday(day: Calendar.current.component(.day, from: today), month: Calendar.current.component(.month, from: today), year: 1990)
        createPerson(name: "Max Müller", relation: "Bruder", birthday: birthday)

        // Act
        let todayBirthdays = BirthdayWidgetData.fetchTodayBirthdays(from: modelContext)

        // Assert
        XCTAssertEqual(todayBirthdays.count, 1, "Should have 1 birthday today")
        XCTAssertTrue(todayBirthdays[0].isToday, "Birthday should be marked as today")
        XCTAssertEqual(todayBirthdays[0].daysUntil, 0, "Days until should be 0")
    }

    func testFetchTodayBirthdays_MultipleBirthdays() {
        // Arrange
        let today = Calendar.current.startOfDay(for: Date())
        let birthday = createBirthday(day: Calendar.current.component(.day, from: today), month: Calendar.current.component(.month, from: today), year: 1990)
        createPerson(name: "Max Müller", relation: "Bruder", birthday: birthday)
        createPerson(name: "Anna Schmidt", relation: "Schwester", birthday: birthday)

        // Act
        let todayBirthdays = BirthdayWidgetData.fetchTodayBirthdays(from: modelContext)

        // Assert
        XCTAssertEqual(todayBirthdays.count, 2, "Should have 2 birthdays today")
        XCTAssertTrue(todayBirthdays.allSatisfy { $0.isToday }, "All birthdays should be marked as today")
    }

    // MARK: - Timeline Entries Tests

    func testFetchTimelineEntries_DateRange() {
        // Arrange
        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!
        let nextWeek = Calendar.current.date(byAdding: .day, value: 5, to: startDate)!
        let components = Calendar.current.dateComponents([.day, .month], from: nextWeek)
        let birthday = createBirthday(day: components.day!, month: components.month!, year: 1990)
        createPerson(name: "Lisa Braun", relation: "Freundin", birthday: birthday)

        // Act
        let timelineEntries = BirthdayWidgetData.fetchTimelineEntries(
            from: modelContext,
            startDate: startDate,
            endDate: endDate
        )

        // Assert
        XCTAssertEqual(timelineEntries.count, 1, "Should have 1 birthday in date range")
        XCTAssertEqual(timelineEntries[0].daysUntil, 5, "Birthday should be in 5 days")
    }

    func testFetchTimelineEntries_OutsideDateRange() {
        // Arrange
        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!
        let beyondRange = Calendar.current.date(byAdding: .day, value: 10, to: startDate)!
        let components = Calendar.current.dateComponents([.day, .month], from: beyondRange)
        let birthday = createBirthday(day: components.day!, month: components.month!, year: 1990)
        createPerson(name: "Thomas Weber", relation: "Kollege", birthday: birthday)

        // Act
        let timelineEntries = BirthdayWidgetData.fetchTimelineEntries(
            from: modelContext,
            startDate: startDate,
            endDate: endDate
        )

        // Assert
        XCTAssertTrue(timelineEntries.isEmpty, "Should have no birthdays outside date range")
    }

    // MARK: - BirthdayEntry Tests

    func testBirthdayEntry_DisplayText_Today() {
        // Arrange
        let today = Calendar.current.startOfDay(for: Date())
        let components = Calendar.current.dateComponents([.day, .month], from: today)
        let birthday = createBirthday(day: components.day!, month: components.month!, year: 1990)
        createPerson(name: "Max Müller", relation: "Bruder", birthday: birthday)

        // Act
        let summary = BirthdayWidgetData.fetchWidgetData(from: modelContext)
        let entry = summary.nextBirthday!

        // Assert
        XCTAssertEqual(entry.displayText, "Heute!", "Today's birthday should display 'Heute!'")
    }

    func testBirthdayEntry_DisplayText_Tomorrow() {
        // Arrange
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let tomorrowComponents = Calendar.current.dateComponents([.day, .month], from: tomorrow)
        let tomorrowBirthday = createBirthday(day: tomorrowComponents.day!, month: tomorrowComponents.month!, year: 1990)
        createPerson(name: "Anna Schmidt", relation: "Schwester", birthday: tomorrowBirthday)

        // Act
        let tomorrowSummary = BirthdayWidgetData.fetchWidgetData(from: modelContext)
        let tomorrowEntry = tomorrowSummary.nextBirthday!

        // Assert
        XCTAssertEqual(tomorrowEntry.displayText, "Morgen", "Tomorrow's birthday should display 'Morgen'")
    }

    func testBirthdayEntry_DisplayText_NextWeek() {
        // Arrange
        let nextWeek = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
        let nextWeekComponents = Calendar.current.dateComponents([.day, .month], from: nextWeek)
        let nextWeekBirthday = createBirthday(day: nextWeekComponents.day!, month: nextWeekComponents.month!, year: 1990)
        createPerson(name: "Lisa Braun", relation: "Freundin", birthday: nextWeekBirthday)

        // Act
        let nextWeekSummary = BirthdayWidgetData.fetchWidgetData(from: modelContext)
        let nextWeekEntry = nextWeekSummary.nextBirthday!

        // Assert
        XCTAssertEqual(nextWeekEntry.displayText, "in 5 Tagen", "Future birthday should display 'in X Tagen'")
    }

    func testBirthdayEntry_IconSymbol() {
        // Arrange
        let today = Calendar.current.startOfDay(for: Date())

        // Today
        let todayComponents = Calendar.current.dateComponents([.day, .month], from: today)
        let todayBirthday = createBirthday(day: todayComponents.day!, month: todayComponents.month!, year: 1990)
        createPerson(name: "Max Müller", relation: "Bruder", birthday: todayBirthday)

        let summary = BirthdayWidgetData.fetchWidgetData(from: modelContext)
        let todayEntry = summary.nextBirthday!

        XCTAssertEqual(todayEntry.iconSymbol, "cake.fill", "Today's birthday icon should be cake.fill")

        // Test urgency levels by checking symbol patterns
        // (Actual testing of specific dates would require more complex date manipulation)
    }

    func testBirthdayEntry_UrgencyColor() {
        // Arrange
        let today = Calendar.current.startOfDay(for: Date())
        let todayComponents = Calendar.current.dateComponents([.day, .month], from: today)
        let todayBirthday = createBirthday(day: todayComponents.day!, month: todayComponents.month!, year: 1990)
        createPerson(name: "Max Müller", relation: "Bruder", birthday: todayBirthday)

        // Act
        let summary = BirthdayWidgetData.fetchWidgetData(from: modelContext)
        let todayEntry = summary.nextBirthday!

        // Assert
        XCTAssertEqual(todayEntry.urgencyColor, .today, "Today's birthday should have .today urgency color")
        XCTAssertEqual(todayEntry.urgencyColor.hexValue, "#FF3B30", "Today's birthday should have red color")
    }

    func testBirthdayEntry_LocalizedDisplay() {
        // Arrange
        let today = Calendar.current.startOfDay(for: Date())
        let todayComponents = Calendar.current.dateComponents([.day, .month], from: today)
        let todayBirthday = createBirthday(day: todayComponents.day!, month: todayComponents.month!, year: 1990)
        createPerson(name: "Max Müller", relation: "Bruder", birthday: todayBirthday)

        // Act
        let summary = BirthdayWidgetData.fetchWidgetData(from: modelContext)
        let entry = summary.nextBirthday!
        let localizedText = entry.localizedDisplay()

        // Assert
        XCTAssertTrue(localizedText.contains("🎂"), "Should contain cake emoji")
        XCTAssertTrue(localizedText.contains("Max Müller"), "Should contain person name")
        XCTAssertTrue(localizedText.contains("Heute!"), "Should contain 'Heute!' for today")
    }

    func testBirthdayEntry_AccessibilityLabel() {
        // Arrange
        let today = Calendar.current.startOfDay(for: Date())
        let todayComponents = Calendar.current.dateComponents([.day, .month], from: today)
        let todayBirthday = createBirthday(day: todayComponents.day!, month: todayComponents.month!, year: 1990)
        createPerson(name: "Max Müller", relation: "Bruder", birthday: todayBirthday)

        // Act
        let summary = BirthdayWidgetData.fetchWidgetData(from: modelContext)
        let entry = summary.nextBirthday!
        let accessibilityLabel = entry.accessibilityLabel()

        // Assert
        XCTAssertTrue(accessibilityLabel.contains("Max Müller"), "Should contain person name")
        XCTAssertTrue(accessibilityLabel.contains("Bruder"), "Should contain relation")
        XCTAssertTrue(accessibilityLabel.contains("heute Geburtstag"), "Should mention today's birthday")
        XCTAssertTrue(accessibilityLabel.contains("Jahre"), "Should mention age")
    }
}
