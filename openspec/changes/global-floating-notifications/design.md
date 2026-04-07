## Context

The current mobile app renders active system broadcasts inline on the home screen, which couples announcement display to a single page and reduces visual quality. The app already has a global floating interaction pattern via the existing assistive touch widget, which makes a global floating notification bell a natural extension, but it also means notification behavior must be coordinated at the app-shell layer instead of inside individual screens.

This change introduces a unified in-app notification flow that covers:
- admin broadcasts that must always surface as heads-up notifications,
- application-generated alerts and reminders such as budget warnings and missing daily actions,
- per-user read state, deletion eligibility, and day-based reminder reset behavior,
- linked navigation that only occurs after the user has entered the detail view and explicitly chooses the action.

The design must be safe and low-friction for implementation in an existing Flutter + Firestore app. It should minimize surprise navigation, prevent unread notifications from being discarded, and avoid stale daily reminders carrying over to the next day.

## Goals / Non-Goals

**Goals:**
- Provide a floating bell that is available across app screens and can be repositioned without leaving the current screen.
- Surface new notifications as short heads-up overlays in the top-right area, one at a time, with queueing to avoid overlap.
- Preserve a compact review surface that shows only high-level notification titles and unread state.
- Require users to open the detail view before a notification can be treated as read or navigated to its linked destination.
- Support safe day rollover for daily reminders so outdated reminders expire and new-day reminders can be generated cleanly.
- Replace the current inline home broadcast presentation with the global notification model.

**Non-Goals:**
- Push notifications outside the app or OS-level notification integration.
- Rich multi-line inbox cards in the compact list.
- Automatic navigation directly from the heads-up overlay without user review.
- Resetting all notifications to unread at the start of each day.
- A desktop/admin redesign beyond data fields needed to support notification content and routing.

## Decisions

### 1. Use a global overlay host instead of screen-local banners
The notification bell and heads-up toasts will live at the top app layer, similar to the current global floating assistive widget, so they remain visible across screens and do not depend on `HomeScreen`.

Why:
- This removes the current home-only coupling.
- It supports a truly global floating bell and toast queue.
- It keeps notifications from occupying layout space inside feature screens.

Alternative considered:
- Reusing the inline home widget and only adding a detail page. Rejected because it does not satisfy the global bell requirement and leaves the current visual problem in place.

### 2. Separate heads-up display from persistent notification records
Every surfaced notification will be represented as a persistent user-facing notification record, while the heads-up toast is only a temporary presentation of a newly eligible record.

Why:
- Read/unread, delete-after-read, and day rollover all require durable state.
- Admin broadcasts must appear for each user even after the temporary toast disappears.
- A persistent record makes compact list and detail views deterministic.

Alternative considered:
- Treating broadcasts as transient UI events only. Rejected because the user would lose the ability to review details, track unread state, or enforce delete-after-read.

### 3. Model unread/read state explicitly per notification
Notifications will remain unread until the user opens the detail view. Compact list items will show a green unread indicator. Deletion is only permitted after read state exists.

Why:
- This prevents a toast timeout from incorrectly marking a notification as consumed.
- It gives a clear, auditable rule for deletion.
- It aligns with the requested UX that detail is the review step before action.

Alternative considered:
- Marking as read when the toast is shown or when the compact list is opened. Rejected because it weakens the unread contract and can hide important alerts too early.

### 4. Compact list items show category-style titles, not full content
The compact list opened from the bell will display short normalized titles such as `Thong bao tu he thong`, `Thong bao tu ung dung`, or `Canh bao ngan sach`. Full content appears only in the detail view.

Why:
- This keeps the list visually lightweight.
- It creates a consistent information hierarchy: signal first, details second, action third.
- It avoids long admin-entered text overflowing the quick-access surface.

Alternative considered:
- Showing full content snippets in the compact list. Rejected because it recreates the visual density the change is intended to remove.

### 5. Linked navigation happens only from the detail view CTA
Opening a list item will show notification details and mark the item as read. Navigation to linked destinations such as budget or savings will occur only when the user taps the detail action.

Why:
- This avoids surprise route changes.
- It ensures the user has context before leaving the notification flow.
- It keeps detail view semantics consistent across notification types.

Alternative considered:
- Deep-linking immediately from the toast or list item tap. Rejected because it is less safe and conflicts with the explicit review step.

### 6. Reset only daily reminders on day rollover
Day rollover behavior will apply only to reminders that are scoped to a specific day, such as "today has no transaction yet" or "today has no savings contribution yet." Admin broadcasts and non-daily alerts keep their original lifecycle.

Why:
- Daily reminders become stale by definition after midnight.
- Broadcasts and persistent alerts should not unexpectedly lose read state.
- This keeps reset logic targeted and predictable.

Alternative considered:
- Resetting unread state for all notifications every day. Rejected because it would re-open old system notices and create noise.

### 7. Queue heads-up toasts and present one at a time
Multiple notifications arriving together will be queued and shown sequentially in the top-right heads-up region.

Why:
- Prevents overlap and visual chaos.
- Guarantees all admin broadcasts can still surface without covering one another.
- Simplifies animation and interaction behavior.

Alternative considered:
- Showing multiple stacked toasts simultaneously. Rejected because it is harder to read, harder to dismiss cleanly, and more likely to obscure app content.

## Risks / Trade-offs

- [Two global floating controls may compete for attention] -> Coordinate default placement and movement boundaries with the existing assistive touch widget, or consolidate later if needed.
- [Per-user notification persistence adds data-model complexity] -> Keep the first version focused on fields needed for state, category title, detail content, route target, and expiry metadata only.
- [Admin broadcasts may be too noisy if all are heads-up] -> Use queueing plus short one-line toast presentation so mandatory surfacing does not monopolize the screen.
- [Daily reset logic can be error-prone around local date boundaries] -> Base rollover on the app's local date handling for the signed-in user and store the effective date on daily reminders.
- [Unread-only deletion rules may frustrate users who want quick cleanup] -> Offset this by marking as read as soon as detail opens and keeping the compact list lightweight.

## Migration Plan

1. Introduce the notification data model and overlay host without removing existing routing behavior elsewhere.
2. Wire admin broadcasts and app-generated alerts into persistent notification records.
3. Replace the inline home broadcast widget with the global heads-up presentation.
4. Enable compact list, detail screen, read state, and delete-after-read enforcement.
5. Add day-rollover handling for daily reminders and verify stale reminders expire instead of accumulating.
6. If rollout issues appear, fall back temporarily to reading notifications without showing heads-up overlays while preserving the stored records.

## Open Questions

- Whether the floating bell should coexist permanently with the current assistive touch control or eventually replace part of its role.
- Whether unread count should appear as a numeric badge or only as a green dot on the bell.
- Whether admin tooling should expose explicit route target fields immediately or infer routes from notification type in the first implementation.
