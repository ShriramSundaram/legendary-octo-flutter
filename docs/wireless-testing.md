# Wireless Android testing and App Check

## Local testing

Use a debug build for direct ADB installs. `main.dart` already selects the
Firebase App Check debug provider only when `kDebugMode` is true. Release builds
continue to use Play Integrity and should normally be tested via Google Play.

The M02 release APK installed directly on the test phone was rejected on login:
`403 App attestation failed`, followed by `Firebase App Check token is invalid`.
ADB reported `installer=null`. This is consistent with the sideloaded build
not receiving the Play-recognised verdict; server provider settings were not
inspected. Do not disable production enforcement to solve local testing.

Build the debug APK separately, then use ADB to install. ADB stops on signing
mismatches. Avoid `flutter run` when switching signing keys: it can uninstall
the existing application automatically, clearing local data.

```powershell
./tools/build-wireless-debug.ps1
adb -s <phone-IP:connection-port> install -r build/app/outputs/flutter-apk/app-debug.apk
```

The debug APK cannot be published to Google Play as a production release.

Use the wrapper for subsequent wireless builds. It passes the previously
registered credential through an ignored local `--dart-define-from-file` file,
without printing it. Omitting that define lets the SDK choose an installation
credential that may not be the one registered for this phone. Never pass this
file to a release build or upload the resulting private debug APK to Play.

On 2026-11-26 the M03 debug installation returned App Check 403 during login.
The saved test credential was independently accepted by Firebase's debug-token
exchange endpoint. The wireless rebuild now explicitly supplies that credential;
debug startup logs only whether validation succeeded, never the token itself.
Production provider selection and backend enforcement remain unchanged.

The corrected private debug APK rebuilt in 143.9 seconds and installed with
`adb install -r` returning `Success`. Restarting returned `Status: ok`, and the
app itself logged `Wireless App Check validation: accepted` on 2026-11-26.
The user subsequently confirmed successful login on 2026-11-26. No app data was cleared,
no debug secret was printed, and no screenshots were taken.
On 2026-11-25 the attempted opt-in upload signing did not take effect: APK
certificate comparison confirmed different debug and release certificates.
Flutter automatically uninstalled the previous test installation and installed
the debug APK. Local-only profile preferences/photos may have been cleared;
Firebase Authentication accounts and Firestore documents were not deleted.
The ineffective signing override was removed. Future replacements must stop
on a signing mismatch and obtain approval before deleting local app data.

## Register the test installation

The debug provider issues a test secret. Store it only in an ignored local file
such as `.local-tools/wireless-app-check-token.txt`, never in this document,
source code, screenshots or a production build.

1. Open Firebase Console, project `germanreminderapp`, App Check → Apps.
2. Open the Android app's menu → Manage debug tokens → Add debug token.
3. Name it `Wireless test phone`, paste the local test secret and save.
4. Close and reopen the test app, then retry login. No password reset is needed
   to resolve an App Check failure. User authentication and owner-only rules
   still apply after the test token is registered.
5. Revoke the test token when local testing ends.

Registering a debug token authorises that test secret to bypass device/app
attestation. Keep it private. Production Play Integrity enforcement stays on.

References:
- https://firebase.google.com/docs/app-check/flutter/debug-provider
- https://firebase.google.com/docs/app-check/android/play-integrity-provider
