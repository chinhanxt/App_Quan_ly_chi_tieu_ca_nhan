## Why

User settings currently cannot disable application-generated notifications, and admin operations for maintenance mode and system broadcasts still depend on manual toggles. The product now needs time-bounded automation so users can silence app reminders cleanly and admins can preconfigure system state changes without having to be online at the exact start or end time.

## What Changes

- Add a user-facing preference that disables application notifications only, including hiding existing application notifications from the in-app notification UI while leaving system broadcasts visible.
- Add admin-configurable maintenance scheduling with a single start and end window in addition to the existing manual maintenance toggle.
- Add admin-configurable scheduled activation windows for system broadcasts so a prepared message can automatically appear and disappear without manual toggling.
- Evaluate maintenance and broadcast effective state from stored schedule timestamps instead of requiring a background job to flip stored booleans at runtime.

## Capabilities

### New Capabilities
- `user-app-notification-preferences`: User control over whether application-generated notifications are shown or delivered in the app experience.
- `scheduled-maintenance-mode`: Admin-configured maintenance windows with automatic enforcement during a defined start/end range.
- `scheduled-system-broadcasts`: Admin-configured start/end windows that automatically control broadcast visibility.

### Modified Capabilities
- None.

## Impact

- Affected user settings UI and user profile persistence in Firestore.
- Affected notification-loading, heads-up display, and notification-list filtering in the mobile app.
- Affected admin web system configuration and broadcast management screens.
- Affected maintenance access checks in authentication and app-gate flows.
