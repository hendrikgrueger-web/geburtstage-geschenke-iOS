---
status: pending
priority: p1
issue_id: "001"
tags: [code-review, testing, ci, swift]
dependencies: []
---

# Restore a Buildable Test Target

## Problem Statement

The `aiPresentsAppTests` target does not compile, so the project currently has no reliable automated verification path. This blocks meaningful CI/test execution and hides regressions in the app and widget code.

## Findings

- `xcodebuild -project ai-presents-app-ios.xcodeproj -scheme aiPresentsApp -destination 'platform=iOS Simulator,OS=26.2,name=iPhone 16 Pro' build-for-testing` exits with code `65`.
- The immediate compile errors come from stale test references to `Throttler` and `DebouncedPublisher`, which no longer exist in [`Sources/aiPresentsApp/Utilities/Debouncer.swift`](/Users/hendrik.grueger/Coding/1_privat/Apple%20Apps/ai-presents-app-ios/Sources/aiPresentsApp/Utilities/Debouncer.swift#L1) but are still instantiated in [`Tests/aiPresentsAppTests/DebouncerTests.swift`](/Users/hendrik.grueger/Coding/1_privat/Apple%20Apps/ai-presents-app-ios/Tests/aiPresentsAppTests/DebouncerTests.swift#L129) and [`Tests/aiPresentsAppTests/DebouncerTests.swift`](/Users/hendrik.grueger/Coding/1_privat/Apple%20Apps/ai-presents-app-ios/Tests/aiPresentsAppTests/DebouncerTests.swift#L207).
- A second stale test suite remains wired into the test target: [`Tests/aiPresentsAppTests/BirthdayWidgetDataTests.swift`](/Users/hendrik.grueger/Coding/1_privat/Apple%20Apps/ai-presents-app-ios/Tests/aiPresentsAppTests/BirthdayWidgetDataTests.swift#L50) still targets `BirthdayWidgetData`, even though `BirthdayWidgetData.swift` was deleted in commit `e38eaa2` and no such source file is present anymore.
- The project still includes that dead suite in the test target via [`ai-presents-app-ios.xcodeproj/project.pbxproj`](/Users/hendrik.grueger/Coding/1_privat/Apple%20Apps/ai-presents-app-ios/ai-presents-app-ios.xcodeproj/project.pbxproj#L100) and [`ai-presents-app-ios.xcodeproj/project.pbxproj`](/Users/hendrik.grueger/Coding/1_privat/Apple%20Apps/ai-presents-app-ios/ai-presents-app-ios.xcodeproj/project.pbxproj#L325).

## Proposed Solutions

### Option 1: Remove orphaned tests

**Approach:** Delete or exclude the `Throttler`/`DebouncedPublisher` tests and the obsolete `BirthdayWidgetDataTests` suite.

**Pros:**
- Fastest way to get the test target compiling again
- Matches the current production code surface

**Cons:**
- Reduces coverage unless replacement tests are added
- Can hide whether removed utilities should actually still exist

**Effort:** 1-2 hours

**Risk:** Low

---

### Option 2: Reintroduce matching production/test seams

**Approach:** Bring back the removed utility types or replace them with current equivalents, then update tests to the new APIs.

**Pros:**
- Preserves intended utility behavior coverage
- Keeps historical test intent alive

**Cons:**
- Risks reintroducing unnecessary API surface
- More refactor work than the codebase likely needs

**Effort:** 3-5 hours

**Risk:** Medium

---

### Option 3: Replace with lean current-state tests

**Approach:** Rewrite the failing suites around the current `Debouncer`, widget snapshot pipeline, and any still-supported utility APIs.

**Pros:**
- Restores confidence with tests that reflect today’s architecture
- Avoids carrying dead abstractions forward

**Cons:**
- More work than simple deletion
- Requires clear ownership of widget behavior and utility contracts

**Effort:** 4-6 hours

**Risk:** Low

## Recommended Action

## Technical Details

**Affected files:**
- `Sources/aiPresentsApp/Utilities/Debouncer.swift`
- `Tests/aiPresentsAppTests/DebouncerTests.swift`
- `Tests/aiPresentsAppTests/BirthdayWidgetDataTests.swift`
- `ai-presents-app-ios.xcodeproj/project.pbxproj`

**Related components:**
- XCTest target bootstrap
- Widget data preparation tests
- CI / local simulator verification

## Resources

- Build command: `xcodebuild -project ai-presents-app-ios.xcodeproj -scheme aiPresentsApp -destination 'platform=iOS Simulator,OS=26.2,name=iPhone 16 Pro' build-for-testing`
- Cleanup commit: `e38eaa2`

## Acceptance Criteria

- [ ] `aiPresentsAppTests` compiles successfully with `xcodebuild ... build-for-testing`
- [ ] No test file references removed production types
- [ ] Widget-related tests either target live code or are removed from the target
- [ ] CI/local verification path is documented and runnable

## Work Log

### 2026-03-24 - Initial Discovery

**By:** Codex

**Actions:**
- Ran `xcodebuild ... build-for-testing` against the iOS simulator target
- Confirmed compile-time failures from stale test references
- Cross-checked git history and project file entries for deleted utility/test mismatches

**Learnings:**
- The test target is currently broken before any runtime tests can execute
- At least two utility-oriented suites have drifted from the production code

## Notes

- This is a release/merge blocker because it disables automated validation for the repo.
