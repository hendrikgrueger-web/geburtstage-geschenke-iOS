import Foundation

/// Debounces rapid changes to a value, only emitting the final value after a delay.
/// Useful for search fields and other inputs where processing should wait until the user stops typing.
@MainActor
final class Debouncer {
    private var task: Task<Void, Never>?

    /// The debounce delay in seconds
    let delay: TimeInterval

    init(delay: TimeInterval = 0.3) {
        self.delay = delay
    }

    /// Debounces the provided value, cancelling any pending updates
    func debounce(_ action: @escaping @Sendable () -> Void) {
        task?.cancel()
        task = Task {
            try? await Task.sleep(for: .seconds(delay))
            if !Task.isCancelled {
                action()
            }
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}
