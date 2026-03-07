import Foundation
import SwiftUI

/// Debounces rapid changes to a value, only emitting the final value after a delay.
/// Useful for search fields and other inputs where processing should wait until the user stops typing.
@MainActor
class Debouncer: ObservableObject {
    private var task: Task<Void, Never>?

    /// The debounce delay in seconds
    let delay: TimeInterval

    /// Creates a new debouncer with the specified delay
    /// - Parameter delay: The delay in seconds to wait before emitting the final value (default: 0.3 seconds)
    init(delay: TimeInterval = 0.3) {
        self.delay = delay
    }

    /// Debounces the provided value, cancelling any pending updates
    /// - Parameter action: The action to execute after the delay
    func debounce(_ action: @escaping () -> Void) {
        // Cancel any pending task
        task?.cancel()

        // Create a new task that will execute the action after the delay
        task = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

            // Check if the task was cancelled while sleeping
            if !Task.isCancelled {
                action()
            }
        }
    }

    /// Cancels any pending debounced action without executing it
    func cancel() {
        task?.cancel()
        task = nil
    }
}

/// A property wrapper that debounces value changes
@MainActor
@propertyWrapper
struct Debounced<Value: Equatable> {
    private let debouncer: Debouncer
    private var _projectedValue: Value

    /// The current non-debounced value
    var wrappedValue: Value {
        get { _projectedValue }
        set {
            _projectedValue = newValue
        }
    }

    /// The debounced value (accessed via $)
    var projectedValue: Debounced<Value> {
        get { self }
    }

    /// Initializes the debounced property
    /// - Parameters:
    ///   - wrappedValue: The initial value
    ///   - delay: The debounce delay in seconds (default: 0.3)
    init(wrappedValue: Value, delay: TimeInterval = 0.3) {
        self._projectedValue = wrappedValue
        self.debouncer = Debouncer(delay: delay)
    }

    /// Sets the value with debouncing
    /// - Parameter value: The new value
    mutating func update(with value: Value, onChange: @escaping (Value) -> Void) {
        _projectedValue = value
        debouncer.debounce {
            onChange(value)
        }
    }

    /// Cancels any pending debounced update
    mutating func cancelPending() {
        debouncer.cancel()
    }
}

// MARK: - View Extension for Debounced Search
extension View {
    /// Adds a debounced search field to the view
    /// - Parameters:
    ///   - text: Binding to the search text
    ///   - debouncedText: Binding to store the debounced text
    ///   - delay: The debounce delay in seconds (default: 0.3)
    ///   - prompt: The placeholder text
    /// - Returns: A view with a debounced searchable modifier
    func searchableWithDebounce(
        _ text: Binding<String>,
        debouncedText: Binding<String>,
        delay: TimeInterval = 0.3,
        prompt: Text
    ) -> some View {
        self
            .searchable(text: text, prompt: prompt)
            .onChange(of: text.wrappedValue) { oldValue, newValue in
                @MainActor
                func debouncedUpdate() {
                    let debouncer = Debouncer(delay: delay)
                    debouncer.debounce {
                        debouncedText.wrappedValue = newValue
                    }
                }
                debouncedUpdate()
            }
    }
}

// MARK: - Throttler for Rate Limiting
@MainActor
class Throttler {
    private var task: Task<Void, Never>?
    private let minimumInterval: TimeInterval

    /// Creates a new throttler
    /// - Parameter minimumInterval: The minimum interval between executions in seconds
    init(minimumInterval: TimeInterval = 1.0) {
        self.minimumInterval = minimumInterval
    }

    /// Throttles the execution of an action
    /// - Parameter action: The action to execute (will be skipped if called too frequently)
    func throttle(_ action: @escaping () -> Void) {
        // If a task is still running, skip this call
        guard task == nil || task?.isCancelled == true else {
            return
        }

        // Create a new task
        task = Task {
            action()

            // Wait for the minimum interval before allowing another execution
            try? await Task.sleep(nanoseconds: UInt64(minimumInterval * 1_000_000_000))

            task = nil
        }
    }

    /// Cancels any pending throttled action
    func cancel() {
        task?.cancel()
        task = nil
    }
}

// MARK: - Debounced Value Publisher
import Combine

/// A publisher that debounces value changes
@MainActor
class DebouncedPublisher<Value>: ObservableObject {
    @Published var value: Value

    private let subject = PassthroughSubject<Value, Never>()
    private var cancellable: AnyCancellable?
    private let debounceDelay: TimeInterval

    /// The debounced value
    @Published var debouncedValue: Value {
        didSet {
            // Notify subscribers when debounced value changes
            subject.send(debouncedValue)
        }
    }

    /// Initializes the publisher
    /// - Parameters:
    ///   - initialValue: The initial value
    ///   - delay: The debounce delay in seconds
    init(initialValue: Value, delay: TimeInterval = 0.3) {
        self.value = initialValue
        self.debouncedValue = initialValue
        self.debounceDelay = delay

        setupSubscription()
    }

    private func setupSubscription() {
        cancellable = $value
            .debounce(for: .seconds(debounceDelay), scheduler: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.debouncedValue = newValue
            }
    }

    /// Updates the current value (will be debounced)
    func update(_ newValue: Value) {
        value = newValue
    }

    /// Subscribes to debounced value changes
    func subscribe(_ handler: @escaping (Value) -> Void) -> AnyCancellable {
        return subject.sink(receiveValue: handler)
    }
}

// MARK: - Debounce Strategies
enum DebounceStrategy {
    /// Standard debounce: wait until user stops typing
    case standard(delay: TimeInterval = 0.3)

    /// Aggressive debounce: faster response but more CPU usage
    case aggressive(delay: TimeInterval = 0.15)

    /// Conservative debounce: better for expensive operations
    case conservative(delay: TimeInterval = 0.5)

    var delay: TimeInterval {
        switch self {
        case .standard(let delay),
             .aggressive(let delay),
             .conservative(let delay):
            return delay
        }
    }
}

// MARK: - Usage Examples
#if DEBUG
@MainActor
struct DebouncerPreview: View {
    @State private var searchText = ""
    @State private var debouncedText = ""
    @State private var resultCount = 0

    private let debouncer = Debouncer(delay: 0.3)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Debouncer Demo")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Search Input: \(searchText)")
                    .font(.caption)
                Text("Debounced: \(debouncedText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Results: \(resultCount)")
                    .font(.caption)
            }

            TextField("Type to search...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .onChange(of: searchText) { oldValue, newValue in
                    debouncer.debounce {
                        debouncedText = newValue
                        resultCount = Int.random(in: 0...100)
                    }
                }
        }
        .padding()
    }
}
#endif
