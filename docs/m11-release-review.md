# M11 release candidate — 1.0.15 (30)

The owner explicitly answered “Include the new content” when asked about the thirty missions and 280 new vocabulary entries. That release-inclusion decision is recorded against the exact asset hashes in docs/m11-release-content-approval.json. It does not claim independent linguistic or CEFR certification.

## Included

- Thirty real-life missions: five per A1–C2 level, ten exchanges and three reply choices per step, listening/text alternatives, saved checkpoints and separate first-choice scoring.
- Mission-linked follow-up vocabulary review goals on results and Home, with existing saved review sessions preserved.
- 280 additional published offline vocabulary entries: 120 mission-linked entries plus 160 additional B1–C2 entries. Production structured catalog: 549 entries. Full bundled vocabulary: 1,608 entries.
- Consolidated Home / Learn / My words / Profile navigation, offline browsing at the top of Words and matching vocabulary search/card UI.
- Optional spoken activity introductions, distinct recall/outcome effects, correct-answer applause and a gentle wrong-answer effect. Independent device audio controls and outcome previews remain in Profile.

New content is published in production asset loading; future unapproved edits remain excluded. Unchanged content retains its editorial decision when regenerated. Stable content IDs and compatible saved sessions are preserved. Original source/quiz assets and the approved lavender icon remain unchanged.

## Validation

All 151 Flutter tests passed. Analysis of six affected Dart files is clean. Editorial preservation tests passed; regenerating the authored packs retained the exact owner-approved hashes. Release notes are 432 characters. Signed-bundle checks and exact artifact details are recorded in docs/m11-release-candidate.json after verification.

The production build uses the original application ID and production Play Integrity. Wireless-test/release-check modes and the private debug App Check credential are excluded. No credentials or distribution binaries are staged for Git.

## Remaining limitation

M06 cloud progress recovery is not implemented. Reviews, tests, goals and missions remain account-separated on-device data and do not recover after uninstall through cloud synchronization. The app and release notes disclose device-only progress. Building this candidate does not close M06/M11 or claim Google Play publication. The owner will upload the bundle; no rollout was performed.

## Production confirmation — 28 November 2026
The owner now reports 1.0.15 (30) is in production. See [production record](m11-production-release.md). The prior no-publication statement describes the bundle handoff; the agent did not perform or independently verify the Play rollout. Cloud recovery remains pending.
