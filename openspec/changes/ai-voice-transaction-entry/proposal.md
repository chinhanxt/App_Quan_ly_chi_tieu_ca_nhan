## Why

The AI screen already supports draft transaction cards, manual correction, and batch save, but it still depends on typed text or image input. Users need a voice-first entry path that feels fast in real use while still being safe when speech recognition is incomplete, merged, or ambiguous.

## What Changes

- Add a voice input flow on the AI screen that captures live speech, shows the recognized transcript in real time, and reuses the existing AI draft card confirmation experience.
- Introduce a unified voice interpretation pipeline that handles both single-intent and multi-intent utterances in one feature instead of separate modes.
- Create safety rules so the app only generates draft transaction cards when the recognized content is sufficiently complete and confident.
- Add an ambiguity-handling path that presents recommendations, candidate interpretations, and editable draft data when the transcript is partially understood but not safe to auto-confirm.
- Keep voice-generated results inside the current AI draft layer so users can review, edit, delete, and save with the same contract already used for typed AI cards.

## Capabilities

### New Capabilities
- `ai-voice-transaction-entry`: Capture spoken transaction input on the AI screen, interpret it into safe draft cards, and guide the user through clarification or recommendation flows when the transcript is ambiguous.

### Modified Capabilities

## Impact

- Affects the AI chat UI in `lib/screens/ai_input_screen.dart`.
- Likely adds a speech capture adapter and a voice interpretation layer alongside `lib/services/ai_service.dart` and existing transaction parsing helpers.
- Extends local AI message state and persistence to include voice transcript, recommendation metadata, or other draft-only review context.
- Requires microphone permission handling and UX for permission denial, active listening, stopping, and retrying.
- Reuses the existing AI draft card edit and save flow without requiring Firestore schema changes for persisted transactions.
