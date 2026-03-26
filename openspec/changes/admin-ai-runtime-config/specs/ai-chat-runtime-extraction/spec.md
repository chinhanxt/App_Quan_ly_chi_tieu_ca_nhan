## ADDED Requirements

### Requirement: AI mode routes extraction behavior through runtime configuration
The system SHALL use the published AI runtime configuration to determine whether AI mode is enabled and how runtime extraction behavior should operate.

#### Scenario: AI mode is disabled
- **WHEN** the published runtime configuration marks AI mode as disabled
- **THEN** the application does not attempt to use the real AI runtime path for message understanding

#### Scenario: AI mode is enabled
- **WHEN** the published runtime configuration marks AI mode as enabled
- **THEN** the application uses the runtime AI path and its published prompt/model settings to process supported AI interactions

### Requirement: AI mode must ask for missing financial fields before returning confirmation cards
When AI mode is active, the system SHALL return a clarification response instead of a confirmation card whenever the user intent is financial but required transaction data is still missing.

#### Scenario: Missing amount
- **WHEN** the user describes a financial transaction without a usable amount
- **THEN** the system asks the user to provide the amount and does not return a confirmation card yet

#### Scenario: Missing category or unresolved category creation
- **WHEN** the user describes a financial transaction but the category is absent, ambiguous, or a new category name is not yet clear enough
- **THEN** the system asks a follow-up question for the missing category detail and does not return a confirmation card yet

### Requirement: AI mode returns confirmation cards only for sufficiently complete transactions
When AI mode is active, the system SHALL return confirmation cards only after the AI has enough information to construct a transaction that is ready for user confirmation and save.

#### Scenario: Complete transaction request
- **WHEN** the user provides a transaction with sufficient details for type, amount, category, and usable date context
- **THEN** the system returns one or more confirmation cards that the user can review and save

#### Scenario: Multiple transactions in one message
- **WHEN** the user provides multiple sufficiently complete financial transactions in one message
- **THEN** the system returns separate confirmation cards for each parsed transaction

### Requirement: AI mode supports conversational responses outside direct transaction capture
When AI mode is active, the system SHALL support broad conversational understanding and natural responses for messages that are not yet ready to become transaction cards.

#### Scenario: User asks a finance-related question
- **WHEN** the user asks for clarification, categorization help, or financial interpretation instead of directly recording a transaction
- **THEN** the system responds in natural language without forcing a confirmation card

#### Scenario: User sends an out-of-scope or non-transaction message
- **WHEN** the user sends a message that is not a transaction capture request
- **THEN** the system replies naturally and avoids fabricating transaction cards

### Requirement: Runtime AI prompt follows a four-layer contract
The system SHALL build the effective AI prompt from four semantic layers: role, task, card-generation rules, and broad conversation response rules.

#### Scenario: Runtime prompt is reconstructed consistently
- **WHEN** the application loads published runtime AI configuration
- **THEN** it can reconstruct a stable effective prompt using the four configured layers in a deterministic order

#### Scenario: Operators change one layer without rewriting all behavior
- **WHEN** an admin edits only one prompt layer
- **THEN** the system preserves the other prompt layers unchanged in the effective runtime prompt

### Requirement: Image-based AI flow follows the same confirmation contract as text
When AI mode is active, the system SHALL apply the same clarification-or-card contract to image-driven inputs as it does to text-driven inputs.

#### Scenario: Image input produces complete transaction data
- **WHEN** an image-derived interaction yields enough transaction data after OCR or AI interpretation
- **THEN** the system returns confirmation card output using the same save flow as text interactions

#### Scenario: Image input is incomplete
- **WHEN** an image-derived interaction does not yield enough trustworthy transaction data
- **THEN** the system asks the user for the missing or uncertain fields instead of generating a premature confirmation card
