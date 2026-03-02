import SwiftUI

// MARK: - Toast Message Type
enum ToastType {
    case success
    case error
    case warning
    case info

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .success: return AppColor.success
        case .error: return AppColor.error
        case .warning: return AppColor.warning
        case .info: return AppColor.primary
        }
    }
}

// MARK: - Toast Item
struct ToastItem: Identifiable {
    let id = UUID()
    let type: ToastType
    let title: String
    let message: String?
    let duration: TimeInterval

    init(type: ToastType, title: String, message: String? = nil, duration: TimeInterval = 3.0) {
        self.type = type
        self.title = title
        self.message = message
        self.duration = duration
    }

    static func success(_ title: String, message: String? = nil) -> ToastItem {
        ToastItem(type: .success, title: title, message: message)
    }

    static func error(_ title: String, message: String? = nil) -> ToastItem {
        ToastItem(type: .error, title: title, message: message)
    }

    static func warning(_ title: String, message: String? = nil) -> ToastItem {
        ToastItem(type: .warning, title: title, message: message)
    }

    static func info(_ title: String, message: String? = nil) -> ToastItem {
        ToastItem(type: .info, title: title, message: message)
    }
}

// MARK: - Toast View
struct ToastView: View {
    let item: ToastItem
    @Binding var isPresented: Bool
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 0

    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                Image(systemName: item.type.icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(item.type.color)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundColor(AppColor.textPrimary)
                    if let message = item.message {
                        Text(message)
                            .font(.subheadline)
                            .foregroundColor(AppColor.textSecondary)
                    }
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(AppColor.textSecondary)
                }
            }
            .padding(16)
            .background(AppColor.cardBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)
            .padding(.horizontal, 16)
            .padding(.bottom, isPresented ? 16 : -100)
            .offset(x: offset)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(AnimationHelper.spring) {
                offset = 0
                opacity = 1
            }
            // Modern Swift Concurrency for auto-dismiss
            Task {
                try? await Task.sleep(for: .seconds(item.duration))
                if isPresented { dismissWithAnimation() }
            }
        }
    }

    private func dismissWithAnimation() {
        withAnimation(AnimationHelper.easeOut) {
            offset = 0
            opacity = 0
        }
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            isPresented = false
        }
    }

    private func dismiss() {
        dismissWithAnimation()
    }
}

// MARK: - Toast Modifier
struct ToastModifier: ViewModifier {
    @Binding var toast: ToastItem?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let toast = toast {
                    ToastView(item: toast, isPresented: Binding(
                        get: { self.toast != nil },
                        set: { if !$0 { self.toast = nil } }
                    ))
                }
            }
    }
}

// MARK: - View Extension
extension View {
    func toast(item: Binding<ToastItem?>) -> some View {
        self.modifier(ToastModifier(toast: item))
    }
}
