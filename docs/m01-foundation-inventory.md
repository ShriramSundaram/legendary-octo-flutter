# M01 learning-data foundation

Status: implementation and automated checks complete; Firestore rules deployed;
version 1.0.2 (15) published to Google Play. Wireless installation, login and
library UI access were confirmed. M01 remains open pending the recorded
two-account, pagination and real-account migration reconciliation checks.
Firestore rules deployed on 2026-11-25 at 10:47 IST. No production vocabulary was migrated by this deployment.

## Verified environment

Firebase project `germanreminderapp`, database `(default)`, Standard edition,
Native mode, region `eur3`. Firebase CLI 15.37.0 and Node 24.22.3 are installed
under `.local-tools` (ignored by version control). The workspace itself has no
Git metadata, so these changes have not been committed or pushed.

The deployed rules inspected on 2026-11-24 use a wildcard that allows all reads
and writes before 2030-10-26. Release ruleset:
`109f11dd-3448-4659-aed7-227f78e28f98`. Those permissive rules were replaced on 2026-11-25.
The tested `firestore.rules` is now active. Verified release ruleset: `9285087a-f243-4ae9-9332-a37ad0398736`. The CLI compiled and deployed the rules successfully, and the active source was read back.

## Schema and paths

- `User/{uid}`: original `wordStorage` array, retained without mutation. New
  rules permit owner document reads and deny all client writes and listing.
- `User/{uid}/personalWordsV1/{id}`: schemaVersion 1, immutable ID and lemma.
  IDs are `p_` plus SHA-256 of the exact UTF-8 text, preserving case, accents,
  and whitespace distinctions. One word per document; no review metadata.
- `User/{uid}/learningStateV1/{itemId}`: schemaVersion 1, itemId, dueAt and
  lastAttempt as Firestore timestamps (lastAttempt nullable), intervalSeconds,
  lapseCount, schedulerVersion. Dart normalizes times to UTC.
- `User/{uid}/migrations/personalWordsV1`: versioned reconciliation report with
  sourceDigest, uniqueWords, copiedWords, invalidEntries, and reconciled.
  Checkpoints confer no access privileges.
- `contentV1/{id}`: stable publisher-assigned ID, lemma, article, plural,
  meaning, example, topic, level, source, rights, editorialStatus, version,
  schemaVersion. Client reads require published status; clients cannot publish.
- `Generic/{level}`: retained legacy reference arrays, authenticated document
  reads only. No automatic promotion into reviewed content.

Repositories bind user operations to the account that opened the screen and
reject stale handles. The personal-word list clears when authentication changes.
Profile data uses UID-scoped Hive keys and photo preference keys. Old unscoped
profile values remain stored for manual recovery but are not attributed to a
newly signed-in account. Users must set their profile preferences again. This
avoids guessing who owns legacy device data.

## Migration and reconciliation

Opening Your words reads the legacy document from the server, then copies each
unique valid string using a create-if-absent transaction. Existing records must
match their deterministic identity; conflicting records stop the migration.
The source is never edited or deleted. Checkpoints are written at the start,
every 25 copied words, and after reconciliation. Every copied word is read back
from the server before reconciled can become true.

After interruption, replaying the source is safe. The checkpoint records progress
but is not used to skip validation: old clients may have modified the source.
Repeated runs verify existing records and include newly observed legacy words.
The digest covers sorted valid IDs and the invalid-entry count; it is a
reconciliation fingerprint, not a byte-level backup checksum. Concurrent runs
can replace diagnostic checkpoints, but cannot overwrite word identity or
learning metadata. The last completed report describes its source snapshot.

Non-string, empty, or over-10,000-character entries are counted as invalid and
left in the original array. Valid words are still copied. Such a report never
claims reconciliation; the screen explains that entries need repair. Missing
documents are treated as empty. A malformed whole array reports one invalid
entry. Production reconciliation remains to be performed on actual accounts.

Migration costs roughly two document reads per unique word plus one create for
new words and checkpoint writes. It revalidates on each opening during this
foundation phase. It requires connectivity; full offline synchronization is M06.

## Query and index requirements

All new collection queries use at most 50 documents:

| Query | Cursor/order | Index |
| --- | --- | --- |
| Personal words | document ID, startAfterDocument | built-in document ID |
| Due state | dueAt <= UTC now, orderBy dueAt | automatic ascending dueAt |
| Published content | editorialStatus == published, document ID | automatic editorialStatus index including document ID |

`firestore.indexes.json` needs no composite indexes for these queries. Keep
single-field indexes enabled. Legacy content and migration source use a single
document get; no unbounded collection scan remains. Future query combinations
must add indexes and bounded query tests before use.

## Verification

2026-11-24 results: all 25 Flutter tests passed, all 72 remote Rules checks
passed with no compilation issues, and targeted Dart analysis of changed code
and tests reported no issues. Formatting completed. The existing
`analysis_options.yaml` references `flutter_lints`, which is misplaced in the
original pubspec and cannot be resolved by the formatter; this check does not
claim the configured optional lint rules were applied.

Run Flutter tests with `flutter test --no-pub` using an SDK with writable cache.
The added tests cover interrupted migration/replay, exact-string preservation,
duplicate handling, later additions, malformed input, failed reconciliation,
stable IDs, schema rejection, UTC state validation, account isolation, and
preservation of unowned local values. Existing profile photo tests now exercise
account-scoped storage.

Run `.local-tools/node-v24.22.3-win-x64/node.exe tools/test-firestore-rules.cjs`
after Firebase CLI login. This uses the Firebase Rules test API with synthetic
requests and the proposed source, without deploying rules, writing documents,
or launching an emulator. Results are saved in `m01-rules-test-results.json`.
Tests cover owner/other/anonymous access, malformed creates and updates,
immutable words, legacy overwrite denial, curated read/write restrictions,
state validation, report consistency, query bounds, and unmatched paths.
Reference: https://firebase.google.com/docs/reference/rules/rest/v1/projects/test

These checks simulate rules evaluation; they do not replace a signed-in physical
device smoke test of the Flutter/Firestore integration and pagination.

## Rollout and rollback

Deploying the new rules stops older released apps from saving personal words:
those clients replace `User/{uid}.wordStorage`. The new app writes V1 documents
and does not initialize/reset the legacy document during signup. Existing
clients can still read their own legacy words and Generic reference content.
Coordinate the app release and this write cutoff before deploying. Deploy only
Firestore rules for this rollout, after confirming the target project; do not
use an unrestricted Firebase deploy command.

For rollback, retain V1 words, learning state, reports, and original arrays.
Do not delete V1 collections or restore the old public wildcard rules. Prefer a
forward fix or a read-only compatibility build. If returning to a legacy-only
reader, export and merge the union of original words and V1 lemmas with an
admin-controlled, audited process first; otherwise words added after upgrade
will be hidden. Retain a backup and reconcile counts before any destructive
cleanup. Old metadata and local profile values remain available for recovery.

The user approved the legacy-client write cutoff and the rules are deployed.
Remaining rollout gates: verify two-account isolation and pagination on the
physical phone, and inspect per-account reconciliation reports. M01
must not be marked production-complete before those gates pass.
