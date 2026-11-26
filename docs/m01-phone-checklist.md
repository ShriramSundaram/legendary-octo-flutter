# M01 phone checks — user to perform later

Use the wireless debug build with its registered App Check token. No screenshots
or credentials are needed. Keep M01 open until the results below are recorded.

## 1. Two-account isolation

1. Sign in to a test account A. Save a unique word such as `M01 account A test`.
   Set a recognisable profile name and German level.
2. Sign out and sign in to a different verified test account B. Open Your words:
   A's marker must not appear. Its profile settings/photo must not appear either.
3. Save `M01 account B test` and different profile preferences in B.
4. Return to A: A's word and settings must reappear, B's must not.
5. In Firestore, check each account's own `User/{uid}/personalWordsV1` path.
   The Firebase Console is an admin view and can see both accounts; this is not
   evidence of an app isolation failure. Direct cross-account denial is already
   covered by the automated Security Rules tests.

## 2. Pagination

1. Use a test account with at least 51 distinct saved words. Existing words are
   fine; otherwise add clearly marked test words through the app.
2. Reopen Your words. The first page should contain at most 50 words and offer
   Load more. Tap it to load the rest; verify no gaps or duplicates.
3. Check the beginning and end of the list, reopen it and repeat. Document-ID
   ordering is used, so the order is not necessarily alphabetical.
4. At exactly 50 words, one extra empty fetch is acceptable before Load more
   disappears. Pagination must still not duplicate or lose any words.

## 3. Legacy migration reconciliation

1. Use an existing test account that already has `User/{uid}.wordStorage`.
   Record its contents before opening Your words. Do not overwrite that array.
2. Open Your words while connected. In Firestore inspect
   `User/{uid}/migrations/personalWordsV1`.
3. For a clean legacy array, expect `reconciled: true`, `invalidEntries: 0`, and
   `copiedWords == uniqueWords`. Count distinct exact strings, not total array
   length: duplicates collapse, while case and whitespace are preserved.
4. Confirm every original unique valid word exists in `personalWordsV1`. There
   can also be newer saved words, so the total V1 document count can be larger.
5. Reopen Your words. No duplicates should be created and the legacy array must
   remain unchanged. If malformed entries exist, the app must warn, retain the
   source, and keep `reconciled: false` until those entries are handled.
6. Optional interruption check: close and reopen during migration. It should
   resume safely and reach the same reconciled result without lost words.

## Record results

- Device/build and date:
- Account isolation: PASS / FAIL + notes (use A/B labels; no passwords)
- Pagination: PASS / FAIL + total words and observed page sizes
- Migration: PASS / FAIL + uniqueWords, copiedWords, invalidEntries, reconciled

Report those results in the chat; no screenshot is required. Do not remove
original data or test accounts as part of this checklist.
