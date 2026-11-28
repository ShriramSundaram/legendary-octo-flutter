# Production release — German Reminder 1.0.15 (30)

On 28 November 2026, the project owner reported that version 1.0.15 (30) is in production. This records the owner's confirmation; Google Play publication was not independently checked by the agent.

The signed release bundle is recorded in docs/m11-release-candidate.json, SHA-256 7438d6e967c3dffaa37ae8fa89ab85cf979e963301705a0ee89abf350f1aa12f. That file is the historical build-time snapshot, before this source commit and before the owner's production confirmation.

This source checkpoint includes the M05 optimized-release reminder/logout fix, M07 daily goals and progress, M10 German Reminder branding, and M11 navigation, thirty missions, 280 added offline vocabulary entries, follow-up review goals and learning audio. Validation for the release: 151 Flutter tests passed, targeted analysis clean, signing certificate matched the preceding release, approved packaged content verified and private debug credentials excluded.

M06 cloud save/restore remains unimplemented. Learning progress is account-separated on the device; production publication does not complete M06 or the dependent M07/M11 cloud acceptance criteria. Remaining M05/M09 physical checks retain their documented status.

Release notes: docs/m11-play-release-notes.txt. App bundle, mapping, promo videos, local tools and credentials remain in ignored local directories. They are not part of this source checkpoint.
