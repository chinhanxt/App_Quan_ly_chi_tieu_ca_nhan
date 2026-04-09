## ADDED Requirements

### Requirement: Dashboard primary sections SHALL support synchronized swipe and bottom-nav navigation
The dashboard shell SHALL render the five primary mobile sections in a horizontally swipeable container and SHALL keep the bottom navigation selection synchronized with both taps and swipes.

#### Scenario: Bottom-nav tap updates the page
- **WHEN** the user taps one of the five primary navigation destinations
- **THEN** the dashboard animates to the matching primary section and updates the selected navigation state

#### Scenario: Horizontal swipe updates the selected destination
- **WHEN** the user swipes horizontally between adjacent primary dashboard sections
- **THEN** the visible section changes and the bottom navigation highlights the matching destination

### Requirement: Transaction nested swipes SHALL be consumed before leaving the transaction section
The transaction section SHALL treat its inner transaction tabs as the first horizontal swipe destination, and the dashboard shell SHALL only advance to an adjacent primary section after the transaction tab interaction has reached the relevant edge.

#### Scenario: First swipe changes transaction sub-tab
- **WHEN** the user is on the transaction primary section and swipes horizontally toward the sibling transaction tab while that sibling exists
- **THEN** the transaction screen changes between its inner tabs without switching the dashboard to another primary section

#### Scenario: Edge swipe leaves the transaction section
- **WHEN** the user is on the outermost transaction sub-tab in the swipe direction and performs another horizontal swipe in that same direction
- **THEN** the dashboard shell moves to the adjacent primary section

### Requirement: Primary section changes SHALL preserve workspace state during shell navigation
The dashboard shell SHALL preserve each primary section instance while navigating between primary sections so in-progress context is not dropped solely because the user swiped or tapped to another section.

#### Scenario: Returning to a previously visited primary section
- **WHEN** the user navigates away from a primary section and then returns within the same dashboard session
- **THEN** the app restores that section with its existing in-memory workspace state rather than rebuilding it from an empty default state caused only by shell navigation
