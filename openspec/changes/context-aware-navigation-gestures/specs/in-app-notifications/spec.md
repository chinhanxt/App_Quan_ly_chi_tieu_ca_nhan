## MODIFIED Requirements

### Requirement: Notification details gate read state and linked actions
The system SHALL provide a notification detail view that shows the full notification content, marks the notification as read when opened, and exposes the linked destination action only from the detail view. When that linked action opens another screen, the notification detail view SHALL remain the immediate back destination unless no dashboard shell exists and a fallback primary workspace must be created.

#### Scenario: Opening details marks notification as read
- **WHEN** the user opens a notification detail view for an unread notification
- **THEN** the system marks that notification as read and removes its unread indicator from compact views

#### Scenario: Detail view shows full content
- **WHEN** the user is on a notification detail view
- **THEN** the system displays the full notification content and any available action label

#### Scenario: Linked destination opens from detail action
- **WHEN** the user taps the notification action in the detail view
- **THEN** the system navigates to the linked destination associated with that notification

#### Scenario: Back returns to notification detail context
- **WHEN** the user opens a linked destination from the notification detail view and then performs a back action
- **THEN** the app returns to the notification detail context instead of collapsing directly to a primary dashboard section
