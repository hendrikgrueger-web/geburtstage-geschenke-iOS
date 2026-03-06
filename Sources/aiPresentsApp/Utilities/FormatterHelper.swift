import Foundation
import SwiftUI

// MARK: - Formatter Helper
struct FormatterHelper {
    /// Shared date formatter for display dates
    static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = .current
        return formatter
    }()

    /// Shared date formatter for short dates
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = .current
        return formatter
    }()

    /// Kurzes Log-Datum (dd.MM.yy) für Status-Logs.
    static let shortLogDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yy"
        return f
    }()

    /// Number formatter for currency (Euro)
    static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.currencySymbol = "€"
        formatter.locale = .current
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    /// Number formatter for budget ranges
    static let budgetFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    /// Number formatter for percentages
    static let percentageFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    // MARK: - Date Formatting

    /// Formats a date for display (medium style)
    static func formatDate(_ date: Date) -> String {
        return displayDateFormatter.string(from: date)
    }

    /// Formats a date in short format
    static func formatShortDate(_ date: Date) -> String {
        return shortDateFormatter.string(from: date)
    }

    /// Formats a date relative to today (e.g., "Heute", "Morgen", "In X Tagen")
    static func formatRelativeDate(_ date: Date, from referenceDate: Date = Date()) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: referenceDate)
        let target = calendar.startOfDay(for: date)

        let components = calendar.dateComponents([.day], from: today, to: target)
        guard let days = components.day else { return formatDate(date) }

        if days == 0 {
            return String(localized: "Heute")
        } else if days == 1 {
            return String(localized: "Morgen")
        } else if days == -1 {
            return String(localized: "Gestern")
        } else if days > 0 && days < 7 {
            return String(localized: "In \(days) Tagen")
        } else if days < 0 && days > -7 {
            let absDays = -days
            return String(localized: "Vor \(absDays) Tagen")
        } else {
            return formatDate(date)
        }
    }

    /// Formats a month and year
    static func formatMonthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    /// Formats a weekday
    static func formatWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    // MARK: - Number/Currency Formatting

    /// Formats a number as currency (Euro)
    static func formatCurrency(_ amount: Double) -> String {
        return currencyFormatter.string(from: NSNumber(value: amount)) ?? "0€"
    }

    /// Formats a budget range
    static func formatBudget(min: Double, max: Double) -> String {
        if min == max {
            return formatCurrency(min)
        } else if min == 0 {
            let maxFormatted = formatCurrency(max)
            return String(localized: "bis \(maxFormatted)")
        } else {
            return "\(formatCurrency(min)) - \(formatCurrency(max))"
        }
    }

    /// Formats a number for display
    static func formatNumber(_ number: Double) -> String {
        return budgetFormatter.string(from: NSNumber(value: number)) ?? "0"
    }

    /// Formats a percentage
    static func formatPercentage(_ value: Double) -> String {
        return percentageFormatter.string(from: NSNumber(value: value)) ?? "0%"
    }

    // MARK: - Text Formatting

    /// Formats a list of items with commas and localized conjunction
    static func formatList(_ items: [String]) -> String {
        let conjunction = String(localized: "und")
        switch items.count {
        case 0:
            return ""
        case 1:
            return items[0]
        case 2:
            return "\(items[0]) \(conjunction) \(items[1])"
        default:
            let allButLast = items.dropLast().joined(separator: ", ")
            return "\(allButLast) \(conjunction) \(items.last!)"
        }
    }

    /// Truncates text to a maximum length with ellipsis
    static func truncate(_ text: String, maxLength: Int) -> String {
        if text.count <= maxLength {
            return text
        }
        if maxLength <= 3 {
            return String(text.prefix(maxLength))
        }
        let index = text.index(text.startIndex, offsetBy: maxLength - 3)
        return String(text[..<index]) + "..."
    }

    /// Sanitizes and formats a URL for display
    static func formatURL(_ urlString: String) -> String {
        guard let url = URL(string: urlString) else { return urlString }
        return url.host ?? urlString
    }

    // MARK: - Age Formatting

    /// Formats age with proper grammar
    static func formatAge(_ age: Int) -> String {
        return String(localized: "\(age) Jahre alt")
    }

    /// Formats turning age for upcoming birthdays
    static func formatTurningAge(_ age: Int) -> String {
        return String(localized: "wird \(age)")
    }

    // MARK: - Duration Formatting

    /// Formats duration in days with proper grammar
    static func formatDuration(_ days: Int) -> String {
        if days == 1 {
            return String(localized: "1 Tag")
        } else {
            return String(localized: "\(days) Tage")
        }
    }

    /// Formats time ago (e.g., "vor 5 Minuten")
    static func formatTimeAgo(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfMonth, .month, .year], from: date, to: now)

        if let years = components.year, years > 0 {
            let unit = years == 1 ? String(localized: "Jahr") : String(localized: "Jahren")
            return String(localized: "vor") + " \(years) \(unit)"
        } else if let months = components.month, months > 0 {
            let unit = months == 1 ? String(localized: "Monat") : String(localized: "Monaten")
            return String(localized: "vor") + " \(months) \(unit)"
        } else if let weeks = components.weekOfMonth, weeks > 0 {
            let unit = weeks == 1 ? String(localized: "Woche") : String(localized: "Wochen")
            return String(localized: "vor") + " \(weeks) \(unit)"
        } else if let days = components.day, days > 0 {
            let unit = days == 1 ? String(localized: "Tag") : String(localized: "Tagen")
            return String(localized: "vor") + " \(days) \(unit)"
        } else if let hours = components.hour, hours > 0 {
            let unit = hours == 1 ? String(localized: "Stunde") : String(localized: "Stunden")
            return String(localized: "vor") + " \(hours) \(unit)"
        } else if let minutes = components.minute, minutes > 0 {
            let unit = minutes == 1 ? String(localized: "Minute") : String(localized: "Minuten")
            return String(localized: "vor") + " \(minutes) \(unit)"
        } else {
            return String(localized: "gerade eben")
        }
    }
}

// MARK: - Preview
#Preview("Formatter Helper") {
    VStack(alignment: .leading, spacing: 12) {
        Text("Formatter Helper Examples")
            .font(.headline)

        Text("Date: \(FormatterHelper.formatDate(Date()))")
        Text("Currency: \(FormatterHelper.formatCurrency(99.99))")
        Text("Budget: \(FormatterHelper.formatBudget(min: 25, max: 75))")
        Text("Relative: \(FormatterHelper.formatRelativeDate(Date().addingTimeInterval(86400 * 3)))")
        Text("Age: \(FormatterHelper.formatAge(35))")
        Text("List: \(FormatterHelper.formatList(["Apfel", "Birne", "Kirsche"]))")
    }
    .padding()
}
