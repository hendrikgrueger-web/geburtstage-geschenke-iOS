import SwiftUI

/// Utility for consistent accessibility configuration across the app
@MainActor
enum AccessibilityConfiguration {

    /// Checks if reduced motion is enabled
    static var isReducedMotionEnabled: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    /// Checks if dynamic type is larger than default
    static var isLargeTextEnabled: Bool {
        UIFont.preferredFont(forTextStyle: .body).pointSize > 17
    }

    /// Checks if voice over is running
    static var isVoiceOverRunning: Bool {
        UIAccessibility.isVoiceOverRunning
    }

    /// Creates an animation that respects reduced motion settings
    static func animation(_ animation: Animation?, defaultDuration: Double = 0.3) -> Animation? {
        guard !isReducedMotionEnabled else { return nil }
        return animation ?? .easeInOut(duration: defaultDuration)
    }

    /// Provides accessible value formatting for numbers
    static func formatNumber(_ value: Int, unit: String? = nil) -> String {
        var result = "\(value)"
        if let unit = unit {
            result += " \(unit)"
        }
        return result
    }

    /// Provides accessible date formatting
    static func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    /// Provides accessible duration formatting (e.g., "5 minutes")
    static func formatDuration(_ seconds: TimeInterval) -> String {
        if seconds < 60 {
            return "\(Int(seconds)) Sekunden"
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            return "\(minutes) Minute\(minutes == 1 ? "" : "n")"
        } else {
            let hours = Int(seconds / 3600)
            let remainingMinutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
            if remainingMinutes > 0 {
                return "\(hours) Stunde\(hours == 1 ? "" : "n") \(remainingMinutes) Minute\(remainingMinutes == 1 ? "" : "n")"
            } else {
                return "\(hours) Stunde\(hours == 1 ? "" : "n")"
            }
        }
    }

    /// Creates accessibility traits for a button with action
    static func buttonTraits(isEnabled: Bool = true) -> AccessibilityTraits {
        var traits: AccessibilityTraits = [.isButton]
        if !isEnabled {
            _ = traits.insert(.isStaticText)
        }
        return traits
    }

    /// Creates accessibility traits for a selectable element
    static func selectableTraits(isSelected: Bool) -> AccessibilityTraits {
        var traits: AccessibilityTraits = [.isButton]
        if isSelected {
            _ = traits.insert(.isSelected)
        }
        return traits
    }

    /// Creates accessibility hint for navigation
    static func navigationHint(destination: String) -> String {
        "Navigiert zu \(destination)"
    }

    /// Creates accessibility hint for actions
    static func actionHint(_ action: String) -> String {
        "Doppeltippen für \(action)"
    }

    /// Provides accessible relative date description
    static func relativeDateDescription(from date: Date, reference: Date = Date()) -> String {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: reference, to: date).day ?? 0

        switch days {
        case 0:
            return String(localized: "Heute")
        case 1:
            return String(localized: "Morgen")
        case -1:
            return String(localized: "Gestern")
        case 2...6:
            let d = days
            return String(localized: "In") + " \(d) " + String(localized: "Tagen")
        case let x where x < 0:
            return String(localized: "vor") + " \(abs(x)) " + String(localized: "Tagen")
        default:
            let d = days
            return String(localized: "In") + " \(d) " + String(localized: "Tagen")
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Applies accessible configuration to a view
    func accessible(
        label: String,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(traits)
    }

    /// Applies accessible toggle configuration
    func accessibleToggle(label: String, isOn: Bool) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(isOn ? "Aktiviert, doppeltippen zum Deaktivieren" : "Deaktiviert, doppeltippen zum Aktivieren")
            .accessibilityAddTraits([.isButton, isOn ? .isSelected : []])
    }

    /// Applies accessible navigation link configuration
    func accessibleNavigation(label: String, destination: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(AccessibilityConfiguration.navigationHint(destination: destination))
            .accessibilityAddTraits(.isLink)
    }

    /// Respects reduced motion for animations
    func reducedMotionAnimation(_ animation: Animation? = .easeInOut(duration: 0.3)) -> some View {
        self.animation(
            AccessibilityConfiguration.isReducedMotionEnabled ? nil : animation,
            value: UUID().hashValue
        )
    }

    /// Adds dynamic type support with scaling
    func supportsDynamicType(minScale: CGFloat = 0.8, maxScale: CGFloat = 1.5) -> some View {
        self
            .dynamicTypeSize(.xSmall ... .accessibility5)
            .minimumScaleFactor(minScale)
    }

    /// Hides view from voice over if condition is met
    func accessibleHidden(_ hidden: Bool = true) -> some View {
        self
            .accessibility(hidden: hidden)
            .accessibilityElement(children: hidden ? .ignore : .contain)
    }

    /// Combines accessibility elements for better voice over experience
    func combineAccessibilityElements(label: String? = nil) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label ?? "")
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension AccessibilityConfiguration {
    static var mockReducedMotion: Bool {
        false
    }

    static var mockLargeText: Bool {
        false
    }
}
#endif
