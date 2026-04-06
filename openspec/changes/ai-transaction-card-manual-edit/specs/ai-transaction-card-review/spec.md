## ADDED Requirements

### Requirement: User can manually edit AI-generated transaction draft cards before save
The system SHALL allow the user to open an editor for any unsaved AI-generated transaction draft card and update its title, amount, transaction type, date, category, and note before the draft is saved.

#### Scenario: Edit a parsed draft card
- **WHEN** an AI response contains one or more unsaved transaction draft cards and the user chooses to edit one card
- **THEN** the system opens a draft editor populated with the card's current values
- **THEN** the user can change title, amount, type, date, category, and note
- **THEN** saving the editor updates that card in the AI message draft state

#### Scenario: Edited draft persists in chat history
- **WHEN** the user updates an unsaved AI-generated draft card
- **THEN** the updated card data is persisted with the local AI chat history
- **THEN** reopening the AI screen later restores the edited draft values

#### Scenario: Saved messages cannot be edited as drafts
- **WHEN** an AI message has already been saved to transactions
- **THEN** the system MUST disable or hide draft editing actions for cards in that message

### Requirement: User can delete individual AI-generated transaction draft cards before save
The system SHALL allow the user to remove an individual unsaved AI-generated transaction draft card from an AI response without removing the entire conversation message.

#### Scenario: Delete one card from a multi-card response
- **WHEN** an AI response contains multiple unsaved draft cards and the user deletes one card
- **THEN** only the selected card is removed from the message draft state
- **THEN** the remaining draft cards stay available for review and save

#### Scenario: Delete the last remaining draft card
- **WHEN** an AI response contains a single unsaved draft card and the user deletes it
- **THEN** the message remains in chat history without any draft cards
- **THEN** the system MUST hide or disable the save action for that message

#### Scenario: Saved messages cannot delete draft cards
- **WHEN** an AI message has already been saved to transactions
- **THEN** the system MUST disable or hide draft deletion actions for cards in that message

### Requirement: Batch save uses the latest remaining AI draft cards
The system SHALL save only the current set of unsaved draft cards in a message, including all manual edits and excluding any cards the user removed before confirmation.

#### Scenario: Save after manual edits
- **WHEN** the user edits one or more draft cards and then confirms save for the AI message
- **THEN** the system persists the edited field values for each remaining card
- **THEN** the saved transaction records reflect the final reviewed draft state rather than the original AI output

#### Scenario: Save after deleting some draft cards
- **WHEN** the user removes one or more draft cards from an AI message and then confirms save
- **THEN** the system saves only the remaining draft cards
- **THEN** deleted draft cards are not persisted as transactions

#### Scenario: No save when no cards remain
- **WHEN** all draft cards in an AI message have been removed before save
- **THEN** the system MUST prevent a save action for that message because there are no remaining drafts to persist
