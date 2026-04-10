---
status: pending
priority: p1
issue_id: "002"
tags: [code-review, app-intents, swiftdata, data-integrity, architecture]
dependencies: []
---

# Align App Intents with the App's SwiftData Store

## Problem Statement

The Siri/App Shortcuts layer builds its own `ModelContainer` with a different configuration than the main app. That can make intents query or mutate a different store than the one the user sees in the app, causing "contact not found" failures or invisible writes.

## Findings

- The main app creates its container with a named configuration and conditional CloudKit mode in [`Sources/aiPresentsApp/aiPresentsApp.swift`](/Users/hendrik.grueger/Coding/1_privat/Apple%20Apps/ai-presents-app-ios/Sources/aiPresentsApp/aiPresentsApp.swift#L18).
- The intents always create a fresh container with unnamed configuration and `cloudKitDatabase: .none` in [`Sources/aiPresentsApp/Intents/PersonEntity.swift`](/Users/hendrik.grueger/Coding/1_privat/Apple%20Apps/ai-presents-app-ios/Sources/aiPresentsApp/Intents/PersonEntity.swift#L40).
- All three intents depend on that helper:
  - entity lookup in [`Sources/aiPresentsApp/Intents/PersonEntity.swift`](/Users/hendrik.grueger/Coding/1_privat/Apple%20Apps/ai-presents-app-ios/Sources/aiPresentsApp/Intents/PersonEntity.swift#L60)
  - write path in [`Sources/aiPresentsApp/Intents/AddGiftIdeaIntent.swift`](/Users/hendrik.grueger/Coding/1_privat/Apple%20Apps/ai-presents-app-ios/Sources/aiPresentsApp/Intents/AddGiftIdeaIntent.swift#L27)
  - read path in [`Sources/aiPresentsApp/Intents/UpcomingBirthdaysIntent.swift`](/Users/hendrik.grueger/Coding/1_privat/Apple%20Apps/ai-presents-app-ios/Sources/aiPresentsApp/Intents/UpcomingBirthdaysIntent.swift#L16)
- The design spec explicitly calls for a shared factory with the same configuration as the app in [`docs/superpowers/specs/2026-03-14-siri-integration-design.md`](/Users/hendrik.grueger/Coding/1_privat/Apple%20Apps/ai-presents-app-ios/docs/superpowers/specs/2026-03-14-siri-integration-design.md#L130).

## Proposed Solutions

### Option 1: Centralize container creation

**Approach:** Extract a single shared container factory used by both app startup and App Intents, including the same store name and iCloud/local mode selection.

**Pros:**
- Eliminates config drift at the source
- Keeps intent reads/writes aligned with app behavior

**Cons:**
- Requires careful handling of intent-process constraints
- May need explicit decisions around CloudKit vs local fallback

**Effort:** 2-4 hours

**Risk:** Medium

---

### Option 2: Use an app-group-backed intent store contract

**Approach:** If direct parity is not viable, explicitly move App Intents onto an app-group/shared-store strategy and make the app use that same store.

**Pros:**
- Clear multi-process data-sharing model
- Easier to reason about than accidental default-store behavior

**Cons:**
- More invasive migration work
- Requires data migration/testing

**Effort:** 1-2 days

**Risk:** Medium

---

### Option 3: Downgrade intents to read-only until storage parity is fixed

**Approach:** Temporarily disable write intents like `AddGiftIdeaIntent` and limit shortcuts to safe actions.

**Pros:**
- Reduces data inconsistency risk quickly
- Smaller immediate patch

**Cons:**
- Feature regression for Siri/Shortcuts
- Leaves architecture debt in place

**Effort:** 1-2 hours

**Risk:** Low

## Recommended Action

## Technical Details

**Affected files:**
- `Sources/aiPresentsApp/aiPresentsApp.swift`
- `Sources/aiPresentsApp/Intents/PersonEntity.swift`
- `Sources/aiPresentsApp/Intents/AddGiftIdeaIntent.swift`
- `Sources/aiPresentsApp/Intents/UpcomingBirthdaysIntent.swift`

**Related components:**
- SwiftData persistence
- CloudKit/local fallback behavior
- Siri / Shortcuts entity resolution

## Resources

- Siri design spec: `docs/superpowers/specs/2026-03-14-siri-integration-design.md`

## Acceptance Criteria

- [ ] App Intents and the app use the same storage configuration contract
- [ ] Shortcuts can resolve contacts that exist in the main app store
- [ ] Writes performed via `AddGiftIdeaIntent` are visible in the app without store mismatch
- [ ] Behavior is covered by an automated or manual regression test plan

## Work Log

### 2026-03-24 - Initial Discovery

**By:** Codex

**Actions:**
- Compared app startup container creation with App Intent container creation
- Traced all intent paths using `makeIntentsModelContainer()`
- Cross-checked against the Siri integration design document

**Learnings:**
- The current implementation does not follow the documented “same config as app” requirement
- Multi-process features are especially sensitive to silent store-configuration drift

## Notes

- This is user-visible in production because it affects Siri/Shortcuts behavior, not just tests.
