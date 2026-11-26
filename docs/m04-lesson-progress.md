# M04 — recall practice, topic tests and a profile vocabulary check

Feature complete locally on `work/m04`; reviewed for release on 26 November 2026. PR #17 remains unchanged. The owner accepted all functional phone checks on **1.0.5+19** and the results styling on **1.0.5+20**. The signed **1.0.5 (20)** app bundle and release notes are ready for the owner to upload; no production upload has been performed.

## Distinct purposes

- **Start practice** owns recall: German word card, Hear pronunciation, Reveal meaning, Again/Remembered and the existing M03 schedule/resume behavior. Pronunciation is inside the card below the German word and never reveals the English meaning. Missing audio leaves recall usable.
- **Start Test** replaces Start topic lesson. It uses the selected level/topic, up to five words with approved questions, and meaning recognition plus listening only. There is no recall activity or recall-only fallback. A selection without reviewed questions explains that tests are not available yet.
- **Profile → Quick vocabulary check** samples twelve distinct approved questions: three each from A1, A2, B1 and B2. Results show the observed vocabulary sample by level and suggest where to practise. This is not a full German/CEFR placement test: grammar and speaking are not assessed, and the current C1/C2 question bank is insufficient.

## Test feedback and next steps

Every submitted answer shows the correct response and reviewed explanation before advancing, including the final question. Correct, wrong and unanswered totals count submissions only. A selected but unsubmitted answer remains unanswered at timeout.

The result now contains **What was tested**, recognition/listening results, **Review next**, the actual missed/unanswered words and a Start practice shortcut. Text alternatives are reported separately from listening. A listening answer requires playback or an explicit text alternative before submission.

The profile check's practice suggestion is the lowest sampled level with a missed/unanswered question, provided there are at least three questions at that level. All-correct samples suggest exploring more B2 vocabulary without assigning a B2 level. The suggestion never overwrites the user's chosen profile level.

## Retained safeguards

- Quiz time uses a monotonic stopwatch and pauses during feedback. Replay creates a fresh test. Back navigation disposes timers/audio; incomplete tests are not recorded as completed.
- German voice availability, replay, text alternative and Android TTS visibility are supported without microphone permission.
- Completed summaries/outcomes are account-scoped local Hive records under `practiceSessionsV1`, with duplicate protection, a 50-session limit and retry on save failure. M06 owns cloud sync; M07 owns the progress dashboard.
- Tests do not overwrite the separate M03 saved session or modify scheduling from quiz scores. Start practice retains any existing resumable review session.
- Credentials, private APKs and scratch files stay ignored. No screenshots or emulator are used.

## Results styling

Both test flows share a gradient score header with a prominent score/percentage, colored correct/wrong/unanswered cards, skill and level progress bars, grouped review words and clear action buttons. A single emoji gently pops in: celebration for all-correct samples, encouragement for other results, and an hourglass for timeout. Animations respect reduced-motion settings. Cards stack for small screens and large text. Scores, recommendations, grading and storage behavior are unchanged.

## Verification

Functional version **1.0.5+19** was installed wirelessly with `adb install -r`, preserving application data. Launch and App Check validation succeeded, and the owner accepted all functional phone checks.

Results refinement **1.0.5+20** was installed wirelessly, preserving data; launch, package version and App Check validation succeeded. The owner accepted the styling. Final acceptance review added the explicit non-certification note to topic results: **81 tests passed**, targeted analysis of **17 files found no issues**. The production AAB is signed with the same certificate as the previous release, has the expected approved bundled content, and excludes the private debug credential. See [release manifest](m04-release-candidate.json) and [completion review](m04-completion-review.md). No screenshots were taken.

## Phone acceptance — accepted

1. Learning library → Start practice → word card → Hear pronunciation. Check replay, Reveal meaning and Again/Remembered. Leave and resume the saved session.
2. Library → Start Test. Confirm only meaning recognition and listening appear, with no Reveal meaning/Recall activity.
3. Submit a wrong answer and read its correction/explanation. Try audio replay and Use text question.
4. Finish the test. Check What was tested, separate text-alternative results, Review next words and Retake test.
5. Profile → Quick vocabulary check. Check the twelve-question A1–B2 sample, per-level results and practice suggestion.

Owner confirmed the functional experience and results styling work. No pending implementation or phone-acceptance item remains for the agreed M04 scope. Administrative work remains: commit/push the local M04 changes and close GitHub issue #6. Production upload/publication will be performed by the owner. Cloud synchronization and the progress dashboard remain M06/M07.
