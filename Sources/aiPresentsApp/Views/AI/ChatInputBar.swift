import SwiftUI

/// Eingabeleiste für den KI-Chat: Textfeld + Mikrofon + Sende-Button.
struct ChatInputBar: View {
    @Binding var text: String
    let isLoading: Bool
    let onSend: () -> Void
    let onMicTap: () -> Void
    var isRecording: Bool = false

    @FocusState private var isFocused: Bool

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Mikrofon-Button
            Button {
                onMicTap()
            } label: {
                Image(systemName: isRecording ? "mic.fill" : "mic")
                    .font(.system(size: 20))
                    .foregroundColor(isRecording ? .red : .secondary)
                    .frame(width: 36, height: 36)
                    .background(isRecording ? Color.red.opacity(0.12) : Color.clear)
                    .clipShape(Circle())
                    .symbolEffect(.pulse, isActive: isRecording)
            }
            .accessibilityLabel(isRecording ? String(localized: "Aufnahme stoppen") : String(localized: "Spracheingabe"))

            // Textfeld
            TextField(String(localized: "Nachricht..."), text: $text, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .focused($isFocused)
                .submitLabel(.send)
                .onSubmit {
                    if canSend { onSend() }
                }
                .accessibilityLabel(String(localized: "Nachricht eingeben"))

            // Sende-Button
            Button {
                if canSend { onSend() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(canSend ? AppColor.primary : Color(.tertiaryLabel))
            }
            .disabled(!canSend)
            .accessibilityLabel(String(localized: "Senden"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }
}
