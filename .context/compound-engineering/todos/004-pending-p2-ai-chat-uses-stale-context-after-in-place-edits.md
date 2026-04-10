---
status: pending
priority: p2
issue_id: "004"
tags: [code-review, ai, state-management, correctness]
dependencies: []
---

# Rebuild AI Chat Context When Data Changes In Place

## Problem Statement

The AI chat caches its system prompt and only invalidates that cache when entity counts change. If a person, gift idea, or gift history item is edited in place while the chat is open, the assistant continues reasoning over stale context.

## Findings

- `AIChatView` only invalidates the prompt cache on `people.count`, `giftIdeas.count`, and `giftHistory.count` changes in [`Sources/aiPresentsApp/Views/AI/AIChatView.swift`](/Users/hendrik.grueger/Coding/1_privat/Apple%20Apps/ai-presents-app-ios/Sources/aiPresentsApp/Views/AI/AIChatView.swift#L69).
- `AIChatViewModel` caches the fully rendered prompt and reuses it until invalidated.
- The chat itself mutates gift state in place in [`Sources/aiPresentsApp/ViewModels/AIChatViewModel.swift`](/Users/hendrik.grueger/Coding/1_privat/Apple%20Apps/ai-presents-app-ios/Sources/aiPresentsApp/ViewModels/AIChatViewModel.swift#L485), but never calls `invalidatePromptCache()`.
- The same stale-cache issue applies to renames, relation changes, hobbies edits, or status changes that do not alter collection counts.

## Proposed Solutions

### Option 1: Invalidate on any relevant model mutation

**Approach:** Explicitly call `invalidatePromptCache()` after in-chat mutations and when sheets/actions save edits.

**Pros:**
- Smallest targeted fix
- Keeps current caching strategy

**Cons:**
- Easy to miss future mutation paths
- Requires discipline across multiple save points

**Effort:** 1-3 hours

**Risk:** Medium

---

### Option 2: Derive a cache key from content, not counts

**Approach:** Rebuild the prompt whenever a stable hash/fingerprint of relevant fields changes.

**Pros:**
- More robust against in-place edits
- Reduces hidden invalidation edge cases

**Cons:**
- More code and bookkeeping
- Slightly higher recomputation overhead

**Effort:** 4-6 hours

**Risk:** Low

---

### Option 3: Remove prompt caching

**Approach:** Rebuild the system prompt for every send.

**Pros:**
- Simplest correctness model
- Eliminates invalidation bugs entirely

**Cons:**
- Higher token/computation cost
- May impact responsiveness for large datasets

**Effort:** <1 hour

**Risk:** Low

## Recommended Action

## Technical Details

**Affected files:**
- `Sources/aiPresentsApp/Views/AI/AIChatView.swift`
- `Sources/aiPresentsApp/ViewModels/AIChatViewModel.swift`

**Related components:**
- AI system prompt construction
- Chat action processing
- SwiftData-backed live edits

## Resources

- Prompt invalidation hooks: `Sources/aiPresentsApp/Views/AI/AIChatView.swift`
- Status mutation path: `Sources/aiPresentsApp/ViewModels/AIChatViewModel.swift`

## Acceptance Criteria

- [ ] AI chat reflects status/title/relation/hobby edits made while the sheet is open
- [ ] In-chat actions that mutate data invalidate or rebuild prompt context
- [ ] Repeated follow-up prompts do not use stale gift status or person metadata
- [ ] Regression is covered by a focused test or repeatable manual scenario

## Work Log

### 2026-03-24 - Initial Discovery

**By:** Codex

**Actions:**
- Traced prompt-cache lifecycle from `AIChatView` into `AIChatViewModel`
- Compared cache invalidation triggers against mutation paths handled inside chat

**Learnings:**
- The cache strategy assumes collection-size changes are sufficient, which is false for most edits
- In-place model mutation is common in this app, so stale AI context is a realistic user-facing bug

## Notes

- This is especially risky because the assistant can make planning/status suggestions based on outdated data and appear inconsistent.
