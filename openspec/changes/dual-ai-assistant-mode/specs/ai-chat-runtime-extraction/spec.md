## ADDED Requirements

### Requirement: App AI screen supports two distinct AI modes
The system SHALL expose two distinct AI modes inside the app AI screen: one for transaction capture and one for assistant support.

#### Scenario: User sees both AI modes when assistant mode is enabled
- **WHEN** the published runtime configuration enables both transaction AI and assistant AI
- **THEN** the app AI screen shows a clear mode switch that lets the user choose between `AI thêm giao dịch` and `AI hỗ trợ`

#### Scenario: Assistant mode stays hidden when disabled by admin
- **WHEN** the published runtime configuration disables assistant AI
- **THEN** the app does not let the user switch into assistant mode

### Requirement: Assistant AI uses a separate runtime contract from transaction AI
The system SHALL route assistant-mode chat through a separate assistant AI contract that is independent from the transaction-card contract.

#### Scenario: Assistant question does not create transaction card
- **WHEN** the user asks a support-style question while assistant mode is active
- **THEN** the system returns a natural assistant response without generating transaction confirmation cards

#### Scenario: Transaction AI continues to use card contract
- **WHEN** the user is in transaction mode and sends a transaction-like request
- **THEN** the system continues to use the transaction AI clarification-or-card contract rather than the assistant reply contract

### Requirement: Assistant AI answers from app and finance context
The system SHALL let assistant AI answer from user-specific application context including current-month finance summaries, budget state, saving-goal state, and app usage guidance.

#### Scenario: User asks about current month spending
- **WHEN** the user asks how much they have spent or earned this month in assistant mode
- **THEN** the system answers using the current-month finance summary available to the app

#### Scenario: User asks how to use a feature
- **WHEN** the user asks how to add a transaction, use budgets, or use savings features in assistant mode
- **THEN** the system answers as an app support assistant instead of forcing transaction parsing

### Requirement: Assistant AI may suggest safe in-app actions
The system SHALL allow assistant AI to return safe action suggestions that help the user navigate or continue a task in the app.

#### Scenario: User asks about budget status
- **WHEN** the user asks about budget usage in assistant mode
- **THEN** the system may suggest a safe action such as opening the budget view in addition to the text reply

#### Scenario: User asks to record a transaction while in assistant mode
- **WHEN** the user asks for transaction entry while assistant mode is active
- **THEN** the system may suggest switching to transaction mode instead of silently creating a transaction card in assistant mode

### Requirement: Assistant action suggestions do not execute user-affecting operations automatically
The system MUST treat assistant-mode actions as user-selectable suggestions rather than autonomous operations.

#### Scenario: Assistant proposes navigation
- **WHEN** the assistant response includes an action suggestion
- **THEN** the app waits for explicit user interaction before navigating or changing screens

#### Scenario: Assistant suggests follow-up work
- **WHEN** the assistant suggests a next step such as opening savings or starting transaction entry
- **THEN** the system does not mutate user data unless the user later performs a separate explicit action
