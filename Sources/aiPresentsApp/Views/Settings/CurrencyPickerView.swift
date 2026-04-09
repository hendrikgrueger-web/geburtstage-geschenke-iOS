import SwiftUI

struct CurrencyPickerView: View {
    @Environment(\.dismiss) private var dismiss
    private var currencyManager: CurrencyManager { CurrencyManager.shared }

    var body: some View {
        List {
                Section {
                    Toggle("Automatisch (Geräteregion)", isOn: Binding(
                        get: { currencyManager.isAutomatic },
                        set: { currencyManager.isAutomatic = $0 }
                    ))
                } footer: {
                    if currencyManager.isAutomatic {
                        Text("Aktuelle Währung: \(currencyManager.currencyName) (\(currencyManager.effectiveCurrencyCode))")
                    }
                }

                if !currencyManager.isAutomatic {
                    Section("Währung wählen") {
                        ForEach(CurrencyManager.commonCurrencyCodes, id: \.self) { code in
                            let name = Locale.current.localizedString(forCurrencyCode: code) ?? code
                            Button {
                                currencyManager.currencyCode = code
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(name)
                                            .foregroundStyle(.primary)
                                        Text(code)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if currencyManager.currencyCode == code {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(AppColor.primary)
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        .navigationTitle("Währung")
        .navigationBarTitleDisplayMode(.inline)
    }
}
