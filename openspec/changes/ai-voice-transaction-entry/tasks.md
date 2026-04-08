## 1. Voice Capture Foundation

- [x] 1.1 Add a speech capture adapter/service for the AI screen with start, stop, transcript update, and error callbacks
- [x] 1.2 Implement microphone permission handling and recovery UX for denied or blocked states
- [x] 1.3 Add AI screen mic controls and a visible listening state with live transcript rendering

## 2. Voice Interpretation Pipeline

- [x] 2.1 Define draft-only result models for voice transcript state, intent mode, ambiguity reasons, recommendation options, and editable draft seeds
- [x] 2.2 Implement a unified interpreter that classifies transcripts as single, multi, or uncertain and reuses existing transaction segmentation and parsing helpers where appropriate
- [x] 2.3 Add confidence and completeness gating so only safe voice interpretations become ready draft cards
- [x] 2.4 Implement structured ambiguity output for candidate interpretations, partial field preservation, and retry/clarification paths

## 3. AI Draft Integration

- [x] 3.1 Integrate voice interpretation results into the existing AI message contract without breaking typed or image-driven flows
- [x] 3.2 Add recommendation and clarification presentation on the AI timeline with a fast path into draft edit actions
- [x] 3.3 Persist voice draft metadata in local AI history and restore it correctly across app restart
- [x] 3.4 Ensure save behavior persists only finalized transaction fields and does not leak voice-only metadata into stored transactions

## 4. Verification

- [x] 4.1 Add interpreter tests covering clear single-intent, clear multi-intent, and ambiguous utterance cases
- [x] 4.2 Add UI or widget coverage for listening state, permission denial, and recommendation-to-edit recovery flow
- [ ] 4.3 Run regression checks for existing AI draft card review and save behavior after voice integration
