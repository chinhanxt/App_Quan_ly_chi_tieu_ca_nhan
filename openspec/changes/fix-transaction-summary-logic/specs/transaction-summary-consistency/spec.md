## ADDED Requirements

### Requirement: Transaction summaries SHALL use a single sign convention
The system SHALL treat transaction `amount` as a positive absolute value, SHALL store `totalCredit` as the positive sum of credit transactions, SHALL store `totalDebit` as the positive sum of debit transactions, and SHALL derive user balance semantics from transaction `type` rather than from negative stored totals.

#### Scenario: Credit transactions increase positive income totals
- **WHEN** a credit transaction is created or recalculated
- **THEN** the system SHALL add its positive `amount` to `totalCredit` and SHALL NOT negate the stored income total

#### Scenario: Debit transactions increase positive expense totals
- **WHEN** a debit transaction is created or recalculated
- **THEN** the system SHALL add its positive `amount` to `totalDebit` and SHALL NOT store expense totals as negative aggregates

### Requirement: Transaction create, update, and delete flows SHALL apply consistent summary arithmetic
The system SHALL update `remainingAmount`, `totalCredit`, and `totalDebit` with the same business rules across every transaction entry point, including manual create flows, AI create flows, update flows, and delete flows.

#### Scenario: Deleting a debit transaction restores balance and reduces total expense
- **WHEN** a stored debit transaction is deleted
- **THEN** the system SHALL increase `remainingAmount` by the transaction amount and SHALL decrease `totalDebit` by the same amount

#### Scenario: Updating a transaction reverts the old type before applying the new type
- **WHEN** an existing transaction is edited, including a change from `credit` to `debit` or from `debit` to `credit`
- **THEN** the system SHALL first reverse the old transaction's summary effect and SHALL then apply the new transaction's summary effect using the same arithmetic rules as transaction creation

#### Scenario: AI-created transactions follow the same summary rules
- **WHEN** a transaction is saved through the AI transaction flow
- **THEN** the system SHALL update summary fields with the same arithmetic and sign convention used by manual transaction flows

### Requirement: User summary data SHALL be reconcilable from transaction history
The system SHALL provide a deterministic way to rebuild `totalCredit`, `totalDebit`, and `remainingAmount` for a user from the user's stored transaction history so that previously corrupted summary fields can be corrected without changing unrelated user data structures.

#### Scenario: Reconciliation rebuilds correct user totals
- **WHEN** the system recalculates a user's summary fields from `users/{uid}/transactions`
- **THEN** `totalCredit` SHALL equal the sum of credit amounts, `totalDebit` SHALL equal the sum of debit amounts, and `remainingAmount` SHALL equal `totalCredit - totalDebit`

#### Scenario: Reconciliation preserves unrelated user data
- **WHEN** summary reconciliation updates a user document
- **THEN** the system SHALL modify only summary fields that depend on transaction totals and SHALL NOT alter unrelated profile, permissions, settings, or other domain structures

### Requirement: Summary consumers SHALL interpret expense totals as positive values
Any screen, report, or admin view that reads `totalDebit` SHALL interpret it as a positive expense aggregate and SHALL apply visual negative signs only at presentation time when needed.

#### Scenario: Expense cards display a negative sign without requiring negative stored totals
- **WHEN** a UI component renders an expense summary from `totalDebit`
- **THEN** the component SHALL prepend or style the visual negative indicator in the presentation layer without expecting `totalDebit` itself to be negative

#### Scenario: Net calculations subtract positive expense totals
- **WHEN** a report or summary view computes net balance or net cash flow from aggregate fields
- **THEN** it SHALL compute the net result as `totalCredit - totalDebit`
