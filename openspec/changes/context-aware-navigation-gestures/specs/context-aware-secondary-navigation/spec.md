## ADDED Requirements

### Requirement: Secondary screens SHALL preserve their originating workspace in the back stack
When the user opens a secondary screen from AI, notifications, search, assistive actions, or another non-primary overlay source, the system SHALL push the destination so the originating workspace remains the immediate back destination.

#### Scenario: AI opens a primary-related reference screen
- **WHEN** the user opens budget, savings, or another reference screen from an AI action
- **THEN** the destination opens without discarding the AI screen and a back action returns the user to the AI workspace

#### Scenario: Notification detail opens a linked destination
- **WHEN** the user opens a linked destination from the notification detail screen
- **THEN** the destination opens without discarding the notification screen and a back action returns the user to notifications

### Requirement: Primary sections opened from outside the dashboard SHALL use contextual fallback behavior
If a primary section destination is opened from a context that does not already have a live dashboard shell in the route stack, the system SHALL create or reuse the dashboard shell with the matching selected section as the fallback workspace.

#### Scenario: External context opens budget without an existing dashboard shell
- **WHEN** a budget destination is opened from a cold-start, heads-up action, or another context that has no dashboard shell to return to
- **THEN** the app opens the dashboard with the budget section selected as the fallback primary workspace

### Requirement: Secondary pushed screens SHALL support route-based back gestures where available
Secondary screens that are pushed onto the route stack SHALL use route behavior that supports platform back gestures, including iPhone-style edge-swipe back on supported platforms.

#### Scenario: iPhone-style edge swipe returns to source screen
- **WHEN** the user opens a supported secondary screen on iOS and swipes from the left edge toward the right
- **THEN** the route pops interactively and reveals the originating screen underneath

#### Scenario: Back gesture does not switch primary tabs
- **WHEN** the user performs a back gesture on a secondary pushed screen
- **THEN** the app pops the current route instead of interpreting the gesture as a primary dashboard tab switch
