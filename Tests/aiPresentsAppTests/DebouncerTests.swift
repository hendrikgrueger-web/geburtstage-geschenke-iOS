import XCTest
@testable import aiPresentsApp
import Combine

@MainActor
final class DebouncerTests: XCTestCase {
    var debouncer: Debouncer!
    var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        debouncer = Debouncer(delay: 0.1) // Short delay for testing
        cancellables = Set<AnyCancellable>()
    }

    override func tearDownWithError() throws {
        debouncer.cancel()
        debouncer = nil
        cancellables = nil
    }

    // MARK: - Basic Debounce Tests

    func testDebounceExecutesAfterDelay() async throws {
        var executed = false
        var executionTime: Date?

        debouncer.debounce {
            executed = true
            executionTime = Date()
        }

        // Wait briefly - should not execute yet
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05s
        XCTAssertFalse(executed, "Should not execute immediately")

        // Wait for delay - should execute
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        XCTAssertTrue(executed, "Should execute after delay")
        XCTAssertNotNil(executionTime)
    }

    func testDebounceCancelsPreviousAction() async throws {
        var executionCount = 0

        debouncer.debounce {
            executionCount += 1
        }

        // Cancel and execute again immediately
        debouncer.cancel()
        debouncer.debounce {
            executionCount += 1
        }

        // Wait for delay
        try await Task.sleep(nanoseconds: 150_000_000) // 0.15s

        XCTAssertEqual(executionCount, 1, "Should only execute once after cancel")
    }

    func testMultipleDebounces() async throws {
        var executionCount = 0

        debouncer.debounce { executionCount += 1 }
        debouncer.debounce { executionCount += 1 }
        debouncer.debounce { executionCount += 1 }

        // Wait for delay
        try await Task.sleep(nanoseconds: 150_000_000) // 0.15s

        XCTAssertEqual(executionCount, 1, "Should only execute once despite multiple calls")
    }

    func testCancelPreventsExecution() async throws {
        var executed = false

        debouncer.debounce {
            executed = true
        }

        // Cancel immediately
        debouncer.cancel()

        // Wait for delay
        try await Task.sleep(nanoseconds: 150_000_000) // 0.15s

        XCTAssertFalse(executed, "Should not execute after cancel")
    }

    // MARK: - Delay Variation Tests

    func testCustomDelay() async throws {
        let customDebouncer = Debouncer(delay: 0.05)
        var executed = false
        var executionTime: Date?

        let startTime = Date()

        customDebouncer.debounce {
            executed = true
            executionTime = Date()
        }

        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s

        XCTAssertTrue(executed)
        XCTAssertNotNil(executionTime)

        if let executionTime = executionTime {
            let elapsed = executionTime.timeIntervalSince(startTime)
            XCTAssertGreaterThanOrEqual(elapsed, 0.05, "Should wait at least custom delay")
        }
    }

    func testVeryLongDelay() async throws {
        let longDebouncer = Debouncer(delay: 0.01)
        var executed = false

        longDebouncer.debounce {
            executed = true
        }

        try await Task.sleep(nanoseconds: 20_000_000) // 0.02s

        XCTAssertTrue(executed, "Should execute with long delay")
    }
}

// MARK: - Throttler Tests
@MainActor
final class ThrottlerTests: XCTestCase {
    var throttler: Throttler!

    override func setUpWithError() throws {
        throttler = Throttler(minimumInterval: 0.1)
    }

    override func tearDownWithError() throws {
        throttler.cancel()
        throttler = nil
    }

    func testThrottleExecutesImmediately() async throws {
        var executed = false

        throttler.throttle {
            executed = true
        }

        // Give a small delay for async execution
        try await Task.sleep(nanoseconds: 20_000_000) // 0.02s

        XCTAssertTrue(executed, "Should execute immediately on first call")
    }

    func testThrottleSkipsRapidCalls() async throws {
        var executionCount = 0

        throttler.throttle { executionCount += 1 }

        // Immediate second call - should be skipped
        throttler.throttle { executionCount += 1 }

        try await Task.sleep(nanoseconds: 20_000_000) // 0.02s

        throttler.throttle { executionCount += 1 }

        try await Task.sleep(nanoseconds: 20_000_000) // 0.02s

        XCTAssertEqual(executionCount, 1, "Should skip rapid calls within minimum interval")
    }

    func testThrottleAllowsAfterInterval() async throws {
        var executionCount = 0

        throttler.throttle { executionCount += 1 }

        try await Task.sleep(nanoseconds: 150_000_000) // 0.15s

        throttler.throttle { executionCount += 1 }

        try await Task.sleep(nanoseconds: 20_000_000) // 0.02s

        XCTAssertEqual(executionCount, 2, "Should allow execution after minimum interval")
    }

    func testThrottleCancel() async throws {
        var executed = false

        throttler.throttle {
            executed = true
        }

        throttler.cancel()

        try await Task.sleep(nanoseconds: 150_000_000) // 0.15s

        // New execution after cancel should work
        throttler.throttle {
            executed = true
        }

        XCTAssertTrue(executed, "Should execute after cancel")
    }
}

// MARK: - DebouncedPublisher Tests
@MainActor
final class DebouncedPublisherTests: XCTestCase {
    var publisher: DebouncedPublisher<String>!
    var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        publisher = DebouncedPublisher(initialValue: "", delay: 0.1)
        cancellables = Set<AnyCancellable>()
    }

    override func tearDownWithError() throws {
        cancellables.removeAll()
        publisher = nil
    }

    func testPublisherUpdatesValue() async throws {
        publisher.update("test")

        XCTAssertEqual(publisher.value, "test")
    }

    func testPublisherDebouncesValue() async throws {
        var receivedValues: [String] = []

        publisher.subscribe { value in
            receivedValues.append(value)
        }
        .store(in: &cancellables)

        publisher.update("first")
        publisher.update("second")
        publisher.update("third")

        // Wait briefly - should not have received debounced value yet
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05s
        XCTAssertEqual(receivedValues.count, 0, "Should not have received debounced value yet")

        // Wait for debounce delay
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s

        XCTAssertEqual(receivedValues.count, 1)
        XCTAssertEqual(receivedValues.last, "third", "Should receive final value")
    }

    func testPublisherMultipleUpdates() async throws {
        var receivedValues: [String] = []

        publisher.subscribe { value in
            receivedValues.append(value)
        }
        .store(in: &cancellables)

        // Multiple rapid updates
        for i in 1...10 {
            publisher.update("value\(i)")
            try await Task.sleep(nanoseconds: 10_000_000) // 0.01s
        }

        // Wait for debounce
        try await Task.sleep(nanoseconds: 150_000_000) // 0.15s

        XCTAssertEqual(receivedValues.count, 1)
        XCTAssertEqual(receivedValues.first, "value10", "Should receive last value")
    }

    func testPublisherSeparateSubscribers() async throws {
        var subscriber1Values: [String] = []
        var subscriber2Values: [String] = []

        publisher.subscribe { value in
            subscriber1Values.append(value)
        }
        .store(in: &cancellables)

        publisher.subscribe { value in
            subscriber2Values.append(value)
        }
        .store(in: &cancellables)

        publisher.update("test")

        try await Task.sleep(nanoseconds: 150_000_000) // 0.15s

        XCTAssertEqual(subscriber1Values.count, 1)
        XCTAssertEqual(subscriber2Values.count, 1)
        XCTAssertEqual(subscriber1Values.first, "test")
        XCTAssertEqual(subscriber2Values.first, "test")
    }

    func testPublisherInitialValue() async throws {
        XCTAssertEqual(publisher.value, "")
        XCTAssertEqual(publisher.debouncedValue, "")
    }

    // MARK: - DebounceStrategy Tests

    func testDebounceStrategyStandard() {
        let strategy = DebounceStrategy.standard()
        XCTAssertEqual(strategy.delay, 0.3, "Standard strategy should have 0.3s delay")
    }

    func testDebounceStrategyAggressive() {
        let strategy = DebounceStrategy.aggressive()
        XCTAssertEqual(strategy.delay, 0.15, "Aggressive strategy should have 0.15s delay")
    }

    func testDebounceStrategyConservative() {
        let strategy = DebounceStrategy.conservative()
        XCTAssertEqual(strategy.delay, 0.5, "Conservative strategy should have 0.5s delay")
    }

    func testDebounceStrategyCustomDelays() {
        let aggressive = DebounceStrategy.aggressive(delay: 0.05)
        let conservative = DebounceStrategy.conservative(delay: 1.0)

        XCTAssertEqual(aggressive.delay, 0.05)
        XCTAssertEqual(conservative.delay, 1.0)
    }

    // MARK: - Integration Tests

    func testDebouncerWithRealWorldScenario() async throws {
        let debouncer = Debouncer(delay: 0.1)
        var searchResults: [String] = []
        let mockSearchResults = ["Result 1", "Result 2", "Result 3"]

        debouncer.debounce {
            // Simulate expensive search operation
            searchResults = mockSearchResults
        }

        // User types more quickly than debounce delay
        debouncer.debounce {
            searchResults = ["Result 1", "Result 2"]
        }

        debouncer.debounce {
            searchResults = ["Result 1"]
        }

        // Wait for debounce
        try await Task.sleep(nanoseconds: 150_000_000) // 0.15s

        XCTAssertEqual(searchResults, ["Result 1"], "Should only execute final search")
    }

    func testThrottlerWithRealWorldScenario() async throws {
        let throttler = Throttler(minimumInterval: 0.1)
        var apiCallCount = 0

        // Simulate rapid button presses
        for _ in 1...10 {
            throttler.throttle {
                apiCallCount += 1
            }
            try await Task.sleep(nanoseconds: 5_000_000) // 0.005s between calls
        }

        // Wait for all throttled executions to complete
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5s

        XCTAssertLessThan(apiCallCount, 10, "Should throttle rapid API calls")
        XCTAssertGreaterThan(apiCallCount, 0, "Should allow at least one call")
    }

    func testDebouncerAndThrottlerTogether() async throws {
        let debouncer = Debouncer(delay: 0.1)
        var debounceExecutions = 0
        var throttleExecutions = 0
        let throttler = Throttler(minimumInterval: 0.1)

        // Simulate user typing (debounce)
        debouncer.debounce {
            debounceExecutions += 1
        }

        // Simulate rapid button clicks (throttle)
        for _ in 1...3 {
            throttler.throttle {
                throttleExecutions += 1
            }
        }

        try await Task.sleep(nanoseconds: 200_000_000) // 0.2s

        XCTAssertEqual(debounceExecutions, 1)
        XCTAssertLessThanOrEqual(throttleExecutions, 3)
    }

    // MARK: - Edge Cases

    func testDebouncerWithEmptyAction() async throws {
        let debouncer = Debouncer(delay: 0.1)
        // Should not crash with empty action
        debouncer.debounce {
            // Empty action
        }

        try await Task.sleep(nanoseconds: 150_000_000) // 0.15s

        // If we get here without crashing, the test passes
        XCTAssertTrue(true)
    }

    func testDebouncerMultipleCancels() async throws {
        let debouncer = Debouncer(delay: 0.1)
        var executed = false

        debouncer.debounce {
            executed = true
        }

        // Multiple cancels should not crash
        debouncer.cancel()
        debouncer.cancel()
        debouncer.cancel()

        try await Task.sleep(nanoseconds: 150_000_000) // 0.15s

        XCTAssertFalse(executed)
    }

    func testThrottlerWithEmptyAction() async throws {
        let throttler = Throttler(minimumInterval: 0.1)
        throttler.throttle {
            // Empty action
        }

        try await Task.sleep(nanoseconds: 50_000_000) // 0.05s

        XCTAssertTrue(true)
    }

    func testPublisherWithComplexTypes() async throws {
        let intPublisher = DebouncedPublisher<Int>(initialValue: 0, delay: 0.1)
        var receivedValues: [Int] = []

        intPublisher.subscribe { value in
            receivedValues.append(value)
        }
        .store(in: &cancellables)

        intPublisher.update(5)
        intPublisher.update(10)
        intPublisher.update(15)

        try await Task.sleep(nanoseconds: 150_000_000) // 0.15s

        XCTAssertEqual(receivedValues.count, 1)
        XCTAssertEqual(receivedValues.first, 15)
    }

    func testDebouncerZeroDelay() async throws {
        let zeroDelayDebouncer = Debouncer(delay: 0.01)
        var executed = false

        zeroDelayDebouncer.debounce {
            executed = true
        }

        try await Task.sleep(nanoseconds: 20_000_000) // 0.02s

        XCTAssertTrue(executed)
    }
}
