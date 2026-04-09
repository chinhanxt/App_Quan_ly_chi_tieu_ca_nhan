## Why

The mobile app currently treats bottom-tab navigation, in-screen tab swipes, and pushed secondary screens as unrelated flows. As the project nears completion, navigation needs a consistent gesture model so users can swipe across primary sections without losing the correct back destination for AI, notifications, search, savings, and similar secondary screens.

## What Changes

- Add horizontal swipe navigation across the five primary dashboard sections while keeping the bottom navigation bar in sync.
- Preserve nested swipe behavior in the transaction area so users move between its inner tabs before leaving the transaction section.
- Introduce a context-aware secondary navigation policy so pushed screens such as AI, notifications, search, and savings keep their back destination based on where they were opened from.
- Standardize iPhone-style edge-swipe back behavior for supported secondary screens without converting primary tab switches into stacked routes.
- Replace context-breaking route replacements in navigation actions that should preserve the previous screen for back navigation.

## Capabilities

### New Capabilities
- `primary-dashboard-gesture-navigation`: Swipe-based navigation across the five primary dashboard destinations with nested transaction-tab behavior.
- `context-aware-secondary-navigation`: Context-preserving push navigation and edge-swipe back behavior for secondary screens opened from AI, notifications, search, assistive actions, and similar entry points.

### Modified Capabilities
- `in-app-notifications`: Notification-linked actions must preserve the notification screen as the back destination instead of collapsing into a primary tab switch.

## Impact

- Affected code includes the dashboard shell, bottom navigation widget, transaction tab experience, AI action routing, notification routing, and shared navigation helpers.
- No new backend dependency is required, but route construction and screen entry semantics will change across several mobile screens.
- Existing flows that use `pushReplacement` for convenience may need to move to explicit push or tab-switch helpers to preserve back-stack behavior.
