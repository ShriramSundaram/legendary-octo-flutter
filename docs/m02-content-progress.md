# M02 reviewed content and library

Started 2026-11-25. Completed and GitHub issue #4 closed on 2026-11-26 after
reviewing the owner's accepted scope, implementation and phone acceptance.
The owner reported uploading M02 1.0.3+16; Google publication is not independently
verified. The combined signed M03 1.0.4+17 bundle is now ready for the owner's
production upload. Historical draft/build notes below describe earlier checkpoints
and are superseded by this status. See `docs/m02-closure-summary.md` and
`docs/m02-m03-issue-closure.json`. No M02 implementation points remain.

## Owner-approved offline delivery — current status

The owner accepted the content and explicitly requested offline inclusion on
2026-11-25. This supersedes the earlier independent-review publication gate
for this delivery; no independent language review or CEFR certification is claimed.
`docs/m02-owner-approval.json` records the actual approval basis, stable IDs and
catalog hashes. All 269 structured entries and 55 quiz questions are published
in the app catalogs. A1 has 157 entries, A2 25, B1 30, B2 26, C1 16 and C2 15.

The 1,059 original legacy entries are bundled separately in
`assets/legacy_vocabulary_v1.json`, retaining all 1,060 source positions and
original strings (one exact duplicate collapsed). Source paths, warnings and
possible same-level matches remain traceable. They are owner-approved legacy
vocabulary, not fabricated example-rich starter entries. Same-lemma senses are
not automatically merged. `docs/m02-offline-reconciliation.json` records complete
source reconciliation; no live Generic or User documents were changed.

Home cards and the shared vocabulary browser now use the same offline loader
for 1,328 source-distinct entries. The learning library retains the richer 269
structured entries and links to the searchable combined offline browser.
Vocabulary loading requires no Firestore access, prior cache warming or download.
Existing authenticated users can browse offline; first-time login, password
reset, personal-word writes and future progress synchronization still need their
own connectivity handling. German audio depends on the device's installed voice.

Publication validation passes, 44 Flutter tests pass, and targeted Dart analysis
reports no issues. The cold bundled-asset test runs without Firebase initialization.
Version 1.0.3+16 is the next release candidate. Physical airplane-mode checks and
Play rollout evidence remain outstanding; M01's deferred checks remain separate.

The final debug APK built successfully, wireless `adb install -r` returned
`Success` without uninstalling, and opening MainActivity returned `Status: ok`.
Follow `docs/m02-offline-phone-checklist.md` for the final offline acceptance.
No screenshots were taken and production App Check enforcement was unchanged.

The signed release app bundle also built successfully (45.6 MB) at
`build/app/outputs/bundle/release/app-release.aab`. Its packaged content was
checked: 269 structured entries, 55 quiz questions and 1,059 legacy entries.
`docs/m02-release-candidate.json` records its SHA-256 fingerprint and verification
status. It has not been uploaded to Google Play. M02 implementation is ready;
the milestone remains open pending rollout.

The user confirmed phone acceptance ("Works great") and authorized Play rollout
on 2026-11-25. The browser and Computer Use runtimes both failed to initialize
with `failed to write kernel assets` / `os error 3`, so no Play upload or contact
settings changes were performed. The user also requested removal of personal
public contact details; a replacement public support email is needed. Required
developer-profile identity/contact disclosures depend on account/trader status
and must not be replaced with false information. Manual rollout instructions and
release notes are ready; the release artifact itself is unchanged.

## Changes and acceptance checklist

- [x] Shared bundled catalog schema and loader for A1, A2, B1, B2, C1 and C2.
- [x] Home toolbar entry to a learning library with level and topic filters.
- [x] Expandable word details: meaning, German example, English translation,
  noun article/plural and usage notes; visible counts and starter-pack wording.
- [x] Content IDs, versions, source/rights fields and editorial signoff fields.
- [x] Validate duplicate IDs/level-lemma pairs, required translations and noun
  metadata; exclude draft, quarantined and merely reviewed items from published UI.
- [x] Draft 150 A1 items across 10 practical topics (15 per topic), and 15 sample
  entries each for A2/B1/B2/C1/C2: 225 total. Content and CEFR tags await review.
- [x] Add 44 draft vocabulary items needed by the corrected legacy quiz, bringing
  the catalog to 269: A1 157, A2 25, B1 30, B2 26, C1 16, C2 15.
- [x] Debug-only, clearly labelled draft preview; release UI excludes drafts.
- [x] Visible level chips replace the collapsed dropdown. Header and topic
  controls scroll with the list to support narrow screens and large text.
- [x] Publish the owner-approved 157 A1 entries with recorded approval metadata.
- [x] Record the owner's content acceptance and original-writing declaration;
  do not claim independent language review or certified level assignment.
- [x] Include owner-approved starter samples for all other levels.
  No full CEFR coverage or higher-level word count is claimed by this iteration.
- [x] Complete a correction-draft pass on all 55 legacy quiz questions, retaining
  originals and attaching stable question/content IDs, explanations and metadata.
- [x] Record owner approval for the 55 corrected quiz items and publish them.
- [x] Validate quiz schema, unique IDs, four distinct options, integer answer
  indices, level/content references, correct-answer identity and publication signoff.
- [x] Read-only inventory of all 5 live Generic documents: 1,060 source rows,
  1,059 distinct candidates and one duplicate. Originals retained; candidates
  initially quarantined for review, then approved by the owner for offline inclusion.
- [x] Bundle and reconcile all original legacy entries; switch shared home/browser
  reads to local assets and add an all-vocabulary link from the learning library.
- [ ] Physical-device verification and next Android release, after content signoff.

## Editorial workflow

Run `node tools/build-content-review.cjs` after preparing the local legacy queue
to create `.local-tools/m02-content-review.html`. Open it locally for searchable
review of all 269 vocabulary drafts, 55 quiz drafts and 127 priority legacy
candidates (48 formatting/diacritic flags plus 79 possible catalog overlaps).
`docs/m02-review-manifest.json` records exact input hashes, counts and the owner's
original-writing declaration. The review page has no network calls or save action.
Record actual reviewer decisions by stable ID; it does not grant approval or
modify source/catalog/Firestore data. Dot-below removal is an unapproved spelling
proposal only, retaining umlauts; original marks may encode pronunciation.

Edit `assets/content_catalog_v1.json`. Keep unapproved rows as `draft`.
All 269 catalog rows are original project drafts, not scraped material. The additions
are AI-assisted and their level tags are provisional. Source additions live in
`docs/content/m02-drafts.psv`; `tools/import-draft-content.ps1` imports missing
rows without overwriting existing items or editorial decisions.
The additional quiz words are in `docs/content/m02-quiz-vocabulary.psv`; use
`tools/import-draft-content.ps1 -SourcePath docs/content/m02-quiz-vocabulary.psv`.
Rights text explicitly remains pending. A reviewer must check it rather than
simply copying the existing draft rights statement into a published row.

`dart run tools/validate-content.dart` validates the working catalog.
`dart run tools/validate-content.dart --publish-ready` additionally refuses
drafts or an empty catalog. The release library only displays `published` rows.
Debug builds additionally show draft rows with an explicit review-pending banner.
The 150-word target is an initial A1 pack, not complete A1 coverage.

The library works offline from bundled assets and adds no Firestore reads.
The existing random vocabulary and legacy quiz remain separate during this
initial implementation. Legacy content has not acquired reviewed status.
Learning-state scheduling remains M03; Firestore review-state sync remains M06.

## Quiz audit queue

`docs/m02-quiz-audit.json` retains every original question, option and answer
index, and now links the corrected proposal to a stable item/question ID.
`assets/quiz_catalog_v1.json` contains 55 corrected drafts and explanations.
Authoring corrections are in `docs/content/m02-quiz-corrections.psv`.
`tools/prepare-quiz-drafts.ps1` regenerates drafts while preserving previously
reviewed, published and quarantined records. Originals in `assets/quiz_data.json`
remain as an audit source; the app loader now uses the validated versioned catalog.

Corrections include lie/lie down, noun capitalization, preisgünstig,
kraulen/krabbeln, langweilig, besorgt/besorgen, gift/natural talent,
Hilfsmittel/medical remedy and tragfähig/nachhaltig. These are draft corrections,
not a claim of qualified editorial approval. Debug builds expose the drafts;
release builds expose approved questions only and handle empty/error states.
Explanations are stored for M04's answer-feedback interface. The misleading
CEFR recommendation was removed from the result display as an early safeguard;
M04 still owns full result/timer/session behaviour.

## Legacy Firebase content

`tools/inventory-legacy-content.cjs` rechecks the Standard eur3 database and reads
only the Generic collection. `docs/m02-legacy-inventory.json` records paths,
counts, update times, SHA-256 fingerprints and retain/quarantine decisions.
The untouched document snapshot is in ignored local storage:
`.local-tools/legacy-generic-snapshot.json`.

`tools/prepare-legacy-candidates.cjs` produces an ignored review queue at
`.local-tools/legacy-content-candidates.json` and a committed summary at
`docs/m02-legacy-pairing-summary.json`. Exact duplicate source rows share a
candidate but keep all original indexes. Three missing-space separators are
parsed and flagged without changing originals; no unresolved separator ambiguity
remains. Forty-five diacritic cases need review, and 79 candidates have possible
same-level matches to the draft catalog. These are suggestions, not automatic
merges. All 1,059 candidates still require language, provenance and rights review
plus examples and noun metadata before promotion. No Firestore documents were
changed, deleted or published by this work.

On 2026-11-25 the project owner confirmed in chat that the existing Firebase
German/English vocabulary is their own original writing. Source origin is now
recorded as owner-declared original material. This is not German editorial
approval or a change to candidate publication status. Preserve the original
snapshot and source indexes when reviewing language, examples and metadata.

## Current limitations

Wireless build attempt on 2026-11-25: `flutter run --release --no-pub
--no-resident -d 192.168.1.4:34087` built the release APK successfully in
62.2 seconds (21.3 MB). Installation was blocked by the phone with
`INSTALL_FAILED_USER_RESTRICTED: Install canceled by user`. Physical-device
UI validation remains pending. APK: `build/app/outputs/flutter-apk/app-release.apk`.
On retry, ADB installation returned `Success`. Launching MainActivity returned
`Status: ok`; Android's permission dialog was foregrounded. No screenshots taken.

Subsequent login testing failed with App Check `403 App attestation failed` on
the sideloaded release APK. A debug build using the existing `kDebugMode` App
Check debug-provider path was built and installed. Flutter automatically
uninstalled the prior APK on a signing mismatch; local preferences may have
been cleared. The ineffective temporary debug-signing override was removed.
Future signing changes must use a separate build plus `adb install -r`, which
stops on mismatches. Register the local App Check test secret using
`docs/wireless-testing.md`. The user subsequently confirmed successful login and
UI access after registering the debug token.

Validation on 2026-11-25: all 32 Flutter tests passed (including 7 catalog/UI
tests). Tests cover 225 draft entries, 150 A1 entries with 15 per topic, all six
levels, release-content filtering, example expansion, topic reset and a narrow
320 px screen at double text size. Working-catalog validation passed for the
225 draft entries; `--publish-ready` remains inapplicable because
editorial publication is still pending. The pre-existing unresolved optional
flutter_lints include still emits a formatter warning.

The expanded-vocabulary debug APK built in 190.4 seconds. ADB `install -r`
returned `Success` without uninstalling the existing debug app, and launching
MainActivity returned `Status: ok`. This update retains the existing App Check
debug-token registration and app data. User inspection of the updated library
is pending. Targeted Dart analysis reported no issues. No screenshots taken.

The release library will show zero reviewed words until approved rows are published.
The updated debug preview displays 269 draft words and 55 draft quiz questions.
No mock reviewer or fabricated signoff is supplied. Existing users can continue
using their current vocabulary. Do not release this iteration as a completed M02.

## Latest verification — 2026-11-25

All 40 Flutter tests passed, including the eight new quiz validation/loading
tests. Targeted Dart analysis reported no issues. Working validation passed for
269 vocabulary drafts and 55 quiz drafts, with zero published items; the legacy
parser/traceability checks also passed. The debug APK built successfully and
wireless `adb install -r` returned `Success`, preserving the existing debug app
data without uninstalling it. Launching MainActivity returned `Status: ok`.
No screenshots were taken. Editorial approval
and physical-device behaviour checks remain pending; M01's deferred manual
checks are in `docs/m01-phone-checklist.md`. M01 and M02 remain open.

## Parent design task

[UI01 / GitHub #16](https://github.com/ShriramSundaram/legendary-octo-flutter/issues/16)
owns navigation, visual components and the fuller library redesign. M03 and M04
retain review/lesson behaviour; no duplicate UI child tickets were created.
