## Context

The current AI transaction flow in `lib/screens/ai_input_screen.dart` already supports draft transaction cards inside each AI chat message. Those cards can be lightly adjusted in place for some fields such as transaction type and fallback category selection, and the entire message can then be persisted with a single "confirm and save" action.

This change extends that draft model rather than introducing a second persistence layer. Users need a way to correct AI-parsed cards before save when the parse is mostly correct but not fully trustworthy. The codebase already contains add/edit transaction forms that define the expected fields and validation model for a transaction, which makes them a useful reference for a dedicated AI draft editor.

Constraints:
- AI chat history is persisted locally, so draft edits must survive app restarts until the user clears the conversation.
- Firestore transactions are only created during the final save step; draft cards do not exist as server records yet.
- The current saved state is tracked at the message level, so draft actions must remain disabled after a message has been saved.

## Goals / Non-Goals

**Goals:**
- Allow users to manually edit all important fields of an AI-generated transaction draft before saving.
- Allow users to delete an individual AI-generated draft card before saving.
- Keep the existing batch save model, but save the edited list of remaining cards.
- Preserve chat history and draft state consistently after edit and delete actions.

**Non-Goals:**
- Editing transactions that were already saved to Firestore from the AI chat timeline.
- Introducing a new Firestore draft collection or syncing draft cards to the backend before save.
- Redesigning the broader AI conversation model or changing AI parsing behavior.

## Decisions

Use the existing `AIChatMessage.transactions` list as the single source of truth for editable draft cards.
Rationale: the screen already reads, updates, restores, and saves this structure. Extending the current draft state keeps the implementation local to the AI flow and avoids draft/server divergence.
Alternative considered: introduce a separate draft transaction model or local database table. Rejected because it adds conversion overhead and extra persistence complexity for a narrow UI enhancement.

Introduce a dedicated edit action per draft card that opens a focused editor surface rather than expanding all fields inline.
Rationale: inline editing would make each AI card visually heavy and complicate the chat layout. A focused dialog or bottom sheet can reuse the existing transaction form pattern and contain validation more cleanly.
Alternative considered: fully inline editable cards. Rejected because it increases card height, makes multi-card AI responses noisy, and adds more stateful widgets to the chat list.

Treat delete as removal of an unsaved draft card only.
Rationale: before save, cards are draft-only objects with no server identity, so removal is simple and predictable. After save, the current UI should remain read-only to avoid mixing draft lifecycle and persisted transaction lifecycle in one component.
Alternative considered: allow deleting already-saved cards directly from chat. Rejected for this change because the message model does not retain per-card Firestore IDs and would require a new persisted linkage model.

Keep message-level save semantics, but make the save action operate on the current post-edit, post-delete transaction list.
Rationale: this preserves the existing user mental model and existing summary update flow while still supporting per-card correction.
Alternative considered: add a save button per card. Rejected because the current implementation and success messaging are built around batch save, and per-card persistence would complicate summary reconciliation and status tracking.

Hide or disable save affordances when a message no longer contains any draft cards.
Rationale: once all cards are deleted, there is nothing left to persist. The chat message itself can remain as conversational history without showing invalid save actions.

## Risks / Trade-offs

[Editor duplication] -> Reusing the existing edit transaction form directly may require adaptation because AI draft cards do not yet have Firestore IDs or persisted summary fields. Mitigation: extract or create a draft-focused editor that works on in-memory maps and only returns edited values.

[State drift in history restore] -> If edit/delete actions are not persisted immediately, the restored chat can show stale draft cards after restart. Mitigation: persist chat history after every successful draft mutation.

[Message-level saved flag] -> A single `isSaved` flag can make card-level action handling brittle if not consistently checked. Mitigation: gate edit and delete actions behind the same unsaved condition used by other interactive controls.

[Validation inconsistencies] -> AI-generated drafts may contain malformed values that differ from manual form assumptions. Mitigation: normalize edited output before writing back to the message and reuse existing transaction field validation patterns.

## Migration Plan

No datastore migration is required because draft cards remain local until saved and saved transaction documents keep the existing schema.

Rollout can happen in one release:
1. Add card-level edit and delete actions for unsaved AI draft cards.
2. Persist edited draft state in local chat history.
3. Save only the remaining draft cards in the current message when the user confirms.

Rollback is straightforward: remove the edit/delete UI and continue using the existing AI draft save flow.

## Open Questions

- Should the draft editor be a dialog for consistency with the existing add/edit forms, or a bottom sheet for a more mobile-native review experience?
- When a user deletes the last card in a message, should the AI bubble show a small “all draft cards removed” hint, or should it simply keep the text response without extra status copy?
