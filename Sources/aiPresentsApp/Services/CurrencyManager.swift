import Foundation
import SwiftUI

@MainActor @Observable
final class CurrencyManager {
    static let shared = CurrencyManager()

    private let automaticKey = "currencyAutomatic"
    private let codeKey = "selectedCurrencyCode"
    private let iCloudStore = NSUbiquitousKeyValueStore.default

    var isAutomatic: Bool {
        didSet {
            UserDefaults.standard.set(isAutomatic, forKey: automaticKey)
            iCloudStore.set(isAutomatic, forKey: automaticKey)
        }
    }

    var currencyCode: String {
        didSet {
            UserDefaults.standard.set(currencyCode, forKey: codeKey)
            iCloudStore.set(currencyCode, forKey: codeKey)
        }
    }

    /// Die effektiv genutzte Währung (Locale-Auto oder manueller Override)
    var effectiveCurrencyCode: String {
        isAutomatic ? (Locale.current.currency?.identifier ?? "EUR") : currencyCode
    }

    /// Lokalisierter Währungsname ("Euro", "US Dollar", …)
    var currencyName: String {
        Locale.current.localizedString(forCurrencyCode: effectiveCurrencyCode) ?? effectiveCurrencyCode
    }

    /// Währungssymbol ("€", "$", "¥", …)
    var currencySymbol: String {
        let locale = Locale(identifier: Locale.identifier(
            fromComponents: [NSLocale.Key.currencyCode.rawValue: effectiveCurrencyCode]
        ))
        return locale.currencySymbol ?? effectiveCurrencyCode
    }

    private init() {
        // Lade gespeicherte Werte; Default: automatisch
        let storedAuto = UserDefaults.standard.object(forKey: "currencyAutomatic") as? Bool ?? true
        let storedCode = UserDefaults.standard.string(forKey: "selectedCurrencyCode")
            ?? (Locale.current.currency?.identifier ?? "EUR")
        self.isAutomatic = storedAuto
        self.currencyCode = storedCode

        // iCloud Sync bei externen Änderungen
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(iCloudDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: iCloudStore
        )
        iCloudStore.synchronize()
    }

    @objc private func iCloudDidChange(_ notification: Notification) {
        if let auto = iCloudStore.object(forKey: automaticKey) as? Bool {
            isAutomatic = auto
        }
        if let code = iCloudStore.string(forKey: codeKey) {
            currencyCode = code
        }
    }

    /// Formatiert einen Betrag in der aktiven Währung (0 Nachkommastellen für ganzzahlige Währungen)
    func formatAmount(_ amount: Double) -> String {
        let decimalAmount = Decimal(amount)
        return decimalAmount.formatted(
            .currency(code: effectiveCurrencyCode)
            .precision(.fractionLength(isFractionalCurrency ? 2 : 0))
            .locale(Locale.current)
        )
    }

    /// Formatiert einen Budget-Bereich
    func formatBudgetRange(min: Double, max: Double) -> String {
        if min == max && min > 0 {
            return formatAmount(min)
        } else if min == 0 && max > 0 {
            return String(localized: "bis \(formatAmount(max))")
        } else if min > 0 && max > 0 {
            return "\(formatAmount(min)) – \(formatAmount(max))"
        }
        return ""
    }

    /// Gibt "Kein Preis" zurück wenn amount == 0, sonst formatAmount
    func formatAmountOrEmpty(_ amount: Double) -> String {
        amount > 0 ? formatAmount(amount) : String(localized: "Kein Preis")
    }

    // MARK: - Slider-Konfiguration pro Währung

    var sliderMinimum: Double { 0 }

    var sliderMaximum: Double {
        switch effectiveCurrencyCode {
        case "JPY", "KRW": return 50_000
        case "SEK", "NOK", "DKK": return 5_000
        case "INR": return 25_000
        default: return 500
        }
    }

    var sliderStep: Double {
        switch effectiveCurrencyCode {
        case "JPY", "KRW": return 500
        case "SEK", "NOK", "DKK": return 50
        case "INR": return 250
        default: return 5
        }
    }

    // MARK: - Häufig verwendete Währungen

    static let commonCurrencyCodes = ["EUR", "USD", "GBP", "CHF", "SEK", "NOK", "DKK", "PLN", "CZK", "JPY", "CAD", "AUD"]

    // MARK: - Helpers

    private var isFractionalCurrency: Bool {
        // Währungen ohne Dezimalstellen
        !["JPY", "KRW", "HUF", "ISK", "CLP", "VND"].contains(effectiveCurrencyCode)
    }
}
