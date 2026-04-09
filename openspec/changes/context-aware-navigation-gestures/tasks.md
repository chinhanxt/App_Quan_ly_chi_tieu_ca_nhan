## 1. Primary Dashboard Swipe Shell

- [x] 1.1 Convert the dashboard body from index swapping to a `PageView` with a managed `PageController`.
- [x] 1.2 Keep bottom navigation taps and page swipes synchronized through one selected-index source of truth.
- [x] 1.3 Preserve primary screen widget instances so shell navigation does not reset in-memory workspace state.

## 2. Transaction Nested Swipe Behavior

- [x] 2.1 Update the transaction section so its inner tabs consume the first horizontal swipe before the dashboard advances.
- [x] 2.2 Allow edge swipes from the outermost transaction tab to continue into the adjacent primary dashboard section.

## 3. Context-Aware Secondary Navigation

- [x] 3.1 Add shared navigation helpers that distinguish primary dashboard switching from contextual secondary pushes.
- [x] 3.2 Replace AI action flows that currently use replacement for reference navigation with contextual pushes or dashboard fallbacks.
- [x] 3.3 Update notification actions to open linked destinations while preserving notifications as the immediate back destination.
- [x] 3.4 Apply route construction for supported secondary screens so iPhone-style edge-swipe back works where the platform supports it.

## 4. Verification

- [x] 4.1 Review the AI-to-budget and AI-to-savings flows to confirm back returns to AI.
- [x] 4.2 Review the notification-to-budget and notification-to-savings flows to confirm back returns to notifications.
- [x] 4.3 Review transaction swipes to confirm the first swipe changes the inner transaction tab and the next edge swipe moves to the adjacent primary section.
- [x] 4.4 Review direct entry fallback behavior to confirm primary destinations still open correctly when no dashboard shell exists.
