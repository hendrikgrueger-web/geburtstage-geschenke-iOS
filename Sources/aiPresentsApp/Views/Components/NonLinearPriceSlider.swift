import SwiftUI

/// Preis-Slider mit nicht-linearen Schritten: klein am Anfang, groß am Ende.
/// 0-50€ in 5er Schritten, 50-100€ in 10er, 100-500€ in 50er.
struct NonLinearPriceSlider: View {
    @Binding var price: Double

    // Diskrete Preisstufen: feine Schritte unten, grobe oben
    private static let steps: [Double] = {
        var s: [Double] = []
        s += stride(from: 0, through: 50, by: 5).map { $0 }     // 0,5,10,...,50
        s += stride(from: 60, through: 100, by: 10).map { $0 }   // 60,70,...,100
        s += stride(from: 150, through: 500, by: 50).map { $0 }   // 150,200,...,500
        return s
    }()

    // Slider-Index (0 bis steps.count-1)
    private var sliderIndex: Binding<Double> {
        Binding(
            get: {
                // Finde den nächsten Step-Index für den aktuellen Preis
                let idx = Self.steps.enumerated().min(by: { abs($0.element - price) < abs($1.element - price) })?.offset ?? 0
                return Double(idx)
            },
            set: { newIndex in
                let idx = Int(newIndex.rounded())
                let clamped = max(0, min(idx, Self.steps.count - 1))
                price = Self.steps[clamped]
            }
        )
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Geschätzter Preis")
                Spacer()
                Text(CurrencyManager.shared.formatAmountOrEmpty(price))
                    .foregroundStyle(price > 0 ? AppColor.primary : .secondary)
                    .fontWeight(.semibold)
            }

            Slider(value: sliderIndex,
                   in: 0...Double(Self.steps.count - 1),
                   step: 1) {
                Text("Geschätzter Preis")
            } minimumValueLabel: {
                Text(CurrencyManager.shared.formatAmount(0)).font(.caption2).foregroundStyle(.secondary)
            } maximumValueLabel: {
                Text(CurrencyManager.shared.formatAmount(500)).font(.caption2).foregroundStyle(.secondary)
            }
            .tint(AppColor.primary)
            .accessibilityLabel(String(localized: "Geschätzter Preis"))
            .accessibilityValue(CurrencyManager.shared.formatAmount(price))
        }
        .padding(.vertical, 4)
    }
}
