import XCTest
@testable import aiPresentsApp

actor ExecutionTracker {
    private var count = 0
    private var lastExecution: Date?

    func record() {
        count += 1
        lastExecution = Date()
    }

    func snapshot() -> (count: Int, lastExecution: Date?) {
        (count, lastExecution)
    }
}

final class DebouncerTests: XCTestCase {
    @MainActor
    func testDebounceExecutesAfterDelay() async throws {
        let debouncer = Debouncer(delay: 0.1)
        let tracker = ExecutionTracker()

        debouncer.debounce {
            Task {
                await tracker.record()
            }
        }

        try await Task.sleep(nanoseconds: 50_000_000)
        let midSnapshot = await tracker.snapshot()
        XCTAssertEqual(midSnapshot.count, 0)

        try await Task.sleep(nanoseconds: 100_000_000)
        let finalSnapshot = await tracker.snapshot()
        XCTAssertEqual(finalSnapshot.count, 1)
        XCTAssertNotNil(finalSnapshot.lastExecution)
    }

    @MainActor
    func testDebounceCancelsPreviousAction() async throws {
        let debouncer = Debouncer(delay: 0.1)
        let tracker = ExecutionTracker()

        debouncer.debounce {
            Task {
                await tracker.record()
            }
        }

        debouncer.debounce {
            Task {
                await tracker.record()
            }
        }

        debouncer.debounce {
            Task {
                await tracker.record()
            }
        }

        try await Task.sleep(nanoseconds: 150_000_000)
        let snapshot = await tracker.snapshot()
        XCTAssertEqual(snapshot.count, 1)
    }

    @MainActor
    func testCancelPreventsExecution() async throws {
        let debouncer = Debouncer(delay: 0.1)
        let tracker = ExecutionTracker()

        debouncer.debounce {
            Task {
                await tracker.record()
            }
        }
        debouncer.cancel()

        try await Task.sleep(nanoseconds: 150_000_000)
        let snapshot = await tracker.snapshot()
        XCTAssertEqual(snapshot.count, 0)
    }

    @MainActor
    func testCustomDelayWaitsAtLeastConfiguredInterval() async throws {
        let debouncer = Debouncer(delay: 0.05)
        let tracker = ExecutionTracker()
        let start = Date()

        debouncer.debounce {
            Task {
                await tracker.record()
            }
        }

        try await Task.sleep(nanoseconds: 100_000_000)

        let snapshot = await tracker.snapshot()
        let executionTime = try XCTUnwrap(snapshot.lastExecution)
        XCTAssertGreaterThanOrEqual(executionTime.timeIntervalSince(start), 0.05)
    }

    @MainActor
    func testMultipleCancelsAreSafe() async throws {
        let debouncer = Debouncer(delay: 0.1)
        let tracker = ExecutionTracker()

        debouncer.debounce {
            Task {
                await tracker.record()
            }
        }

        debouncer.cancel()
        debouncer.cancel()
        debouncer.cancel()

        try await Task.sleep(nanoseconds: 150_000_000)
        let snapshot = await tracker.snapshot()
        XCTAssertEqual(snapshot.count, 0)
    }
}
