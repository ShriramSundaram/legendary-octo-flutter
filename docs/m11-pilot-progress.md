# M11 pilot — 27 November 2026

The owner authorized the M11 pilot first, then M06 cloud recovery before production. This is a working first slice, not completion of M11/M06.

## Implemented

- One labeled Home / Learn / My words / Profile shell, lazy pages and retained tab selection. Returning Home refreshes goals; switching tabs dismisses the keyboard and stops shared TTS.
- Removed both duplicate library shortcuts from Home. Learn contains Words / Missions with one shared A1–C2 selector. Words retains search, topics, reveal/audio, practice/test and full offline vocabulary; its repeated full progress card and oversized header are removed.
- Home retains goals/review and the timer, with a single Reminder word card instead of identical flip-card faces. Personal-word creation is in My words.
- Five-step café pilot: coffee order, snack, takeaway, price listening and goodbye. Conversation bubbles, reply feedback, optional transcript, supportive retry and results distinguish it from recall practice. First choices and retries are reported separately. Text fallback is labeled; no microphone, paid AI or proficiency certification.
- Versioned per-account checkpoints save cursor, feedback and answers. Serialized revision checks reject stale screens; failed writes preserve the saved place.
- Replay creates a new attempt while retaining previous results in the atomic account-local `missionSessionsV1` ledger. The pilot preserves unsynced history rather than silently pruning it; exceeding 1,000 attempts/100 missions gives an error without erasing data.

## Validation and installation

**130 Flutter tests passed; analysis of 11 source/test files: No issues found.** Tests include restart, failed saves, retry scoring, stale pages, replay history, real Hive account isolation, navigation, listening fallback and 320px/200% text.

Full isolated debug app **1.0.10 (25)** installed wirelessly with Success and opened with Status: ok. Package/label/debug mode verified. Play package version unchanged; no app uninstalled or data cleared. [Installation evidence](m11-wireless-pilot.json). No emulator or screenshots used.

## Required gates

**Cloud recovery is not implemented or deployed.** The pilot explicitly labels device-only storage. Reviews/tests/progress also remain local; this build does not fix reinstall loss. Shared M06 migration, upload/retry, restore, owner rules and two-device/reinstall verification are required before production.

Café wording is draft, awaiting owner content/UI approval; release catalog loading excludes it. Other levels show an honest preparation state. The remaining A1–C2 pack and cloud-backed mission completion reporting are unfinished. M08/M09 release gates remain applicable. No production bundle, publication, commit or push is claimed.

Existing Firestore inventory: `germanreminderapp`, `(default)`, Standard edition / Firestore Native, region `eur3`. This pilot changed no backend database/rules/index/data. Billing plan and quota were not inferred from free-tier eligibility.

## Phone review

**German Reminder Test → Learn → Missions → A1 → At the café**. Try a wrong reply and retry; leave midway and Continue mission; try listening/text mode; finish and replay. Check the shared level selector, Words and bottom navigation. Review the German wording and explanations.

Content-only aid: `.local-tools/m11-pilot-content-review.html` (ignored local output). The approved lavender branding master is unchanged.

## Expanded preview update
The initial café-only status above is historical. The owner requested five missions per level, longer conversations, more offline words and post-mission review goals. These are now implemented in the expanded preview; see [current progress](m11-expanded-content-progress.md). Cloud recovery and editorial acceptance remain pending.
