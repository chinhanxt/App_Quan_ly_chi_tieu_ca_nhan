## ADDED Requirements

### Requirement: User can disable application-generated notifications
The system SHALL let an authenticated user disable application-generated notifications from user settings without disabling system broadcasts or other admin-originated notifications.

#### Scenario: User turns off app notifications
- **WHEN** the user disables application notifications in settings
- **THEN** the system stores that preference for the user and stops surfacing new application-generated notifications in the app experience

#### Scenario: System broadcasts remain visible
- **WHEN** application notifications are disabled for a user
- **THEN** admin system broadcasts remain eligible to appear in the notification list and heads-up surfaces

### Requirement: Existing application notifications are hidden while the preference is off
The system SHALL hide previously created application-generated notifications from the active in-app notification experience while the user's application-notification preference is disabled.

#### Scenario: Old app notifications disappear after toggle-off
- **WHEN** the user disables application notifications and previously had active application-generated notifications
- **THEN** the notification list no longer shows those application-generated notifications

#### Scenario: Heads-up app notifications are suppressed
- **WHEN** application notifications are disabled for a user
- **THEN** the system does not display heads-up overlays for application-generated notifications

### Requirement: Disabled preference does not delete notification history
The system SHALL preserve stored notification records when application notifications are disabled, even though hidden application-generated notifications are not shown in the active experience.

#### Scenario: Preference hides without destructive mutation
- **WHEN** the user disables application notifications
- **THEN** the system does not require deleting existing application-notification documents in order to hide them from active views
