## ADDED Requirements

### Requirement: Global floating notification access
The mobile application SHALL provide a floating notification bell that remains available across app screens for authenticated users, can be repositioned by the user, and indicates when unread notifications exist.

#### Scenario: Floating bell is available globally
- **WHEN** an authenticated user navigates between supported app screens
- **THEN** the notification bell remains available without being tied to a single screen layout

#### Scenario: Floating bell can be repositioned
- **WHEN** the user drags the floating notification bell
- **THEN** the bell moves smoothly and remains constrained within the visible app bounds

#### Scenario: Unread indicator appears on bell
- **WHEN** at least one notification is unread
- **THEN** the floating notification bell displays a green unread indicator

### Requirement: Heads-up notifications surface new events
The system SHALL present newly eligible notifications as short heads-up overlays in the top-right area of the app, one at a time, for a limited duration before sliding away.

#### Scenario: Admin broadcast appears as heads-up notification
- **WHEN** an active admin broadcast becomes available to the user
- **THEN** the system shows a one-line heads-up notification near the top-right of the app before removing it automatically after a short delay

#### Scenario: Multiple notifications are queued
- **WHEN** more than one new notification becomes eligible while another heads-up notification is visible
- **THEN** the system queues later notifications and presents them sequentially instead of overlapping them

#### Scenario: Heads-up timeout does not mark as read
- **WHEN** a heads-up notification disappears because its display time ends
- **THEN** the underlying notification remains unread until the user opens its detail view

### Requirement: Compact notification list shows short titles only
The system SHALL provide a compact notification list from the floating bell that shows notifications using short category-style titles and unread indicators without exposing full message bodies in the list.

#### Scenario: Compact list shows normalized title
- **WHEN** the user opens the compact notification list
- **THEN** each item displays a short title such as system notice, app notice, or budget alert rather than the full notification body

#### Scenario: Compact list shows unread state
- **WHEN** a notification in the compact list has not been read
- **THEN** that item displays a green unread indicator

#### Scenario: Compact list hides full content
- **WHEN** the user views the compact notification list
- **THEN** the system does not show the full detailed content of each notification in that list

### Requirement: Notification details gate read state and linked actions
The system SHALL provide a notification detail view that shows the full notification content, marks the notification as read when opened, and exposes the linked destination action only from the detail view.

#### Scenario: Opening details marks notification as read
- **WHEN** the user opens a notification detail view for an unread notification
- **THEN** the system marks that notification as read and removes its unread indicator from compact views

#### Scenario: Detail view shows full content
- **WHEN** the user is on a notification detail view
- **THEN** the system displays the full notification content and any available action label

#### Scenario: Linked destination opens from detail action
- **WHEN** the user taps the notification action in the detail view
- **THEN** the system navigates to the linked destination associated with that notification

### Requirement: Notifications can only be deleted after they are read
The system SHALL prevent users from deleting unread notifications and SHALL allow deletion only after the notification has been marked as read.

#### Scenario: Unread notification cannot be deleted
- **WHEN** the user attempts to delete a notification that has not been read
- **THEN** the system refuses the deletion and keeps the notification available

#### Scenario: Read notification can be deleted
- **WHEN** the user deletes a notification that has already been marked as read
- **THEN** the system removes that notification from the user's available notification list

### Requirement: Daily reminders reset on a new day
The system SHALL expire or replace reminders that are scoped to a specific day when a new local day begins, without resetting unrelated notifications.

#### Scenario: Previous-day reminder no longer remains active
- **WHEN** the local day changes and a daily reminder belongs to the previous day
- **THEN** the system no longer treats that reminder as an active current-day reminder

#### Scenario: New-day reminder can be created
- **WHEN** the local day changes and the reminder condition is still true for the new day
- **THEN** the system may create a new reminder record for the new day

#### Scenario: Broadcast notifications do not reset with daily reminders
- **WHEN** the local day changes
- **THEN** admin broadcasts and other non-daily notifications keep their existing read state and lifecycle
