## Context

The current dashboard swaps its body directly from a selected index, which supports taps on the bottom navigation bar but provides no swipe gesture between primary sections. The transaction screen already contains an inner `TabBarView`, so any primary swipe implementation must respect that nested horizontal gesture and only move to another primary section after the transaction tab edge is reached.

Secondary screens such as AI, search, savings, notifications, and detail screens are mostly opened with ad hoc `MaterialPageRoute` pushes, while some AI actions use `pushReplacement` to jump into a primary section. That replacement behavior breaks the natural back destination the user expects when opening budget or savings from AI or notifications. The app needs a consistent distinction between:
- primary section changes inside the dashboard shell, and
- secondary overlays pushed on top of the current workspace.

## Goals / Non-Goals

**Goals:**
- Add swipe navigation to the primary dashboard shell while keeping the bottom navigation state synchronized.
- Preserve transaction-screen nested swipe behavior so transaction sub-tabs consume the first horizontal swipe before the dashboard shell changes pages.
- Introduce a single navigation helper policy for secondary screens that preserves the originating screen in the back stack.
- Support iPhone-style edge-swipe back on pushed secondary routes without changing the meaning of primary tab switches.
- Remove context-breaking route replacement from AI and notification-linked actions when the user is only referencing another screen temporarily.

**Non-Goals:**
- Redesign the visual appearance of the bottom navigation bar.
- Add deep-link infrastructure for every screen in the app.
- Rewrite every existing route in the project to Cupertino widgets.
- Change the business logic inside budget, savings, AI, or notification features beyond their navigation semantics.

## Decisions

### 1. Convert the dashboard shell to a managed `PageView`
The dashboard will own a `PageController` and render its five primary destinations in a `PageView`. Bottom-nav taps will animate the page controller, and `onPageChanged` will update the selected index.

Why:
- It creates one source of truth for both tap and swipe primary navigation.
- It preserves each primary screen instance instead of rebuilding solely from index assignment.
- It gives a direct place to coordinate nested swipe behavior with the transaction screen.

Alternative considered:
- Wrapping each body swap in ad hoc slide animations. Rejected because it would animate taps but not create real gesture-driven page movement.

### 2. Treat transaction inner tabs as the first horizontal swipe consumer
The transaction screen will expose or manage its own tab controller so that:
- swipe within the screen first moves `Thu Nhập <-> Chi Tiêu`,
- only after the inner tab reaches its edge can the parent dashboard page continue to the adjacent primary section.

Why:
- It matches the intended “swipe twice” interaction.
- It prevents accidental exits from the transaction workspace when the user only wants the sibling transaction tab.

Alternative considered:
- Disabling parent swipe entirely while on the transaction screen. Rejected because it removes the requested shell gesture model.

### 3. Separate primary tab switching from secondary screen pushes
Primary sections remain inside the dashboard shell and should never be opened as stacked overlays during normal use. Secondary screens, including AI, notifications, search, savings, and notification actions, must use push-style navigation so back returns to the originating workspace.

Why:
- It preserves the mental model that bottom tabs are peer workspaces, while AI and notifications are temporary overlays.
- It solves the ambiguity of “back to where?” by honoring the actual source screen when present.

Alternative considered:
- Reusing `Dashboard(initialIndex: ...)` for all destination jumps. Rejected because it discards the source context and makes back behavior unpredictable.

### 4. Add a shared navigation helper for primary-section jumps vs contextual pushes
A small shared helper in the app navigation layer will provide separate APIs such as:
- switch to dashboard index inside the current shell,
- push a secondary screen with platform-appropriate route behavior,
- open a primary section from outside the shell only when no dashboard context exists.

Why:
- It reduces future drift between AI, notifications, and assistive-touch entry points.
- It gives one place to encode fallback behavior for cold-start or out-of-shell navigation.

Alternative considered:
- Leaving navigation decisions inline in each screen. Rejected because the project already shows divergence (`push`, `pushReplacement`, and direct dashboard reconstruction).

### 5. Use platform-appropriate pushed routes for edge-swipe back
Secondary screens that should support iPhone-style interactive back will be pushed with a route that preserves that behavior on iOS while keeping compatible Material behavior elsewhere.

Why:
- It delivers the requested gesture without changing the app’s primary shell semantics.
- It keeps the back gesture attached to stack pop, not tab switching.

Alternative considered:
- Implementing a custom drag detector for back on every screen. Rejected because it is fragile and duplicates route-system behavior.

## Risks / Trade-offs

- [Nested horizontal gestures may conflict between dashboard and transaction tabs] -> Keep the coordination localized to the transaction page boundary and verify edge-only propagation behavior.
- [Replacing route replacements with pushes may expose stale intermediate screens] -> Only convert flows that are contextual references, and keep true workflow exits on explicit replacement if still needed.
- [Primary section state retention may increase memory pressure slightly] -> Limit the shell to five existing screens and reuse their current stateful widgets instead of duplicating them.
- [Mixed iOS and Material route behavior can feel inconsistent if applied unevenly] -> Centralize secondary route creation in one helper and use it everywhere practical.

## Migration Plan

1. Add the dashboard page controller and synchronize bottom-nav taps with page swipes.
2. Coordinate transaction nested swipe behavior so the first swipe stays inside transaction tabs and edge swipes can advance the dashboard shell.
3. Introduce shared navigation helpers that distinguish primary section switches from contextual secondary pushes.
4. Update AI, notifications, and related entry points to use contextual pushes instead of replacement when the user should be able to return.
5. Apply the shared push route to secondary screens that need iPhone-style edge back.
6. If regressions appear, fall back by disabling parent shell swipe while preserving the new contextual push policy.

## Open Questions

- Whether the transaction screen should expose explicit shell callbacks or manage edge transfer purely through controller state observation.
- Whether any secondary screen besides AI, notifications, search, and savings should intentionally remain on `pushReplacement` because it truly ends the previous workflow.
