# M05 release review — 26 November 2026

Version **1.0.6 (21)** has been built and verified as a signed release candidate at the owner's request. This does not mark M05's remaining physical acceptance gates as passed.

**27 November update:** The owner found a reminder startup/logout regression in the Play installation. Its optimized release stripped Gson TypeToken metadata. Version 21 is affected; see [the hotfix review](m05-play-reminder-hotfix.md) for version 1.0.7 (22), release-check evidence and delivery status. Earlier signature/content checks did not cover this runtime failure.

## Owner acceptance and timing observation

- Owner accepted the new timer UI and its Start / Stop / Cancel flow, and reported that notifications arrive.
- Observed notification arrival roughly **5–10 seconds after the countdown reaches zero**. Owner explicitly considers this minor/nonblocking and asked to investigate later. This observation is recorded; no exact-alarm permission, scheduling-mode change or timing workaround was introduced.
- Owner also reported notifications working after “Force stops app.” The exact stop action was not independently verified. Treat this as a positive observation on the tested phone, not proof of delivery after Android Settings → Force stop on all devices.

## Acceptance review

| M05 requirement | Current evidence | Pending |
| --- | --- | --- |
| Delivery outside the Dart process and after reboot | Native AlarmManager/receiver implementation; owner reports notification delivery after closing/stopping the app. | Explicit normal reboot restoration/delivery check on the phone. |
| Safe permission denial, edits, timezone and invalid payloads | Dart scheduling/denial/failure/account tests and 11 native clock/delivery checks pass. Stable IDs/revisions and payload validation are implemented. | Explicit phone denial, changed-time/timezone and no-duplicate checks. |
| Correct tap destination after authentication | Cold-launch payload capture, verified-account gate, owner/revision/level/item checks and saved-word/M03 routing are implemented. | Individual foreground/background/cold-start and after-sign-in tap checks are not explicitly confirmed. |
| Account sign-out/deletion cancellation | Cleanup is awaited before Firebase sign-out/deletion. Unit tests verify clearing scheduled state and alarms; source review confirms the auth hooks. | Physical sign-out and disposable-account deletion checks. |
| Accurate force-stop/battery explanation | UI explains approximate delivery, normal closure/reboot and explicit force-stop restrictions. | No cross-device force-stop guarantee is made. |

Final checks after updating the old onboarding timer instructions: **102 Flutter tests passed**, **11 native Java checks passed**, targeted analysis of **15 source/test files: no issues found**.

Implementation review found no new code blocker. The timing observation is an accepted follow-up. **M05 remains open because the physical acceptance checks above are still unconfirmed.**

## Release handoff

- Signed artifact verification: [m05-release-candidate.json](m05-release-candidate.json), generated only after build/signature/content checks pass.
- Release notes: [m05-play-release-notes.txt](m05-play-release-notes.txt).
- Owner will upload/publish; no production upload or Google publication is claimed.
- M05 checkpoint `180d077` was pushed to `origin/work/m05` and includes M04 checkpoint `5acf20b`. The subsequent Play hotfix is a separate working-tree change until committed. Issue #6 closure remains pending.

References: [Android alarm timing](https://developer.android.com/develop/background-work/services/alarms), [Android stopped-state behavior](https://developer.android.com/about/versions/15/behavior-changes-all#stopped-state).
