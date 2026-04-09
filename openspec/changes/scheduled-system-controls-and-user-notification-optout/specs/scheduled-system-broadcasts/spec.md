## ADDED Requirements

### Requirement: Admin can configure a single scheduled visibility window per broadcast
The system SHALL let an admin define one start time and one end time for a system broadcast so the message can be shown automatically during that period.

#### Scenario: Admin saves scheduled broadcast window
- **WHEN** an admin saves a broadcast with scheduled delivery and valid start/end timestamps
- **THEN** the system stores that scheduled visibility window on the broadcast record

#### Scenario: Invalid scheduled broadcast window is rejected
- **WHEN** an admin enables scheduled delivery for a broadcast without both timestamps or with an end time that is not after the start
- **THEN** the system refuses to store that invalid schedule

### Requirement: Broadcast visibility is evaluated from configured delivery mode
The system SHALL determine whether a broadcast is visible from its configured delivery mode and scheduling fields rather than requiring manual activation at the exact publish time.

#### Scenario: Manual broadcast keeps current behavior
- **WHEN** a broadcast uses manual delivery mode
- **THEN** the system uses its stored active or inactive status to decide whether the broadcast is visible

#### Scenario: Scheduled broadcast becomes visible automatically
- **WHEN** the current time enters a broadcast's scheduled visibility window
- **THEN** the system treats that broadcast as visible to users without requiring manual activation

#### Scenario: Scheduled broadcast expires automatically
- **WHEN** the current time passes the end of a broadcast's scheduled visibility window
- **THEN** the system stops treating that broadcast as visible without requiring manual deactivation
