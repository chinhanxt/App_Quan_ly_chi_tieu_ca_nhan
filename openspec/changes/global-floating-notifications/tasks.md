## 1. Notification Data Foundation

- [x] 1.1 Define the mobile notification record shape for category title, detail content, unread state, delete eligibility, route target, and optional daily reminder metadata.
- [x] 1.2 Add data access logic for loading the current user's notifications and distinguishing active daily reminders from expired ones.
- [x] 1.3 Map admin broadcasts into persistent user-facing notification records without marking them as read when heads-up display completes.
- [x] 1.4 Add helper logic for determining whether a notification can be deleted and whether a linked destination action is available.

## 2. Global Overlay Experience

- [x] 2.1 Add a global notification overlay host at the app-shell level so the floating bell and heads-up toasts are available across authenticated screens.
- [x] 2.2 Build the draggable floating bell with bounded movement and an unread indicator.
- [x] 2.3 Implement top-right heads-up toast presentation with one-line content, timed dismissal, and sequential queue handling.
- [x] 2.4 Remove or replace the current inline home-screen broadcast display with the new global heads-up behavior.

## 3. Review and Detail Flow

- [x] 3.1 Build the compact notification list opened from the floating bell using short normalized titles and unread indicators only.
- [x] 3.2 Build the notification detail view that displays full content and marks the notification as read when opened.
- [x] 3.3 Add the detail-view action that deep-links to supported destinations such as budget, savings, or transaction entry.
- [x] 3.4 Enforce the rule that unread notifications cannot be deleted and read notifications can be deleted.

## 4. Daily Reminder Lifecycle

- [x] 4.1 Identify which app-generated notifications are day-scoped reminders and assign effective-date metadata to them.
- [x] 4.2 Add day-rollover logic that expires previous-day reminders without resetting broadcast or non-daily notification state.
- [x] 4.3 Ensure new reminders can be generated for the new day only when their triggering conditions still apply.

## 5. Verification

- [x] 5.1 Verify heads-up notifications queue correctly and do not overlap when multiple admin broadcasts arrive.
- [x] 5.2 Verify opening detail marks notifications as read, updates unread indicators, and unlocks deletion.
- [x] 5.3 Verify linked actions navigate only from the detail view and not from toast timeout or compact-list preview.
- [x] 5.4 Verify previous-day reminders no longer appear as active after local day rollover while non-daily notifications remain unchanged.
