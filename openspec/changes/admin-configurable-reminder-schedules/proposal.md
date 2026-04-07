## Why

Application reminders are currently driven by client-side timing and hardcoded behavior, which makes reminder delivery inconsistent, difficult to operate, and hard to evolve into a long-term notification platform. The product now needs an admin-controlled scheduling model so reminder timing can be adjusted safely without app releases and delivered only to users who still meet each reminder condition.

## What Changes

- Add an admin-managed reminder policy model for application notifications such as "chua nhap giao dich hom nay" and "chua nap tiet kiem hom nay".
- Allow admins to enable or disable each reminder type and configure one or more daily send times instead of relying on hardcoded client timing.
- Introduce a scheduled reminder evaluation flow that runs from backend-controlled schedules, determines which users are eligible at each configured send time, and creates reminder deliveries for those users.
- Preserve the existing "Khong nhac lai hom nay" behavior so a user who suppresses a reminder is skipped for the rest of that day.
- Keep system broadcasts on their existing proactive admin-controlled path while separating application reminders into policy-driven scheduling and delivery.
- Establish a deduped reminder-delivery model so the same reminder type is not sent multiple times to the same user for the same scheduled window.

## Capabilities

### New Capabilities
- `scheduled-app-reminders`: Admin-configured reminder policies, scheduled eligibility evaluation, per-user daily suppression, deduped reminder delivery windows, and reminder-feed generation for application notifications.

### Modified Capabilities
- None.

## Impact

- Affected admin configuration surfaces and Firestore-backed system configuration for reminder policies and send windows.
- Affected notification generation flow, which moves reminder timing authority from the client into backend-controlled schedules and delivery logic.
- Affected per-user notification records, suppression tracking, and delivery deduplication for daily reminder types.
- Likely affected dependencies and services for scheduled jobs, delivery orchestration, and future push-notification integration.
