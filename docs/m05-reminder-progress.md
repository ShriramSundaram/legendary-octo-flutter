# M05 — durable study reminders and timer UI

**27 November Play regression:** Version 1.0.6 (21) has a confirmed release-only reminder startup/logout failure. [Hotfix 1.0.7 (22)](m05-play-reminder-hotfix.md) adds Gson retention rules, native cleanup, working Retry and independent sign-out. The source checkpoint `180d077` is pushed to `origin/work/m05`; hotfix work is subsequent and uncommitted. Keep issue #7 open for the remaining acceptance gates.

Release candidate prepared on `work/m05`, based on the local M04 checkpoint **5acf20b**. M04's signed 1.0.5 (20) artifact is unchanged. Signed M05 **1.0.6 (21)** was handed off and the owner installed it from Play; it is now superseded by the hotfix work above. Full M05 physical acceptance is not yet complete; issue #7 remains open. No production upload/publication is claimed.

## Implemented

- Home timer redesigned with a gradient card, progress ring, live countdown, duration presets, a validated custom duration, Pause/Resume and cancellation.
- Countdown snapshots the selected offline word's stable ID and level. Changing the displayed word or editing a repeating reminder does not change that saved target.
- Optional repeating study reminders use a chosen local time, selected weekdays and review level. Defaults remain off. Notification permission is requested only when the user starts/enables reminders.
- Timer and preferences persist per account in Hive. The Android execution registry is private SharedPreferences; it stores opaque owner fingerprints, revisions, stable item IDs and scheduling fields, not credentials or word text.
- Android AlarmManager delivers independently of the Dart process. Inexact alarms intentionally avoid exact-alarm permission. The Dart Timer now only redraws the visible countdown; it never delivers a notification.
- A native receiver restores alarms after boot/package replacement and rebases weekday times after device timezone/clock changes. Calendar calculations use current Android zone rules. Spring gaps move forward; autumn overlaps fire once. Original weekday/hour/minute values are retained for subsequent weeks.
- Notification taps are handled in the foreground and from a cold launch, and queued until a verified account is available. Payload schema, owner, current revision, level and item ID are checked. Stale/cancelled/other-account payloads are ignored. Countdown reminders show the saved word; repeating reminders open M03 review for the saved level.
- Sign-out and account deletion cancel account-associated alarms and visible notifications before authentication is changed. A persisted suppression flag prevents automatic re-enabling after an interrupted cleanup.
- Stable IDs (2100 for countdown; 2101–2107 for weekdays), revision checks and native consume-before-display handling prevent duplicate broadcasts from producing repeat notifications. Missed study days do not produce a backlog.

## Compatibility and implementation choice

Notification plugin pinned to the existing **17.2.4**. Added direct **timezone 0.9.4** and **flutter_timezone 4.1.1**, compatible with the installed Flutter 3.32.5/Java 17 setup. Native Android scheduling is used so reboot, DST and timezone rebasing do not need a Flutter engine or access to private plugin scheduling caches. The existing notification plugin continues to supply permission handling and its pinned notification-tap contract. Android notification icon is referenced directly from native code so release resource shrinking can retain it.

Unused, ignored Windows/Linux/macOS generated scaffolding was preserved under `build/unused-platform-scaffolding` to avoid requiring Windows Developer Mode for Android dependency resolution. No source platform was deleted and no global Flutter/Windows setting was changed.

## Verification so far

- **102 Flutter tests passed**, including scheduling edits, permission denial, partial failure cleanup, account changes, persistence/pause/resume, stale/forged payloads and narrow/large-text timer layouts.
- Final targeted analysis of **15 source/test files: no issues found**. The old onboarding timer instructions were updated to match the new controls.
- **11 native Java clock checks passed**: normal scheduling, exact-deadline rollover, year rollover, spring gap and recovery, autumn overlap, timezone, invalid weekday and early/stale alarm rejection.
- Private **1.0.6+21** APK built and installed wirelessly, preserving data. Launch succeeded; package version and App Check acceptance were verified. Native registry was readable with zero pending reminders before user opt-in. Owner now reports successful notification delivery. The detailed remaining reboot/timezone/permission/account/tap-routing checks are recorded in the release review.
- No screenshots or emulator used. No new notification opt-in has been enabled on the phone by the agent.

## Phone acceptance — still required before closing M05

Owner accepted the main timer controls and reported successful notification delivery. A further **approximately 5–10 seconds** between countdown zero and notification arrival was explicitly accepted as minor/nonblocking and deferred for later investigation. No timing-mode change was made. Owner also reported delivery after “Force stops app”; the exact stop action was not independently verified, so this is recorded as a device observation, not a cross-device force-stop guarantee. Individual reboot, timezone, permission/account-cancellation and all tap-routing checks remain unconfirmed.

1. Inspect the home timer. Start a short timer, Pause, reopen the app, Resume and Cancel. Confirm only one timer is active and the saved word stays fixed while browsing other words.
2. Enable selected weekdays and save a time. Change the selection/time and confirm the old schedule is replaced. Check denial and re-enabling through Android notification settings.
3. Start a reminder, leave the app and test ordinary process death (not Force stop). Confirm one notification arrives, then tap it. Verify foreground/background/cold-start routing and sign-in gating.
4. With a future reminder saved, reboot the phone normally, unlock it and confirm restoration/delivery without first opening the app.
5. Change device timezone and confirm the selected local study time follows the phone, while a countdown retains its saved UTC deadline. Restore the original timezone after testing.
6. Sign out with a pending reminder and confirm alarms/notifications are cancelled. Check deletion only with a disposable test account; no personal account needs to be deleted for this check.

Android can delay inexact alarms, including while idle or under vendor battery restrictions. An explicit Force stop is not ordinary process death and delivery is not promised until the app is opened again. The UI describes the countdown as an approximate reminder window, not an exact alarm clock.

Primary references: [Android alarm scheduling](https://developer.android.com/develop/background-work/services/alarms), [Android stopped-state behavior](https://developer.android.com/about/versions/15/behavior-changes-all#stopped-state), [notification plugin 17.2.4](https://pub.dev/packages/flutter_local_notifications/versions/17.2.4), [device timezone 4.1.1](https://pub.dev/packages/flutter_timezone/versions/4.1.1).

## Signed bundle handoff

- Version **1.0.6 (21)**; signature matches the previous release; approved vocabulary hashes verified; private debug credential absent.
- Reminder receiver/restoration actions, notification icon and expected permissions verified in the release build. No exact-alarm or microphone permission requested.
- [Release manifest](m05-release-candidate.json), [release notes](m05-play-release-notes.txt), [acceptance review and remaining checks](m05-release-review.md).
- The owner will publish. M05 remains open until its remaining physical acceptance gates are verified.
