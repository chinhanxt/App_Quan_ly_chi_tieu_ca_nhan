## MODIFIED Requirements

### Requirement: Runtime prompt assembly must include every editable layer

Application-side prompt assembly MUST include all editable layers defined in runtime config for each AI mode.

#### Scenario: Transaction AI compiled prompt uses all six layers

- **WHEN** app builds the system prompt for transaction AI
- **THEN** the compiled prompt includes all six configured layers in deterministic order

#### Scenario: Assistant AI compiled prompt uses all eight layers

- **WHEN** app builds the system prompt for assistant AI
- **THEN** the compiled prompt includes all eight configured layers in deterministic order

### Requirement: Realtime runtime updates must preserve prompt behavior consistency

Prompt assembly MUST remain consistent when published runtime config changes in realtime.

#### Scenario: Published config swap changes effective prompt

- **WHEN** published runtime config changes while app is listening to runtime config
- **THEN** the next effective prompt assembly uses the updated published layers
- **AND** the app does not require a code redeploy to pick up the new prompt content
