import SwiftUI

/// Temporärer Stub — wird durch echte PaywallView aus dem Paywall-Worktree ersetzt.
struct PaywallView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Premium Upgrade")
                    .font(.title2.bold())

                Text("Unlock full access to all features")
                    .foregroundStyle(.secondary)

                Spacer()

                VStack(spacing: 12) {
                    if !subscriptionManager.products.isEmpty {
                        ForEach(subscriptionManager.products, id: \.id) { product in
                            Button {
                                Task { _ = try? await subscriptionManager.purchase(product) }
                            } label: {
                                Text(product.displayName)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(AppColor.primary)
                                    .foregroundStyle(.white)
                                    .clipShape(.rect(cornerRadius: 12))
                            }
                        }
                    } else {
                        Text("Products loading...")
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task { await subscriptionManager.loadProducts() }
    }
}

#Preview {
    PaywallView()
        .environmentObject(SubscriptionManager())
}
