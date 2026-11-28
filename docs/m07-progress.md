# M07 — daily rhythm, useful progress and Learning Library

Owner authorized M07 and additional Learning Library UI improvements on 27 November 2026. Tracked by [M07 #9](https://github.com/ShriramSundaram/legendary-octo-flutter/issues/9) and the existing [UI01 #16](https://github.com/ShriramSundaram/legendary-octo-flutter/issues/16); no duplicate design ticket.

## Learner experience

- Home has one primary Start review / Continue saved session action, a genuine due count, today's review count and a goal-completion state. A named Explore learning library button makes learning discoverable.
- Daily goal defaults to ten recall reviews and can be changed to 5, 10, 15 or 20. Every submitted Again/Remembered answer counts; simply browsing or opening a session does not.
- The expandable seven-day view shows daily recall activity, today's Remembered/Again ratings, completed practice sessions and recent quiz accuracy. Submitted correct/wrong quiz choices are separate from self-reported recall; unanswered questions are excluded from the explicitly labeled answered-question denominator. The test sample is the saved history (up to 50 tests) within seven local calendar days. No fluency percentage or fabricated streak is shown.
- Session completion celebrates the real work done and shows the daily total. Partial sessions preserve answer credit; a session completion is credited only on its last answer.
- Learning Library uses light lavender/peach surfaces, topic illustrations through emoji, actual word counts, practiced/due topic hints, German/English search and tap-to-reveal cards with pronunciation, examples, translation and noun details.
- Practice and Test remain pinned at the bottom during scrolling. Existing A1–C2 starter pack filters, pending-review labels, retry/empty states and the full offline vocabulary entry remain available. Starter packs do not claim complete CEFR coverage.

## Storage and recovery

Daily progress is stored in the existing account-scoped Hive `learningReviewV1` value as `progressV1`; version-1 review states and cursors are retained. Old sessions receive a persisted ID on their next write. Existing word states are not converted into invented historical totals.

An answer writes its scheduling state, cursor, stable session/position credit and daily aggregate together. Account-level serialization covers review answers, new sessions and goal edits across local screens. Stale cursors/session IDs and repeated operation IDs cannot earn a second credit. Failed writes leave the answer retryable. Unsupported progress schemas surface an error without overwriting stored data.

The calendar day is fixed when an answer is recorded, using device-local time. Moving timezone or the clock does not redistribute old credit. Home refreshes after returning from a route, app resume and a periodic minute check, including midnight. Progress retains the latest 400 active calendar-day entries and 5,000 recent credit IDs; the saved cursor/session checks remain the primary replay guard. This is a local UI/history bound, not M06's cloud attempt-retention policy.

## Dependency boundary — M06 remains open

The owner explicitly requires cloud session/progress recovery after uninstall and reinstall. [M06 cloud recovery action plan](m06-cloud-session-recovery-plan.md) makes this a prerequisite for closing M07. Version 1.0.9 (24) remains device-local; creating a release bundle did not implement cloud persistence.

**Cloud synchronization is not implemented by this change.** UI explicitly says Saved on this device. M07's acceptance criterion covering synchronized totals and two-device reconciliation cannot be marked complete before M06 provides bounded uploads, operation deduplication and conflict handling. Future synchronization must preserve each recorded day/operation identity; it must not repeatedly sum uploaded aggregate snapshots. No Firestore rules, backend permissions or CI workflows were changed.

## Validation and handoff

Focused tests cover upgrade compatibility, atomic failure/retry, delayed concurrent writes, goal-edit serialization, restart, midnight/travel replay, corrupt-data preservation, quiz-vs-recall definitions, account isolation, Home refresh after review, search/reveal without credit, loading retry and 320px/200% text layouts.

All **120 Flutter tests passed**. Targeted analysis of eight source/test files reported **No issues found**. The complete **1.0.9 (24)** debug application was built, inspected for the isolated `com.sundaram.germanreminder.wirelesstest` package, version and German Reminder Test label, installed wirelessly with `Success`, and launched with `Status: ok`. The Play package version was checked before/after and remained unchanged. No app was uninstalled and test-app data was not cleared. Evidence: [wireless candidate](m07-wireless-candidate.json).

Earlier signed production bundles remain preserved. M07/UI01 stay open for M06 synchronization and final owner device acceptance. No production publication, commit or push is claimed.

The owner-requested signed production bundle **1.0.9 (24)** is built and verified at `build/releases/1.0.9+24/app-release.aab` (50,518,599 bytes). SHA-256: `025b83ed2e42a0de4358ee44a88d9597bbe7ec65257326e9ceb975bbbc71f9a2`. The signing certificate matches version 23. Production package/label, Firebase initialization, expected permissions/receiver/icon, approved vocabulary hashes and packaged branding were checked; private debug credentials and test entrypoint markers are absent. Evidence: [release manifest](m07-release-candidate.json). Release notes: [Play text](m07-play-release-notes.txt). Historical reminder smoke results are labeled as historical; no M07 optimized phone acceptance is inferred from them.

## Phone acceptance

1. Open German Reminder Test and sign in. On Home, edit the daily goal and check Start review / due count.
2. Submit two recall answers, leave midway and reopen. Confirm the saved session resumes and today's count stays at two.
3. Finish the session, tap Done and confirm Home updates immediately. Expand Your last 7 days and compare recall ratings with quiz accuracy after a short test.
4. Open Explore learning library. Choose A1–C2/topics, search a German or English word, reveal a card and hear pronunciation. Confirm browsing does not change daily credit and Practice/Test remain reachable while scrolling.
5. Check large system text. Switch to a second account and verify its independent goal/activity; return to the first and verify its saved progress. Airplane-mode practice remains local; no cloud-sync success is promised.
