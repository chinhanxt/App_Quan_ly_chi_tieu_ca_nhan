## ADDED Requirements

### Requirement: AI screen SHALL support live voice capture for transaction entry
The system SHALL allow users to start and stop microphone capture from the AI screen and SHALL display the recognized transcript as it is being received so the user can observe what the device heard.

#### Scenario: Live transcript is shown while listening
- **WHEN** the user starts voice input from the AI screen and speech recognition returns transcript updates
- **THEN** the screen shows the recognized transcript in a visible listening state before any transaction card is confirmed

#### Scenario: Microphone permission is denied
- **WHEN** the user starts voice input and microphone permission is denied, blocked, or unavailable
- **THEN** the system does not enter listening mode and shows a clear recovery path instead of pretending to capture audio

### Requirement: Voice interpretation SHALL use one unified pipeline for single-intent and multi-intent utterances
The system SHALL process spoken input through one interpretation pipeline that can classify a transcript as single-intent, multi-intent, or uncertain, without requiring the user to preselect a separate mode.

#### Scenario: Single transaction utterance
- **WHEN** the recognized transcript indicates one sufficiently clear transaction request
- **THEN** the interpreter treats the utterance as a single-intent voice entry and evaluates it as one draft transaction candidate

#### Scenario: Multiple transaction utterance
- **WHEN** the recognized transcript contains multiple sufficiently clear transaction segments
- **THEN** the interpreter returns separate transaction candidates within the same voice result instead of collapsing them into one card

#### Scenario: Ambiguous segmentation
- **WHEN** the recognized transcript could plausibly represent either one transaction or multiple transactions
- **THEN** the interpreter marks the result as uncertain and does not silently choose a destructive interpretation without user review

### Requirement: Voice entry SHALL only auto-create draft cards when the parsed result is sufficiently complete and safe
The system SHALL create draft transaction cards from voice input only when each proposed transaction contains the required core data and the interpretation confidence is high enough for review-safe card generation.

#### Scenario: Complete voice transaction
- **WHEN** a spoken transaction yields a reliable amount, enough semantic information for title/category/type inference, and a usable transaction time context
- **THEN** the system creates one or more draft transaction cards that the user can review with the existing AI draft flow

#### Scenario: Missing critical field
- **WHEN** a spoken transaction is missing a critical field such as amount or has unresolved core meaning
- **THEN** the system does not auto-create a ready draft card for that transaction and instead routes the user to clarification or recommendation handling

### Requirement: Voice ambiguity SHALL produce structured recommendations and editable recovery paths
When the transcript is partially understood but not safe to auto-confirm, the system SHALL provide structured recommendation output that helps the user recover without needing to repeat the entire utterance from the beginning.

#### Scenario: Multiple plausible interpretations
- **WHEN** the spoken transcript yields more than one plausible transaction interpretation
- **THEN** the system shows recommendation options or candidate transaction interpretations that the user can choose from

#### Scenario: Partial but useful understanding
- **WHEN** the spoken transcript contains some trustworthy fields but still has unresolved ambiguity
- **THEN** the system preserves the trustworthy fields in a recommendation or editable draft seed so the user can correct the rest with less effort

#### Scenario: Insufficient understanding
- **WHEN** the spoken transcript is too weak or contradictory to form a safe recommendation
- **THEN** the system asks the user to try again or clarify the missing part instead of fabricating draft cards

### Requirement: Voice-generated draft results SHALL stay inside the existing AI draft review boundary
The system SHALL keep voice-generated transaction results inside the current AI draft card lifecycle so that users can review, edit, delete, persist locally, and batch-save them using the same confirmation boundary as typed AI transaction cards.

#### Scenario: Voice result creates reviewable cards
- **WHEN** voice interpretation produces safe draft transactions
- **THEN** the resulting cards appear in the AI conversation with the same review and save affordances used for existing AI draft cards

#### Scenario: App restarts before save
- **WHEN** the user has unresolved voice-generated draft cards or recommendations in the AI conversation and restarts the app
- **THEN** the local AI history restores the draft review state needed to continue review instead of dropping the voice result context

#### Scenario: Saving voice-generated cards
- **WHEN** the user confirms and saves voice-generated draft cards
- **THEN** only the finalized transaction fields are persisted as transactions and voice-only review metadata does not become part of the stored transaction schema
