## 1. Policy Configuration

- [ ] 1.1 Define the Firestore-backed schema for supported application reminder policies, including enabled state, typed reminder kind, daily send times, channel settings, and scheduling timezone metadata.
- [ ] 1.2 Add admin-facing configuration support to create, update, enable, and disable reminder policies for the supported reminder types.
- [ ] 1.3 Validate admin policy input so unsupported reminder types, malformed send times, and invalid schedule combinations cannot be stored.

## 2. Reminder Evaluation Engine

- [ ] 2.1 Implement backend scheduled execution that loads reminder policies and determines which policy windows are due for evaluation.
- [ ] 2.2 Implement typed eligibility evaluators for the first supported reminder types: daily transaction reminder and daily savings reminder.
- [ ] 2.3 Record effective date and scheduled window metadata during evaluation so reminder generation is tied to a specific daily send slot.

## 3. Delivery State And Dedupe

- [ ] 3.1 Implement deterministic dedupe keys for reminder deliveries using user, reminder type, effective date, and scheduled send window.
- [ ] 3.2 Persist reminder delivery state so retries or overlapping scheduler runs do not create duplicate deliveries for the same window.
- [ ] 3.3 Honor per-user "Khong nhac lai hom nay" suppression so later windows for the same reminder type are skipped on the same day.

## 4. Notification Feed Integration

- [ ] 4.1 Upsert scheduled reminder deliveries into the per-user notification feed as durable application reminder records.
- [ ] 4.2 Ensure disabled reminder policies stop producing new feed entries without rewriting already-created reminder history.
- [ ] 4.3 Gate or remove the old hardcoded client reminder timing once backend-generated reminders are verified.

## 5. Verification And Rollout

- [ ] 5.1 Add automated coverage for policy enable/disable, multiple send windows, eligibility filtering, daily suppression, and dedupe behavior.
- [ ] 5.2 Verify day rollover behavior for application reminders so suppression and effective-date logic reset correctly on the next day.
- [ ] 5.3 Document rollout and fallback steps for enabling policy-driven reminder scheduling in production environments.
