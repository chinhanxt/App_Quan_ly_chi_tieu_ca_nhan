## ADDED Requirements

### Requirement: Admin can manage AI runtime configuration separately from local parse lexicon
The system SHALL provide a dedicated AI runtime configuration in admin web that is managed separately from the existing local parse lexicon configuration.

#### Scenario: Admin views separate AI runtime config
- **WHEN** an admin opens the AI configuration area in admin web
- **THEN** the system shows a distinct runtime AI configuration section separate from the local lexicon parse section

#### Scenario: Existing local lexicon remains unaffected
- **WHEN** an admin edits runtime AI configuration values
- **THEN** the system does not overwrite or mutate the stored local parse lexicon unless the admin explicitly edits the lexicon section

### Requirement: Admin can draft and publish AI runtime configuration
The system SHALL support draft and published versions for AI runtime configuration so operators can review changes before making them live.

#### Scenario: Admin saves draft runtime config
- **WHEN** an admin edits AI runtime configuration and chooses to save draft
- **THEN** the system stores the edited runtime configuration as a draft without changing the published runtime configuration

#### Scenario: Admin publishes runtime config
- **WHEN** an admin publishes a drafted AI runtime configuration
- **THEN** the system promotes the draft to the active runtime configuration and records the publish metadata

### Requirement: Admin runtime config includes direct AI access settings
The system SHALL let admins manage the active AI mode, provider/model settings, image handling strategy, fallback policy, and API key as part of runtime AI configuration.

#### Scenario: Admin updates runtime settings
- **WHEN** an admin edits AI mode defaults, provider/model, image strategy, fallback policy, or API key
- **THEN** the system stores those settings as part of the AI runtime configuration document

#### Scenario: Admin sees masked key state
- **WHEN** an admin loads an existing AI runtime configuration that already includes an API key
- **THEN** the system indicates that a key exists without forcing the UI to reveal the full stored key by default

### Requirement: Admin can manage a structured four-layer prompt
The system SHALL let admins manage a four-layer prompt made of role definition, task definition, card generation rules, and broad conversation response rules.

#### Scenario: Admin edits prompt as structured layers
- **WHEN** an admin opens the prompt editor for runtime AI configuration
- **THEN** the system presents editable sections for all four prompt layers rather than requiring a single opaque prompt blob only

#### Scenario: Published prompt preserves all layers
- **WHEN** an admin publishes prompt changes
- **THEN** the active runtime AI configuration preserves the content of each prompt layer so the application can reconstruct the effective system prompt

### Requirement: Admin can preview runtime AI behavior before publish
The system SHALL provide a preview workflow for runtime AI configuration that allows operators to inspect how the current draft would behave before publishing it.

#### Scenario: Preview uses draft runtime config
- **WHEN** an admin runs preview from the AI configuration page
- **THEN** the system evaluates the preview against the draft runtime AI configuration rather than the currently published configuration

#### Scenario: Preview does not alter live behavior
- **WHEN** an admin runs preview repeatedly on draft runtime settings
- **THEN** the system does not change the active runtime AI configuration until publish is explicitly requested
