## ADDED Requirements

### Requirement: Admin can configure a single maintenance window
The system SHALL let an admin configure one maintenance start time and one maintenance end time that define a single scheduled maintenance window.

#### Scenario: Admin saves a valid maintenance window
- **WHEN** an admin enables scheduled maintenance and saves both a start time and an end time where the end is after the start
- **THEN** the system stores that maintenance window for future runtime evaluation

#### Scenario: Invalid maintenance window is rejected
- **WHEN** an admin attempts to save a scheduled maintenance window without both timestamps or with an end time that is not after the start
- **THEN** the system refuses to store the invalid maintenance schedule

### Requirement: Maintenance enforcement considers both manual and scheduled state
The system SHALL treat maintenance mode as active when either the manual maintenance control is enabled or the current time falls inside the configured scheduled maintenance window.

#### Scenario: Manual maintenance overrides schedule
- **WHEN** the manual maintenance toggle is enabled
- **THEN** the system blocks normal user access regardless of the scheduled maintenance window

#### Scenario: Scheduled maintenance activates automatically
- **WHEN** the current time enters a saved scheduled maintenance window while the manual toggle is off
- **THEN** the system blocks normal user access without requiring an admin to toggle maintenance manually

#### Scenario: Scheduled maintenance ends automatically
- **WHEN** the current time passes the end of the saved scheduled maintenance window and the manual toggle is off
- **THEN** the system allows normal user access again without manual intervention
