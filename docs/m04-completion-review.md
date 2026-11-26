# M04 completion review — 26 November 2026

The project owner accepted the functional phone checks on 1.0.5+19 and the redesigned result screens on 1.0.5+20. This review checked the published GitHub issue #6 against the final owner-directed scope.

| Acceptance criterion | Review evidence | Result |
| --- | --- | --- |
| Correct response and reviewed explanation before advancing | Every submitted question, including the final one, stays on feedback until Continue/Finish; regression coverage verifies wrong-answer feedback. | Pass |
| Consistent correct/wrong/unanswered counts | Submission-based counters, exact-deadline timeout tests and selected-but-unsubmitted tests. Recall stays in Start practice and does not inflate test scores. | Pass |
| Honest level feedback | Topic results show the learner-selected content level. Profile samples A1–B2 vocabulary without assigning a German level. The review added the missing explicit non-certification note to the topic result; both flows now explain the limitation. | Pass |
| Safe timer, content loading, replay and Back | Monotonic timer, feedback pause, disposal/lifecycle guards; empty/error/retry, duplicate submissions, replay and delayed-audio Back tests. | Pass |
| Optional listening | German voice detection, replay, explicit text alternative and fallback on missing/failed audio. Text alternatives are reported separately. No microphone permission added. | Pass |
| Final user-directed structure and presentation | Start practice owns recall and pronunciation; Start Test owns recognition/listening; Profile provides a mixed-level vocabulary snapshot. Shared styled results, score highlights, progress bars, emoji animation and review guidance were accepted on the phone. | Pass |

Final automated verification after the review fix: **81 tests passed**, targeted analysis of **17 files: no issues found**. No screenshots or emulator were used.

## Scope clarifications

- The owner explicitly replaced the originally planned mixed lesson with separate recall practice and scored tests. This is an accepted scope change, not an unfinished duplicate lesson.
- Summaries/outcomes are account-scoped and saved locally. Bounded Firestore synchronization remains **M06**, and a durable progress dashboard remains **M07**.
- C2 currently has no approved scored questions and C1 has a very small sample. The test explains unavailable selections; the profile check excludes C1/C2. A comprehensive curriculum or validated overall German placement assessment is not delivered by this release.
- Typed recall and automatic grammar evaluation were not introduced, so accepted-alternative matching is not applicable.

No remaining implementation or phone-acceptance blocker was found for the agreed M04 scope.

## Release handoff

- Version: **1.0.5 (20)**.
- Release notes: [m04-play-release-notes.txt](m04-play-release-notes.txt).
- Signed bundle verification: [m04-release-candidate.json](m04-release-candidate.json), generated after the build checks pass.
- Production upload/publication: project owner will perform it; neither is claimed here.
- Administrative work: M04 changes are local on `work/m04`, not committed/pushed yet; GitHub issue #6 remains open. PR #17 is unchanged.
