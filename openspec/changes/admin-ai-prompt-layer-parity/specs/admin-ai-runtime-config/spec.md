## MODIFIED Requirements

### Requirement: Admin runtime config must expose full editable prompt parity for runtime AIs

Admin web MUST expose editable prompt layers that match the full prompt library used by each runtime AI.

#### Scenario: Transaction AI shows full prompt parity

- **WHEN** operator opens the `AI thêm giao dịch` tab
- **THEN** the admin UI shows six editable prompt layers
- **AND** the prompt library also shows exactly six prompts
- **AND** each library prompt corresponds to one editable layer

#### Scenario: Assistant AI shows full prompt parity

- **WHEN** operator opens the `AI hỗ trợ` tab
- **THEN** the admin UI shows eight editable prompt layers
- **AND** the prompt library also shows exactly eight prompts
- **AND** each library prompt corresponds to one editable layer

### Requirement: Prompt library must reflect draft editor state immediately

The prompt library and compiled prompt preview MUST update from the current draft editor state without waiting for publish.

#### Scenario: Draft edit updates prompt library immediately

- **WHEN** operator changes any prompt layer value in admin web
- **THEN** the corresponding prompt in the prompt library updates immediately on screen
- **AND** the compiled final prompt preview updates in the same draft session

### Requirement: Published runtime config must continue to drive realtime app behavior

App runtime MUST continue reading published runtime config so prompt changes only affect users after publish.

#### Scenario: App receives new prompt after publish

- **WHEN** operator publishes updated runtime config from admin web
- **THEN** the published runtime config document changes
- **AND** app clients listening to runtime config receive the updated prompt-related fields through the existing realtime config flow

### Requirement: AI parse must remain a separate lexicon/rule workflow

The local parse tab MUST remain a lexicon/rule editor and MUST NOT be presented as prompt-layer governance.

#### Scenario: Parse tab stays separate

- **WHEN** operator opens the `AI parse` tab
- **THEN** the UI presents lexicon/rule editing, preview, and system file views
- **AND** it does not present prompt library parity controls for runtime AI layers
