## ADDED Requirements

### Requirement: Admin can configure application reminder policies
The system SHALL provide admin-managed reminder policies for supported application reminder types and SHALL allow each policy to be enabled or disabled independently from system broadcasts.

#### Scenario: Admin enables a reminder policy
- **WHEN** an admin enables a supported reminder policy
- **THEN** the system stores that policy as active for future scheduled evaluation

#### Scenario: Admin disables a reminder policy
- **WHEN** an admin disables a supported reminder policy
- **THEN** the system stops creating new reminder deliveries from that policy until it is enabled again

#### Scenario: Reminder policies are typed
- **WHEN** an admin configures reminder scheduling
- **THEN** the system only allows supported reminder types such as daily transaction reminder and daily savings reminder rather than arbitrary custom rule definitions

### Requirement: Admin can define one or more daily send times per reminder policy
The system SHALL allow each enabled application reminder policy to define one or more daily send times that determine when the policy is eligible for scheduled evaluation.

#### Scenario: Admin configures multiple send times
- **WHEN** an admin saves a reminder policy with daily send times such as `10:00` and `22:00`
- **THEN** the system stores both send windows for that reminder policy

#### Scenario: Disabled policies do not use configured times
- **WHEN** a reminder policy has configured send times but is disabled
- **THEN** the system does not create reminder deliveries for those times

#### Scenario: Policy update changes future windows only
- **WHEN** an admin changes the configured send times for a reminder policy
- **THEN** the system uses the new times for future scheduled evaluations without rewriting already-created reminder deliveries

### Requirement: Scheduled reminder evaluation SHALL target only eligible users
The system SHALL evaluate each due reminder policy at its configured send windows and SHALL create reminder deliveries only for users who still satisfy the policy's eligibility conditions at that time.

#### Scenario: Transaction reminder targets users with no transaction today
- **WHEN** the daily transaction reminder policy reaches a configured send window
- **THEN** the system creates reminder deliveries only for users who do not have a transaction recorded for the current effective day

#### Scenario: Savings reminder targets users with active goals and no contribution today
- **WHEN** the daily savings reminder policy reaches a configured send window
- **THEN** the system creates reminder deliveries only for users who have at least one active savings goal and no savings contribution recorded for the current effective day

#### Scenario: Ineligible user is skipped
- **WHEN** a user no longer satisfies the condition for a reminder policy at a scheduled send window
- **THEN** the system does not create a reminder delivery for that user at that window

### Requirement: Daily suppression SHALL block later sends for the same reminder type on the same day
The system SHALL respect a user's "Khong nhac lai hom nay" choice by suppressing additional deliveries for that reminder type for the rest of the same effective day.

#### Scenario: Suppressed user is skipped for later window
- **WHEN** a user suppresses the daily transaction reminder after the morning send window
- **THEN** the system does not create that reminder again for the same user during later transaction-reminder windows on the same day

#### Scenario: Suppression does not affect other reminder types
- **WHEN** a user suppresses one reminder type for the day
- **THEN** the system may still create a different reminder type if that user is eligible for it

#### Scenario: Suppression resets on a new day
- **WHEN** a new effective day begins
- **THEN** the previous day's suppression state no longer blocks reminder creation for the new day

### Requirement: Reminder deliveries SHALL be deduplicated per user and scheduled window
The system SHALL prevent duplicate reminder deliveries for the same user, reminder type, effective day, and configured send window even if scheduled jobs retry or overlap.

#### Scenario: Retry does not duplicate same window delivery
- **WHEN** the scheduler processes the same reminder window more than once
- **THEN** the system creates at most one reminder delivery for each user and reminder type for that window

#### Scenario: Different windows can both create reminders
- **WHEN** a reminder policy has both `10:00` and `22:00` configured and the user remains eligible for both windows
- **THEN** the system may create one delivery for the morning window and one delivery for the evening window on the same day

#### Scenario: Delivery records preserve dedupe context
- **WHEN** the system creates a reminder delivery
- **THEN** that delivery stores enough scheduling context to distinguish it from deliveries for other windows or other days

### Requirement: Scheduled reminders SHALL write to the user's notification feed
The system SHALL create or update durable per-user notification records for scheduled application reminders so the in-app notification page can reflect reminder history and state consistently.

#### Scenario: Scheduled reminder appears in notification feed
- **WHEN** the scheduler creates a reminder delivery for an eligible user
- **THEN** the user's notification feed contains a corresponding application reminder record

#### Scenario: Feed remains authoritative for in-app review
- **WHEN** the user opens the in-app notification page after a scheduled reminder is created
- **THEN** the application reads the reminder from the user's notification feed rather than depending on a transient scheduler event

#### Scenario: Disabled policy stops future feed entries
- **WHEN** an admin disables a reminder policy
- **THEN** the system does not create new notification-feed entries from that policy after the disable takes effect
