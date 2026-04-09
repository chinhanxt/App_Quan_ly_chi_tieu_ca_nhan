## Why

The app currently shows system broadcasts inline on the home screen, which takes up visual space and weakens the overall polish of the primary experience. The product now needs a safer, more intentional in-app notification model that can surface important updates globally, preserve unread state, and route users into the right destination only after they review the message details.

## What Changes

- Add a global floating notification bell that stays available across app screens and can be repositioned by the user.
- Replace inline home-screen broadcast presentation with short-lived heads-up notifications that slide in from the top-right, remain visible for a few seconds, and slide away automatically.
- Show all admin broadcasts as heads-up notifications.
- Add a compact notification list opened from the floating bell; list items show only short notification titles such as system notices, app notices, and alerts.
- Add a notification detail view that reveals full content, displays unread/read state, and provides the linked action that navigates to the relevant destination.
- Track unread notifications with a green indicator and allow deletion only after a notification has been read.
- Reset day-based reminders safely when a new day begins so stale daily reminders do not persist indefinitely.

## Capabilities

### New Capabilities
- `in-app-notifications`: Global floating notifications, compact notification list, notification details, unread/read lifecycle, deletion rules, deep links, and daily reminder reset behavior.

### Modified Capabilities
- None.

## Impact

- Affected mobile UI shell and global overlay behavior, including the current floating assistive interaction pattern and the existing inline broadcast widget on the home screen.
- Affected Firestore-backed notification/broadcast data handling, including per-user read state, deletion eligibility, and day-bound reminder expiration.
- Affected navigation flows for linked destinations such as budget, savings, transactions, and system detail views.
