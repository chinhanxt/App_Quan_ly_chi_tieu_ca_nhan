## 1. Draft Card Editing

- [x] 1.1 Add a draft transaction editor surface for AI-generated cards that can edit title, amount, type, date, category, and note.
- [x] 1.2 Wire the editor to load values from an unsaved AI draft card and return normalized edited values back to the message transaction list.
- [x] 1.3 Disable or hide draft edit controls for AI messages that have already been saved.

## 2. Draft Card Removal

- [x] 2.1 Add a delete action for each unsaved AI-generated draft card in the AI chat UI.
- [x] 2.2 Remove only the selected draft card from the owning `AIChatMessage.transactions` list and persist the updated chat history immediately.
- [x] 2.3 Hide or disable the message-level save action when a message no longer has any remaining draft cards.

## 3. Save Flow and Validation

- [x] 3.1 Update the AI message save flow to persist the latest edited draft values for all remaining cards.
- [x] 3.2 Ensure deleted draft cards are excluded from batch save and that saved messages remain read-only afterward.
- [x] 3.3 Recheck validation and normalization for edited AI draft fields before writing transactions to Firestore.

## 4. Verification

- [ ] 4.1 Verify that edited draft cards survive AI chat history restore after leaving and reopening the screen.
- [ ] 4.2 Verify single-card and multi-card responses for edit, delete, and save behavior, including deleting the last card in a message.
- [x] 4.3 Run the relevant Flutter analysis or targeted tests for the AI transaction flow and confirm no regressions in existing save behavior.
