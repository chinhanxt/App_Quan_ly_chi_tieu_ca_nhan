## Context

The current application reminder flow is primarily client-driven: the mobile app decides when to evaluate conditions such as "user has not entered a transaction today" or "user has not contributed to savings today," then surfaces reminders while the app is open. That approach works for lightweight in-app nudges, but it does not provide stable operational control, cannot be adjusted without shipping code, and does not form a strong foundation for future push delivery outside the app.

This change introduces a long-lived reminder-policy layer for application-generated notifications. System broadcasts remain proactive admin messages with their own lifecycle. Application reminders move to an admin-configured schedule model where admins define the send windows and the backend evaluates which users are still eligible at each window. The design must preserve the current "Khong nhac lai hom nay" behavior, avoid duplicate sends for the same reminder window, and keep reminder state compatible with the existing in-app notification feed.

## Goals / Non-Goals

**Goals:**
- Move application reminder timing authority from hardcoded client behavior into admin-managed configuration.
- Support one or more daily send times per reminder type, such as `10:00` and `22:00`.
- Evaluate reminder eligibility from backend-controlled schedules so reminders can be generated consistently without requiring the app to be open first.
- Preserve per-user daily suppression so a user who chooses "Khong nhac lai hom nay" is skipped for the rest of that local day.
- Deduplicate reminder delivery so the same reminder type is not sent multiple times to the same user for the same scheduled window.
- Keep the per-user notification feed as the durable record of reminder state so in-app review remains consistent with scheduled delivery.

**Non-Goals:**
- Redesigning the current in-app notification page or heads-up animations.
- Replacing or modifying admin system broadcast authoring beyond sharing notification infrastructure where useful.
- Delivering personalized arbitrary reminder rules defined by free-form admin queries.
- Solving full multi-timezone scheduling for all geographies in the first version if the product is currently Vietnam-centered.
- Implementing all push-notification delivery channels in this change if the project chooses to land policy and generation before FCM fan-out.

## Decisions

### 1. Split reminder policy configuration from system broadcast content
Application reminders will use a separate admin-managed policy model rather than being authored as broadcast messages. Each policy represents a reminder type such as `daily_transaction_reminder` or `daily_savings_reminder`, with fields for enabled state, one or more send times, delivery channels, and template text.

Why:
- Broadcasts and reminders have different authorship and lifecycle needs.
- Reminder rules need operational controls such as schedule windows and dedupe behavior.
- This separation avoids overloading broadcast content with rule-engine responsibilities.

Alternative considered:
- Reusing `system_broadcasts` to store reminder schedules. Rejected because reminder policies are not ad hoc content items and need structured fields that differ from broadcasts.

### 2. Keep Firestore-backed user notification records as the source of truth
The scheduled engine will write reminder records into the per-user notification feed before or alongside any delivery channel actions. In-app UI will continue to render from that feed rather than from transient scheduler events.

Why:
- Feed records preserve unread state, suppression state, and history.
- Push delivery and in-app delivery can stay consistent by referencing the same notification record.
- Debugging becomes easier because each scheduled send has a durable output in user data.

Alternative considered:
- Treating scheduled reminders as push-only events. Rejected because the app would lose a stable review surface and state would drift across channels.

### 3. Evaluate reminder policies from backend-controlled scheduled windows
A backend scheduler will run on a fixed cadence and evaluate which reminder policies are currently due. For each due policy, it will determine which users are eligible, skip users suppressed for that reminder on the current day, and generate reminder deliveries.

Why:
- The backend can generate reminders even when the app is not open.
- Admin time changes take effect without requiring a client update.
- A scheduled cadence with time-window matching is more reliable than depending on exact second-level cron timing.

Alternative considered:
- Letting the client poll policy configuration and self-trigger reminders. Rejected because it keeps delivery dependent on the app lifecycle and undermines the long-term platform goal.

### 4. Use explicit dedupe keys per user, reminder type, local date, and scheduled window
Each scheduled reminder delivery will carry a deterministic dedupe key built from reminder type, user identity, effective date, and configured send time. The scheduler will not create or send another delivery for the same key once it has succeeded.

Why:
- Scheduled jobs may re-run or overlap.
- The same reminder rule can have multiple configured send times in one day.
- Dedupe makes repeated scheduler execution safe and observable.

Alternative considered:
- Deduping only on notification body text. Rejected because content can stay the same across different windows and would collapse valid deliveries.

### 5. Respect "Khong nhac lai hom nay" as a per-type daily suppression
When a user suppresses a reminder for the day, the system will record suppression state keyed by reminder type and effective local date. Later scheduled windows for that reminder type on the same day will skip the user. The suppression expires automatically on the next local day.

Why:
- This preserves the behavior already expected in the product.
- It gives users control without permanently disabling reminders.
- It keeps suppression logic aligned with daily reminder semantics.

Alternative considered:
- Treating suppression as a permanent unsubscribe. Rejected because it is too strong for a day-scoped reminder dismissal.

### 6. Start with a configured platform timezone, with room to evolve to per-user local time
The first implementation should support a clear scheduling timezone policy, ideally `Asia/Ho_Chi_Minh` if the active product audience is Vietnam-centered. The policy and delivery records should still store enough metadata to support later migration to per-user local-time scheduling.

Why:
- Timezone handling is the hardest part of daily scheduling.
- A fixed product timezone dramatically reduces launch complexity.
- A schema that records effective dates and scheduled slots keeps future per-user timezone support possible.

Alternative considered:
- Requiring per-user timezone scheduling from day one. Rejected because it expands scheduler complexity, testing surface, and eligibility calculation risk.

### 7. Model reminder eligibility as typed rule evaluators, not arbitrary queries
Each reminder type will have a dedicated evaluator in backend logic that checks domain data such as today's transactions or today's savings contributions. Admins can schedule and enable the reminder type, but they do not define custom eligibility expressions.

Why:
- Typed evaluators are safer, testable, and easier to evolve.
- Business logic remains inside code where domain rules can be validated.
- This limits admin power to configuration rather than ad hoc logic authoring.

Alternative considered:
- Allowing admins to define rules dynamically. Rejected because it increases operational and security risk and would be much harder to validate.

## Risks / Trade-offs

- [Scheduler sends reminders twice because jobs overlap or retry] -> Use deterministic dedupe keys and persisted delivery records before fan-out.
- [Timezone boundaries cause a reminder to target the wrong local day] -> Store both scheduled slot and effective date explicitly, start with a fixed timezone, and test day rollover around midnight.
- [Reminder policy becomes too broad and spams users] -> Limit first-version policies to known reminder types and require explicit send times rather than open-ended recurrence expressions.
- [Backend eligibility checks become expensive at scale] -> Start with a small set of typed evaluators, index required query fields, and batch users by rule rather than loading unnecessary documents.
- [Push delivery may arrive without matching feed state] -> Write or upsert the feed record before final delivery fan-out so the app can reconcile reliably.
- [Current client-generated reminders may conflict with scheduled reminders during migration] -> Gate the old client timing logic behind a migration flag and disable it once backend scheduling is validated.

## Migration Plan

1. Define the reminder policy schema and admin configuration storage for known reminder types.
2. Implement backend scheduled evaluation and deduped delivery record creation while keeping client-generated reminders available behind a temporary fallback.
3. Upsert per-user reminder feed records from the scheduler and verify the in-app notification page renders scheduled reminders correctly.
4. Connect configured channels for reminder delivery, starting with in-app feed generation and optionally adding push fan-out once generation is stable.
5. Disable hardcoded client-side reminder timing after backend-generated reminders are verified in production-like environments.
6. If rollout issues occur, disable policy-driven generation via admin config and temporarily fall back to in-app-only reminders while preserving stored policy data.

## Open Questions

- Whether the first release should include push delivery for scheduled reminders or land feed generation and admin scheduling first.
- Whether admins may customize reminder title/body templates immediately or only configure timing and enabled state in the first release.
- Whether the initial schedule timezone should be fixed to `Asia/Ho_Chi_Minh` or already support per-user local time.
- Whether budget warnings should move into the same policy engine in the same phase or stay on their current in-app path until reminder scheduling proves stable.
