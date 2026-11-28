# Android CI

The `Android CI` workflow runs on pushes to `master`, pull requests targeting
`master`, and **Actions > Android CI > Run workflow**. It uses Flutter 3.32.5,
Temurin JDK 17, and the repository's Gradle 8.12 / AGP 8.7.3 / Kotlin 2.1.0
configuration. Android SDK 36 and NDK 27.0.12077973 are installed explicitly.

The workflow resolves `pubspec.lock` without allowing dependency changes, runs
Dart analysis and all tests in `test/`, then builds debug APKs for arm64-v8a,
armeabi-v7a, x86 and x86_64. Analyzer errors fail CI; existing warnings and information
remain visible without blocking builds. Formatting is not currently a gate.

## Download and install

Open a successful run in the repository's **Actions** tab and download the
`german-reminder-debug-<run>-<attempt>` artifact. Extract the archive and install
the APK matching your device (usually `app-arm64-v8a-debug.apk`). Artifacts expire
after seven days; a manual run regenerates them. No emulator or device is needed
by CI. Superseded runs for the same branch or pull request are cancelled.

These APKs use the runner's disposable Android debug signing key. They cannot
update the Play-signed app; use a separate test device/profile or uninstall the
existing app first (uninstalling removes its local data). The signing key may
change between runs. Firebase App Check uses the debug provider in these builds:
protected backend calls require separately registering the device's generated
debug token in Firebase. CI does not inject or publish debug tokens.

## Release signing

This workflow requires no repository secrets and does not build signed release
bundles or deploy to Play. Continue using the existing local release process
with ignored `android/key.properties` and the upload keystore. Do not add either
file to Git or artifacts. A future signed release workflow should be a separate,
manually approved GitHub environment with restricted branch access and secrets
for the base64 upload keystore, alias, key password and store password. No such
secrets need to be configured for this workflow.

Actions are pinned to full commit hashes. Flutter/pub and Gradle dependencies
are cached; APKs alone are uploaded, never the workspace or signing files.

CI uses Google's public Maven Central mirror, including for Flutter's included
Gradle plugin build. Google Android and Gradle Plugin Portal repositories remain
available. The init script is installed only on the disposable runner; local and
release builds keep their existing repositories. Dependency HTTP 429/502/503/504
failures receive up to two retries with 30/60-second delays. Other build failures
fail immediately, and exhausted retries still fail the check.
