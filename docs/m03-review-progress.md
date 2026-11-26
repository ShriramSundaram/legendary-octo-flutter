# M03 recall sessions and graduated review

## Current status — 2026-11-26

The user confirmed successful login and accepted the core M03 phone flow:
Review words → Start practice, Reveal meaning → Again / Remembered, and leaving
midway/reopening → Continue saved session at the next word. Their result was
"All works great." These phone checks passed on the installed 1.0.4+17 debug
build. The completion review below reran all 63 automated tests successfully;
targeted analysis was clean.

Implementation and core phone acceptance are complete. A signed M03 1.0.4+17
bundle has been built and verified, and GitHub issue #5 was closed as completed
on 2026-11-26 at the owner's request. The owner will upload to production;
Google publication is not claimed. The ten-minute due-time, airplane-mode and manual
account-switch checks were not separately reported by the user. Scheduling and
local account isolation are covered by the automated tests. Historical pending
notes below describe earlier checkpoints and are superseded by this status.

## Completion review — 2026-11-26

Compared implementation and tests against the live acceptance criteria in
[M03 / issue #5](https://github.com/ShriramSundaram/legendary-octo-flutter/issues/5).
The issue was open during that initial review. After release preparation and
the owner's explicit closure request, #5 was closed with completion evidence.

| Original M03 criterion | Evidence | Result |
| --- | --- | --- |
| Recall before revealing meaning/example, then Again or Remembered | Recall widget tests and user's phone acceptance | Passed |
| Failed words return earlier, successful intervals grow, due before optional new words | Scheduler/controller tests, including exact 10-minute and one-day boundaries after reopening | Passed |
| Fixed-clock tests for first review, repeated lapse, midnight, time changes and empty decks | `test/review_scheduler_test.dart` | Passed |
| Interrupted session preserves completed answers without double counting | Checkpoint/reopen, stale-tap/concurrent-tap tests, real Hive reopening and user's phone acceptance | Passed |
| Clearly distinguish self-reported recall from scored quiz accuracy | Recall page labels and widget tests | Passed |

The original feature criteria are met in the audited local implementation. No
blocking functional defect was found in those paths. All 63 Flutter tests passed
and targeted analysis found no issues. A new regression test covers the entire
Again → save → reopen → not due at 9:59 → due at 10:00 sequence, followed by the
Remembered → one-day boundary. This review changed tests/documentation only;
the working phone installation did not need replacement.

Release handoff: the signed M03 1.0.4+17 app bundle is verified at
`build/releases/1.0.4+17/app-release.aab`; release notes are in
`docs/m03-play-release-notes.txt`. Its signature verified, the private wireless
debug credential is absent, and all approved content files are included.
`docs/m03-release-candidate.json` records size and SHA-256. M02's prior bundle
is archived separately at `build/releases/1.0.3+16/app-release.aab`.
Production upload and rollout verification will be handled by the owner.
Physical ten-minute,
airplane-mode and account-switch checks were not separately reported; automated
coverage is not presented as proof that those manual checks were performed.

### Where the learner sees progress today

- Review entry: due/new counts for the selected level/topic.
- During practice: Word N of M and the current-session progress bar.
- Completion: Remembered / Again totals for that session.
- Reopening an unfinished session: the saved answered count and Continue action.

There is no durable daily totals/history/streak dashboard yet. That is M07
([issue #9](https://github.com/ShriramSundaram/legendary-octo-flutter/issues/9)),
not an original M03 acceptance criterion. Local schedules and the last session
are stored under the account's Hive `learningReviewV1` key. M06 owns Firestore
synchronization; M03 does not yet make this progress visible in Firebase Console.

Status wording: **M03 complete; GitHub #5 closed; signed release bundle handed
off for the owner's production upload.** Do not claim Google publication.

Implementation started 2026-11-25, after the user accepted M02 on the phone and
reported uploading 1.0.3+16 to Play. Google publication was not independently
verified. M01's manual rollout checks remain deferred and separate.

## Delivered behaviour

- Home has a named **Review words** action. Library **Start practice** uses the
  chosen level/topic, with the same behaviour across A1–C2.
- Sessions contain at most ten distinct published, structured M02 words. Due
  items precede optional new items; **Include new words** can be disabled.
- German is visible before reveal. **Reveal meaning** exposes English, example,
  translation and noun details. **Again / Remembered** are enabled afterwards.
- Self-reported recall counts are clearly distinct from quiz accuracy, mastery,
  streaks or certified CEFR results. No automatic grading is implied.
- A single account-scoped Hive checkpoint stores schedules and the session
  cursor together after each answer. Leaving/reopening resumes the next word;
  completed responses are not counted twice. An unanswered revealed card is
  hidden again on reopening, and has no new schedule until an answer is saved.
- Double taps/stale positions are rejected. A failed write leaves the active
  card and in-memory schedule unchanged for retry. Unknown/corrupt data is not
  overwritten. Removed content can start a new session while keeping schedules.

## Schedule version 1

This is a project-defined deterministic schedule, not FSRS or an adaptive
retention model. **Again** schedules the word after 600 seconds and increments
its lapse count. **Remembered** advances to the next interval: 1, 3, 7, 14, 30,
60, 120 and 180 days, capped at 180 days. After Again, Remembered returns to
one day. Lapses are capped at 1,000,000 to match the existing state model.

All dates are UTC instants and intervals are elapsed seconds, so midnight and
timezone changes do not introduce calendar-day rounding. An injected clock
supports tests. A clock moved backwards cannot move a word's last attempt
backwards; forward changes can make more words due. Device-clock correctness
is not guaranteed without a trusted server clock.

The key is AccountStore's per-UID `learningReviewV1`, containing schemaVersion,
states and the active session. Each word state has itemId, dueAt, lastAttempt,
intervalSeconds, lapseCount and schedulerVersion. This is local device storage;
M06 owns authenticated Firestore synchronization. `learningStateV1` will not
appear in Firestore merely from this local M03 implementation. Sign-out/switch
guards prevent one account's controller from reading/writing another's data.

The richer 269-word approved catalog is the initial review pool. Original legacy
vocabulary remains available offline for browsing/home random cards; entries
without examples/structured metadata are not silently given fabricated details.
M04 still owns scored quiz feedback and timers, M05 durable reminders, and UI01
the broader visual/navigation redesign.

## Verification and rollout

The 18 focused tests passed: first recall/lapse, interval progression/cap,
repeated lapse, midnight/timezones, backwards clocks, empty/due-only decks,
due-before-new, all levels/topic selection, interruption/reopen, duplicate and
concurrent answers, failed persistence, removed content, unknown formats, real
Hive reopening/account isolation, reveal-only meanings, honest summaries,
large text at 320 px and leaving during loading.

The following paragraphs record earlier verification/install checkpoints.
The current status and completion review above supersede their pending states.
No emulator or screenshots were used; no production rollout was performed.

Verified 2026-11-26: all 62 Flutter tests passed, targeted Dart analysis reported
no issues, and the version 1.0.4+17 debug APK built successfully. The M02 release
bundle was not rebuilt or replaced. Wireless pairing succeeded and connection
to the phone's current debugging service was established on 2026-11-26.
`adb install -r` returned `Success`, preserving the existing debug app data.
At that checkpoint, physical M03 acceptance was pending; the user subsequently
confirmed the core review/session-resume checks listed in the current status.

The phone then reported login failure. Logs confirmed App Check 403 rather than
a scheduler error. The saved registered debug credential was accepted directly
by Firebase; the new `tools/build-wireless-debug.ps1` explicitly passes it from
ignored local storage. After rebuilding and data-preserving installation, the
app logged `Wireless App Check validation: accepted` on 2026-11-26. Targeted
analysis remained clean. The user subsequently confirmed successful login and
the core M03 phone checks listed in the current status.
Release Play Integrity and production enforcement were unchanged.

## Phone acceptance checklist

1. Tap **Review words** on home, or choose a library level/topic and **Start
   practice**. Check that the selected level/topic is shown correctly.
2. Start practice: English/example must stay hidden until **Reveal meaning**.
   Use **Again** for one word and **Remembered** for another.
3. Leave partway through. Reopen and **Continue saved session**; completed cards
   must not repeat and the next card must begin hidden. Repeat after closing
   and reopening the app without signing out.
4. Complete the session. Counts should match your answers, with no proficiency
   claim. Disable **Include new words**: successful words should not return
   immediately. After ten minutes, Again words should become due.
5. Try another level/topic and airplane mode with the existing signed-in account.
   Review should work offline. Switching accounts should reveal separate progress.
6. Report PASS/FAIL plus any error text; no screenshot/password is needed.
