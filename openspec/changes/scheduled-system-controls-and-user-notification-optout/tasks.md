## 1. User App Notification Preference

- [x] 1.1 Add Firestore-backed user notification preference support and a settings UI control for enabling or disabling application notifications.
- [x] 1.2 Update notification loading, active-list filtering, and heads-up behavior so disabled users no longer see new or existing application-generated notifications.

## 2. Scheduled Maintenance Mode

- [x] 2.1 Extend system app-controls storage and admin web configuration UI to support a single scheduled maintenance start/end window with validation.
- [x] 2.2 Update runtime maintenance checks so access is blocked whenever manual maintenance is on or the current time is inside the configured maintenance window.

## 3. Scheduled System Broadcasts

- [x] 3.1 Extend broadcast storage, admin web create/edit flows, and list rendering to support manual vs scheduled delivery with a single start/end window and validation.
- [x] 3.2 Update broadcast visibility evaluation in the user notification pipeline so scheduled broadcasts appear and expire automatically based on their configured window.

## 4. Verification

- [ ] 4.1 Run targeted verification for settings, maintenance scheduling, and scheduled broadcast behavior; document any limitations found during validation.
