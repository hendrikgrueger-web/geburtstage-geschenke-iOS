import SwiftUI

struct SuggestionFeedbackView: View {
    let suggestion: GiftSuggestion
    let personId: UUID
    let onFeedback: (Bool) -> Void

    @State private var hasGivenFeedback = false

    var body: some View {
        HStack(spacing: 12) {
            Text("War das hilfreich?")
                .font(.caption)
                .foregroundColor(AppColor.textSecondary)

            Spacer()

            HStack(spacing: 8) {
                Button(action: {
                    onFeedback(true)
                    hasGivenFeedback = true
                    HapticFeedback.light()
                }) {
                    Image(systemName: hasGivenFeedback ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .font(.title3)
                        .foregroundColor(hasGivenFeedback ? .green : AppColor.textSecondary)
                }
                .buttonStyle(.plain)
                .disabled(hasGivenFeedback)

                Button(action: {
                    onFeedback(false)
                    hasGivenFeedback = true
                    HapticFeedback.light()
                }) {
                    Image(systemName: hasGivenFeedback ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                        .font(.title3)
                        .foregroundColor(hasGivenFeedback ? .red : AppColor.textSecondary)
                }
                .buttonStyle(.plain)
                .disabled(hasGivenFeedback)
            }
        }
        .padding(.top, 4)
        .opacity(hasGivenFeedback ? 0.6 : 1.0)
    }
}

#Preview {
    VStack(spacing: 16) {
        SuggestionFeedbackView(
            suggestion: GiftSuggestion(
                title: "Erlebnis-Gutschein",
                reason: "Perfekt für jemanden der neue Erlebnisse sucht"
            ),
            personId: UUID(),
            onFeedback: { isPositive in
                print("Feedback: \(isPositive)")
            }
        )
    }
    .padding()
}
