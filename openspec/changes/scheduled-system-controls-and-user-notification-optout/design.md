## Context

The current app generates reminder-style application notifications on the client and renders them alongside admin broadcasts. User settings do not persist notification preferences, `app_controls` only stores a manual `maintenanceMode` flag, and `system_broadcasts` only stores a manual `status`. The requested change spans user-facing notification behavior, admin web configuration, and shared runtime logic that determines whether maintenance mode or broadcasts are currently effective.

## Goals / Non-Goals

**Goals:**
- Persist a per-user setting that disables application notifications while keeping system broadcasts available.
- Hide already-created application notifications from the active notification experience as soon as the user disables that preference.
- Let admins configure a single maintenance start/end window without needing a recurring schedule engine.
- Let admins configure a single start/end window per broadcast so prepared announcements activate automatically.
- Reuse timestamp-based effective-state evaluation in the client instead of introducing a backend cron dependency.

**Non-Goals:**
- Do not add repeating schedules, weekly recurrence, or multiple windows per maintenance setting or broadcast.
- Do not delete historical notification documents when a user disables app notifications.
- Do not migrate application reminders to backend scheduling as part of this change.
- Do not redesign the full settings or admin information architecture beyond the controls needed for this feature.

## Decisions

### Persist notification preference on the user document
Store the new preference under the user profile document so it is available immediately to notification services and settings UI without adding a separate collection. The preference will be modeled as a boolean flag nested under notification preferences, defaulting to enabled when absent.

Alternative considered: storing the flag locally in shared preferences. Rejected because the user asked for application behavior, not device-only behavior, and the notification service already depends on authenticated Firestore-backed state.

### Hide application notifications by filtering, not deleting
When app notifications are disabled, existing application-generated notification documents remain in Firestore but are excluded from the active list and heads-up pipeline. This satisfies the requirement to hide old app notifications immediately while avoiding destructive writes or irreversible history loss.

Alternative considered: soft-deleting existing app notifications on toggle-off. Rejected because it mutates history and complicates re-enable behavior.

### Compute effective maintenance state from manual and scheduled controls
`app_controls` will support both manual override and one start/end schedule window. Runtime checks treat maintenance as active when either the manual toggle is on or the current time falls within an enabled schedule window.

Alternative considered: flipping `maintenanceMode` automatically at start/end timestamps. Rejected because that would require reliable scheduled infrastructure and introduce drift/recovery concerns.

### Compute effective broadcast visibility from delivery mode and optional time window
Broadcast documents will keep their stored `status` for manual broadcasts while scheduled broadcasts derive active visibility from `autoStartAt` and `autoEndAt`. Admin lists and user notification syncing will evaluate the same effective-state helper so the UI and delivery path stay consistent.

Alternative considered: background workers that rewrite `status` at the schedule boundaries. Rejected for the same operational reasons as maintenance scheduling.

## Risks / Trade-offs

- [Risk] Scheduled state is evaluated on clients, so incorrect device clocks could shift visibility. -> Mitigation: use Firestore timestamps for stored values, keep logic simple, and rely on normal online sync; this is acceptable for the current app architecture.
- [Risk] Filtering hidden app notifications instead of deleting them means re-enabling could expose old active items if the logic is not careful. -> Mitigation: keep filtering tied to the current preference and continue day-based expiry for reminder-style notifications.
- [Risk] Adding schedule fields to broadcast records changes admin forms and list rendering in multiple places. -> Mitigation: centralize effective-state helpers in repository/page code and keep the data model additive so older documents still work.
- [Risk] Maintenance schedule fields could be partially filled, producing ambiguous behavior. -> Mitigation: validate that enabled schedules require both start and end timestamps and that end is after start before saving.

## Migration Plan

- Additive Firestore schema only: absent preference fields default to app notifications enabled, absent schedule fields default to manual-only behavior.
- Deploy app/admin changes without data backfill.
- If rollback is needed, the new fields can be ignored by older clients because the existing manual flags remain intact.

## Open Questions

- None for the currently approved scope.
