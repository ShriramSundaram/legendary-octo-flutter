# M05 Play reminder hotfix — 27 November 2026

Candidate: **1.0.7 (22)**, replacing 1.0.6 (21).

The owner reported that a fresh Play installation could sign in, but could not open reminders or log out. Wireless logs from the actual Play installation confirmed `TypeToken must be created with a type argument` in `FlutterLocalNotificationsPlugin.loadScheduledNotifications`, called by notification cancellation. The configured `proguard-rules.pro` file was missing; the optimized release lost Gson generic metadata. Debug phone acceptance did not exercise this release-only path.

## Changes

- Added the notification plugin's Gson retention rules while keeping R8 and resource shrinking enabled.
- Android reminder cancellation now uses the native alarm path, including legacy notification ID 0, without reading the plugin's JSON cache. Obsolete plugin execution cache is removed so its boot receiver cannot restore legacy alarms; user reminder settings are preserved.
- Added native emergency shutdown that invalidates the active reminder owner and cancels alarms even if reminder storage cannot be parsed.
- Logout attempts Firebase sign-out even when reminder cleanup fails. Auth failures still surface as failures; unconfirmed reminder cancellation produces a warning after successful sign-out.
- Retry rebuilds a failed reminder binding. Failed restoration preserves saved settings.
- Added an isolated, nondebuggable release-check app, with its own package and storage, no internet permission and no Firebase initialization. It exercises the real plugin's repeated cancellation, fresh binding, recovery and cleanup after deliberately invalid settings. Runtime package guards precede any test writes.
- Ignored generated Kotlin compiler caches. Credentials and build outputs remain excluded from Git.

## Verification and delivery

All **109 Flutter tests** and **11 native clock checks passed**; targeted analysis reported no issues. The final optimized release ran successfully on the paired physical phone: all five checks passed, including repeated real-plugin cancellation, fresh initialization, Retry without resetting settings and cleanup after failed initialization. The separate package was nondebuggable, had no internet permission or Firebase initialization, and left the Play package version unchanged. Evidence: [phone release check](m05-hotfix-release-smoke.json). This does not replace a signed Play-update acceptance check.

Signed production artifact verification passed: **1.0.7 (22)**, 46.7 MiB, SHA-256 `ab7a60a63039caf6d907b18cf440b75b4a512f63b405b3060cd21ced46c68437`. The immutable bundle is `build/releases/1.0.7+22/app-release.aab`. Signing matches version 21; production package, Firebase initialization, expected receiver/permissions, approved catalog hashes and absence of private debug credentials/test entrypoint were verified. Evidence: [release manifest](m05-hotfix-release-candidate.json). Release notes: [Play text](m05-hotfix-play-release-notes.txt). Source changes are not yet committed or pushed.

The Play app is not replaced, uninstalled or cleared by this check. Existing versioned release artifacts are preserved. The owner uploads the new bundle; the currently installed Play version remains affected until updated. The previously accepted approximate 5–10 second notification delay is unchanged. Reboot/timezone, permission denial, account deletion and notification-tap acceptance gates remain open under M05.

## Full app acceptance

On 27 November the owner confirmed login, timer Start/Stop/Cancel and successful logout in the separate full **GermanReminder Test** debug installation. It uses the normal app entrypoint and separate Android storage; it is distinct from the optimized single-screen release check. The requested production rebuild completed and passed signing, production configuration, catalog and credential-exclusion verification. Its SHA-256 is identical to the earlier verified production artifact; the additional debug isolation tooling did not change production output. The upload copy is `build/releases/1.0.7+22/phone-accepted/app-release.aab`, recorded in the release manifest. Pending-reminder cancellation during account switch/deletion and the remaining M05 device matrix are still unconfirmed.

Upstream requirements: [notification plugin release configuration](https://pub.dev/packages/flutter_local_notifications/versions/17.2.4), [Gson TypeToken troubleshooting](https://google.github.io/gson/Troubleshooting.html).
