## Why

The AI transaction flow can already generate draft transaction cards, but users cannot fully correct a parsed card before saving it. This creates friction when OCR or AI extracts the right intent but misses a field such as title, amount, date, note, or category.

## What Changes

- Add a review flow for AI-generated transaction cards so users can manually edit card details before saving.
- Add a delete action for individual AI-generated draft cards so users can discard incorrect cards without clearing the entire AI response.
- Preserve the existing "confirm and save" batch workflow, but make it operate on the latest edited draft state.
- Keep saved AI responses read-only after persistence to avoid ambiguity between draft edits and stored transactions.

## Capabilities

### New Capabilities
- `ai-transaction-card-review`: Review, edit, and remove AI-generated transaction draft cards before they are saved.

### Modified Capabilities

## Impact

- Affects the AI transaction chat UI in `lib/screens/ai_input_screen.dart`.
- Likely introduces or reuses a draft transaction editor UI based on existing add/edit transaction form patterns.
- Extends in-memory AI message draft state and persistence of chat history in `SharedPreferences`.
- Changes pre-save validation and save behavior for AI-generated draft cards, but does not require Firestore schema changes for stored transactions.
