---
status: pending
priority: p2
issue_id: "003"
tags: [code-review, product, monetization, app-intents]
dependencies: []
---

# Remove Monetization Drift Between UI and Shortcuts

## Problem Statement

The app UI currently grants full access to everyone for the v1 launch, but the Siri shortcut for adding gift ideas still enforces a 14-day trial or purchased entitlement. After the trial expires, users can keep adding ideas in-app but receive an upgrade wall in Shortcuts.

## Findings

- The source of truth in [`Sources/aiPresentsApp/Services/SubscriptionManager.swift`](/Users/hendrik.grueger/Coding/1_privat/Apple%20Apps/ai-presents-app-ios/Sources/aiPresentsApp/Services/SubscriptionManager.swift#L57) explicitly hardcodes `hasFullAccess` to `true` for the free launch.
- The same manager still starts a trial clock on first launch in [`Sources/aiPresentsApp/Services/SubscriptionManager.swift`](/Users/hendrik.grueger/Coding/1_privat/Apple%20Apps/ai-presents-app-ios/Sources/aiPresentsApp/Services/SubscriptionManager.swift#L71).
- `AddGiftIdeaIntent.perform()` rejects the shortcut unless `isTrialActive()` or a StoreKit entitlement is present in [`Sources/aiPresentsApp/Intents/AddGiftIdeaIntent.swift`](/Users/hendrik.grueger/Coding/1_privat/Apple%20Apps/ai-presents-app-ios/Sources/aiPresentsApp/Intents/AddGiftIdeaIntent.swift#L22).
- That means the shortcut path diverges from the user-visible app contract once the 14-day window has elapsed.

## Proposed Solutions

### Option 1: Reuse the app's free-launch access rule

**Approach:** Make the intent gate delegate to the same access policy used by `SubscriptionManager`.

**Pros:**
- Restores consistent product behavior
- Minimal code churn

**Cons:**
- Requires exposing a shared access-check helper usable from intents

**Effort:** 1-2 hours

**Risk:** Low

---

### Option 2: Temporarily remove the intent gate

**Approach:** Skip access checks in `AddGiftIdeaIntent` until monetization is actually activated.

**Pros:**
- Fastest fix
- Matches current launch reality

**Cons:**
- Another place to revisit when monetization goes live

**Effort:** <1 hour

**Risk:** Low

---

### Option 3: Turn monetization back on everywhere

**Approach:** Remove the free-launch override and enforce the same policy in UI and shortcuts.

**Pros:**
- Single consistent rule
- Closer to planned subscription behavior

**Cons:**
- Changes the shipped product contract
- High business/product impact

**Effort:** 1 day+

**Risk:** High

## Recommended Action

## Technical Details

**Affected files:**
- `Sources/aiPresentsApp/Services/SubscriptionManager.swift`
- `Sources/aiPresentsApp/Intents/AddGiftIdeaIntent.swift`

**Related components:**
- StoreKit 2 entitlement checks
- Trial lifecycle
- Siri / App Shortcut UX

## Resources

- Shortcut intent: `Sources/aiPresentsApp/Intents/AddGiftIdeaIntent.swift`
- Access policy: `Sources/aiPresentsApp/Services/SubscriptionManager.swift`

## Acceptance Criteria

- [ ] Shortcut access matches the app’s visible access policy
- [ ] No free-launch user is blocked in Shortcuts while the UI remains unlocked
- [ ] Monetization behavior is defined in one shared place
- [ ] Regression is covered by tests or a manual verification checklist

## Work Log

### 2026-03-24 - Initial Discovery

**By:** Codex

**Actions:**
- Compared `SubscriptionManager.hasFullAccess` with `AddGiftIdeaIntent.hasFullAccess()`
- Traced trial initialization and shortcut gating behavior

**Learnings:**
- The current shortcut access policy is stricter than the app policy
- Product-rule duplication has already drifted

## Notes

- This is a user-facing inconsistency, not just cleanup debt.
