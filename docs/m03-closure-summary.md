# M03 completion — 26 November 2026

All original M03 feature acceptance criteria passed:

- Recall before revealing meanings/examples; Again and Remembered responses.
- A documented deterministic scheduler with versioned state and injected clock:
  Again after 10 minutes; increasing Remembered intervals from 1 to 180 days.
- At most ten published structured words per session; due words before optional
  new items; consistent level/topic selection across A1–C2.
- Atomic account-scoped local checkpoints preserve schedules/session cursor;
  interrupted sessions resume without counting completed answers twice.
- Clear self-reported recall labels, separate from scored quiz accuracy.
- Tests cover first recall, lapses, midnight/time changes, empty decks, due-time
  boundaries, persistence failures, concurrent/stale taps, Hive reopening/account
  isolation, removed content, reveal/resume UI and narrow-screen large text.

Verification: all 63 Flutter tests passed; targeted Dart analysis was clean.
The user confirmed login and the core reveal/rate/resume flow on their wireless
phone running the 1.0.4+17 debug build. Extra ten-minute, airplane-mode and manual
account-switch checks were not separately reported; automated coverage is not
represented as physical testing. No screenshots/emulator were used.

App Check login was corrected for the private wireless build using the existing
registered debug credential. Production continues to use Play Integrity; the
release build must not use the ignored wireless debug defines file.

No M03 implementation points remain. A signed 1.0.4+17 app bundle and release
notes are ready and verified for the owner's production upload; issue closure does
not claim that Google approved/published that upload. Firestore sync is M06,
durable reminders M05, the progress dashboard M07, and lesson/quiz feedback M04.
