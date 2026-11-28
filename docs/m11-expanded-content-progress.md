# M11 expanded offline missions — 27 November 2026

The expanded test pack provides five missions per A1–C2 level, ten exchanges per mission: 30 missions, 300 decisions and 600 dialogue turns. Each includes two TTS listening steps with text fallback, contextual reply choices and explanations. These are authored practice scenarios, not a certified level assessment.

## Vocabulary and navigation

Browse all offline vocabulary is the first action in the Words content view. Offline vocabulary and My words share the same search field, selectable card list and speech control. My words retains account ownership, migration and bounded Firestore pagination; searches explicitly cover loaded words, with Load more available.

The supplement adds 120 unique vocabulary entries: 58 nouns with article/plural and 62 useful expressions, twenty entries per level. Each mission links four entries with German examples and English translations. The preview offline deck contains 1,448 entries; the existing 1,328 approved entries are preserved. New wording is original AI-assisted material and remains draft pending owner editorial review. Debug previews show a label; production excludes draft content.

## Follow-up goals and saved sessions

- Finishing a mission shows its objective, first-choice result, explanations and a four-entry review goal.
- The goal links directly to existing Reveal / Again / Remembered practice, scoped to those entries. An existing unfinished review resumes first rather than being replaced.
- Goal progress derives from persisted recall answers after mission completion. Opening results, revealing text and answering dialogue choices award no recall credit. Both honest Again and Remembered ratings count towards completing the follow-up activity.
- Home shows completed missions and pending mission review goals separately from the daily recall goal. Starting a replay preserves the previous completed goal in history. The latest completion supplies the current goal for each mission.
- Optional early mission practice preserves a future due date/interval for Remembered; Again still schedules a short retry. This behaviour survives review-session restart.
- The original five-step café definition remains archived. Its unfinished attempt resumes against version 1; after completion, the expanded version 2 starts a new attempt without deleting the old result. Unknown/incompatible versions preserve the saved data and show an error.

## Local content size

| Text asset | Raw bytes | gzip bytes |
| --- | ---: | ---: |
| 30 missions | 189,232 | 42,437 |
| Original café archive | 3,394 | 1,189 |
| 120 vocabulary entries | 119,869 | 15,965 |
| Total | 312,495 | 59,591 |

This is about 305 KiB raw / 58 KiB gzip for the complete mission-related pack, including the earlier café. gzip is a content-size estimate, not the Play download size. The previous production bundle was about 48.2 MiB; no new production bundle is claimed. Device TTS avoids bundling recorded audio. Recorded audio, pictures and video would need a separate size budget.

Bundle public text for offline use; Firebase remains necessary for private account data and future cloud progress recovery. Bundling content does not solve uninstall loss of locally saved sessions. No shared content was uploaded, removed or changed in Firebase for this expansion.

## Validation and remaining gates

Full regression suite: 136 tests passed before the final replay-goal refinement. Final affected mission suite: 17 tests passed, including replay-goal retention and real Hive version migration/account isolation. Analysis: no issues found across 20 affected files. Existing approved vocabulary, quizzes and branding remain unchanged.

M06 cloud upload/restore, expanded content/UI acceptance and M08/M09 release gates remain open. M11 is not production complete. No production publishing, commit or push was requested for this expansion.

Rebuild authored assets with Node using tools/build-mission-pack.cjs. Editable source dialogues are in tools/content/m11-A1.txt through m11-C2.txt. The generator preserves previous mission definitions when their content changes and checks per-level coverage and vocabulary links. Machine-readable counts and sizes: docs/m11-content-pack-report.json.

## Wireless candidate

German Reminder Test 1.0.11 (26), separate debug package com.sundaram.germanreminder.wirelesstest. Initial wireless update and launch succeeded; the Play app stayed at 1.0.9 (24), with no uninstall or data clearing. The final candidate includes immediate Home goal-count refresh and Show all mission goals.

Measured compressed lengths inside the test APK: missions 53,458 bytes, archive 1,277 bytes, vocabulary 19,455 bytes; total 74,190 bytes (72.5 KiB). The gzip estimate above uses a different compression method and is not the APK measurement. Production download size has not been measured for this pack.

Phone acceptance: Learn → Words → Browse all offline vocabulary; My words search/cards; Learn → Missions → any A1–C2 level (five cards); complete a ten-exchange mission and follow its review goal; leave/reopen a mission; return Home to inspect pending review goals. Existing café sessions may first resume the archived five-step version. Full new content/UI acceptance is pending the owner.

The final goal refresh polish passed the seven-test mission-pack suite and separate two-file analysis. Installation evidence is recorded in docs/m11-expanded-wireless-candidate.json.

Learning sounds and spoken activity cues are added in candidate 1.0.12 (27). See [audio behaviour and verification](m11-learning-audio.md). The final regression suite now has 143 passing tests.
