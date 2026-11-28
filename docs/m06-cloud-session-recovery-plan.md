# M06 — cloud session persistence and reinstall recovery

Owner requirement, 27 November 2026: learning sessions and progress must survive uninstall/reinstall and restore after signing into the same Firebase account. This is required core behavior, not an optional enhancement to Missions. Implement under [M06 #8](https://github.com/ShriramSundaram/legendary-octo-flutter/issues/8) before completing the dependent M07/M11 work.

## Current behavior, confirmed from source

Review sessions/scheduling/daily credit are stored through `AccountReviewStorage` in account-scoped Hive `learningReviewV1`. Completed quiz summaries use local `practiceSessionsV1`; unfinished tests currently live in widget/session memory. An existing Firestore `saveState` method does not make these flows cloud-backed. Version 1.0.9 (24) therefore does not provide reinstall recovery for this learning data.

Uninstall removes device-local app storage. Previously removed data cannot be reconstructed unless a cloud copy or another valid backup exists. Implementation must migrate data that still exists on a device, not claim it can recover already-erased history.

## Required saved data

- Recall review: stable attempt/session identity, content version and ordered word IDs, next unanswered cursor, submitted answers and completion state.
- Word scheduling: due time, interval, last attempt and scheduler version.
- Tests and Quick Vocabulary Check: frozen question order/content version, submitted choices/results and resumable checkpoint. Preserve already-answered questions; define interrupted timed-test behavior explicitly rather than silently restarting the score/timer.
- Daily progress and chosen goal: credit identities, recorded calendar day, aggregates and recent test history. Restoring or retrying must not award activity twice or move old activity to a new day.
- Future Missions: stable mission/attempt/content version, dialogue step, choices, result and completion identity.

## Action points

- [ ] Inventory and validate current account-local review/progress/quiz data; define bounded, versioned user-owned Firestore records and an idempotent migration.
- [ ] Add durable local checkpoints/outbox operations with unique IDs. Save locally first so practice remains responsive offline; upload/retry in the background for the captured account.
- [ ] Cloud-save every submitted-answer/step checkpoint and completion, not just the final result screen. Batch related changes where possible and measure read/write cost against M06's budget.
- [ ] Acknowledge **Synced** only after server confirmation; expose Saving / Waiting for connection / Couldn't sync, Retry. Local cache acceptance alone is not cloud confirmation.
- [ ] After fresh install/sign-in, restore cloud state before initializing or uploading empty defaults. A failed/offline restore must not erase remote progress.
- [ ] Merge remaining local data safely on upgrade. Retries, reconnects, restored snapshots and repeated migration must not duplicate sessions or daily totals.
- [ ] Define deterministic two-device conflicts. Preserve separate attempts and immutable credit days; never blindly replace a whole account or repeatedly sum uploaded aggregates.
- [ ] Enforce owner-only access and stop/rebind synchronization on sign-out/account switch; queued data from account A must never upload as B.
- [ ] Align retention and account-deletion inventory with M08, including session checkpoints, results and progress summaries.
- [ ] Reuse this persistence layer for M07 and M11; do not create a separate missions-only cloud store that leaves existing reviews/tests local.

## Acceptance and recovery checks

1. Finish a review and test, change the goal, wait for Synced, reinstall and sign into the same account. Restore goal, schedule, results and daily totals without duplication.
2. Leave a recall review midway after a synced answer. Reinstall and resume at the next unanswered word.
3. Leave a test midway; restore its original questions, submitted responses and defined timer state. Apply the same check to Missions when built.
4. Work offline, restart, reconnect and wait for Synced. Retry/duplicate uploads preserve one logical attempt and one daily credit.
5. Fresh install or sign-in with an unavailable cloud connection never overwrites saved cloud data with an empty account snapshot.
6. Two accounts on one phone and the same account on two devices follow the documented isolation/conflict policy.
7. M09's final reinstall test uses a disposable test installation/account after confirmed cloud sync. Do not uninstall or clear the owner's existing app/data without explicit authorization for that destructive test.

Only server-confirmed data is recoverable from the cloud. Work performed offline and uninstalled before it uploads cannot be recovered from a server that never received it. The UI must make pending synchronization visible.

## Status

Requirement/plan updated; cloud implementation and deployment have not been performed in this planning update. M06, M07 and M11 remain open. Existing production artifacts are unchanged.
