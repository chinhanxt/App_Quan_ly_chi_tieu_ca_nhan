## ADDED Requirements

### Requirement: Admin runtime config manages transaction AI and assistant AI separately
The system SHALL let admins manage transaction AI and assistant AI as separate runtime configurations inside the AI configuration area.

#### Scenario: Admin sees separate runtime sections
- **WHEN** an admin opens the AI configuration area
- **THEN** the system presents separate management surfaces for `AI thêm giao dịch` and `AI hỗ trợ`

#### Scenario: Assistant AI can be disabled independently
- **WHEN** an admin disables assistant AI while leaving transaction AI enabled
- **THEN** the published runtime configuration keeps transaction AI available and hides assistant AI from the app

### Requirement: Admin AI config UI is organized into three tabs
The system SHALL organize the admin AI configuration area into separate tabs for transaction AI, assistant AI, and parse/local AI behavior.

#### Scenario: Admin opens AI config page
- **WHEN** the admin navigates to the AI configuration page
- **THEN** the page shows tabs for `AI thêm giao dịch`, `AI hỗ trợ`, and `AI parse`

#### Scenario: Parse settings remain isolated
- **WHEN** an admin edits assistant AI settings
- **THEN** the system does not overwrite parse/local AI settings unless the admin edits the parse tab explicitly

### Requirement: Assistant AI runtime config supports independent model, key, prompt, and preview
The system SHALL let admins configure assistant AI with its own enabled state, provider/model, API key, prompt content, restore-default behavior, draft save, publish, and preview workflow.

#### Scenario: Admin edits assistant AI draft config
- **WHEN** an admin changes assistant AI prompt or model settings and saves draft
- **THEN** the system stores the assistant AI draft without mutating the published transaction AI runtime config

#### Scenario: Admin previews assistant AI behavior
- **WHEN** an admin runs preview from the assistant AI tab
- **THEN** the system previews behavior using the assistant AI draft configuration rather than the currently published transaction AI settings

### Requirement: Runtime config remains backward compatible during rollout
The system SHALL preserve compatibility with environments that only have the older single-runtime AI configuration until admins explicitly publish the new dual-AI configuration.

#### Scenario: Existing runtime config is still present
- **WHEN** the system loads an environment that only has the legacy runtime AI document shape
- **THEN** the admin UI and app derive a safe default where transaction AI continues to work and assistant AI remains disabled until configured

#### Scenario: Rollback disables assistant AI only
- **WHEN** an admin rolls back by turning off assistant AI in published config
- **THEN** the app stops exposing assistant mode without disrupting the existing transaction AI mode
