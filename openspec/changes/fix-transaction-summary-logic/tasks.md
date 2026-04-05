## 1. Invariant Alignment

- [x] 1.1 Inventory every transaction write path that updates `totalCredit`, `totalDebit`, or `remainingAmount`
- [x] 1.2 Normalize the shared transaction summary rules so debit totals are stored as positive aggregates and balance changes derive from `type`
- [x] 1.3 Update create, update, and delete transaction flows to apply the same summary arithmetic across manual and AI entry points

## 2. Summary Consumer Compatibility

- [x] 2.1 Audit summary cards, reports, exports, and admin views that read `totalDebit`
- [x] 2.2 Adjust any consumer that currently assumes `totalDebit` is negative so presentation signs are applied only in the UI or reporting layer
- [x] 2.3 Confirm the change does not alter unrelated data structures, collection layouts, or non-transaction workflows

## 3. Data Reconciliation

- [x] 3.1 Implement a deterministic reconciliation path that rebuilds `totalCredit`, `totalDebit`, and `remainingAmount` from transaction history
- [x] 3.2 Define handling for malformed historical transactions, including records with unexpected negative `amount` values
- [ ] 3.3 Validate reconciliation on representative user data before broad application

## 4. Verification

- [ ] 4.1 Verify manual create and delete flows for both `credit` and `debit` transactions
- [ ] 4.2 Verify transaction edits for same-type updates and type changes (`credit -> debit`, `debit -> credit`)
- [ ] 4.3 Verify AI-created transactions update summary fields with the same totals as manual flows
- [ ] 4.4 Verify net summaries and expense displays remain correct in home, reports, and admin views after reconciliation
