## ADDED Requirements

### Requirement: Mobile layouts SHALL adapt to compact Android screens
The system SHALL detect compact-width, short-height, or large-text Android conditions and switch high-risk mobile layouts to safe fallback arrangements instead of preserving a single fixed composition.

#### Scenario: Compact mobile layout is activated
- **WHEN** a mobile screen is rendered on an Android device with narrow width, limited vertical height, or enlarged system text
- **THEN** the UI SHALL apply a compact-safe layout mode for affected high-risk components

#### Scenario: Reference layout is preserved on regular devices
- **WHEN** a mobile screen is rendered on an Android device with sufficient width, height, and normal text scale
- **THEN** the UI SHALL preserve the existing primary visual layout

### Requirement: Transaction cards SHALL remain readable on narrow Android devices
The system SHALL render transaction cards in a layout that preserves title, amount, remaining balance, timestamp, note, and actions without forcing titles into vertical letter wrapping or causing content overlap.

#### Scenario: Transaction card falls back on narrow width
- **WHEN** a transaction card is shown on a narrow Android screen
- **THEN** the card SHALL rearrange metadata and actions into a readable fallback layout rather than forcing all content into one horizontal row

#### Scenario: Long text does not break the card
- **WHEN** transaction title, note, or category text is longer than the available width
- **THEN** the card SHALL constrain lines and apply overflow handling so the card remains readable and stable

### Requirement: Bottom navigation and floating actions SHALL avoid overlap
The system SHALL ensure bottom navigation, floating actions, and primary content respect safe areas and do not visually collide on Android devices with limited vertical space or large navigation insets.

#### Scenario: Floating actions avoid bottom navigation
- **WHEN** the home screen is displayed on a device with a short viewport or large bottom inset
- **THEN** floating actions SHALL be positioned or collapsed so they do not cover essential content or bottom navigation

#### Scenario: Bottom navigation remains usable on compact devices
- **WHEN** the app is displayed on a compact Android device
- **THEN** bottom navigation labels and icons SHALL remain visible and tappable without truncating or overlapping neighboring destinations

### Requirement: AI input screen SHALL support compact density mode
The system SHALL provide a compact-density presentation for the AI input screen so that the header, chat area, quick actions, and composer remain usable on short Android devices and under larger text scale.

#### Scenario: AI screen compresses non-essential spacing
- **WHEN** the AI input screen is opened on a short Android device
- **THEN** decorative spacing, header density, and quick action density SHALL reduce before essential controls become obscured

#### Scenario: Composer remains accessible with keyboard and large text
- **WHEN** the AI input screen is used with the keyboard open or with enlarged system text
- **THEN** the composer and send controls SHALL remain accessible without covering the primary conversation flow
