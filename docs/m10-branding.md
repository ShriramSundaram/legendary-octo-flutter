# M10 — German Reminder name and launcher icon

Owner approved 27 November 2026: display name **German Reminder**, with a space, and the light lavender GR flashcard/bell icon with italic serif lettering.

## Scope and acceptance

- Android launcher and visible app titles use German Reminder; iOS display name is aligned.
- Apply the exact approved light lavender artwork to legacy launcher icons and iOS icon assets. Preserve its lavender background for Android adaptive icons, with safe padding and a matching lavender base.
- Prepare a 512 × 512 Play Store icon and listing name for the owner's publication step.
- Preserve production application ID `com.sundaram.germanreminder.app`, namespace, Firebase app/project, signing configuration, backend data, authentication and APIs.
- Keep the notification status icon as a separate monochrome asset.
- Build a new signed production bundle with an incremented version; preserve earlier versioned release artifacts.
- Verify production label/package, signature, icon resources and absence of test credentials. Check launcher assets visually without taking screenshots.
- Store listing publication and final physical launcher appearance are pending until independently verified.

## Artwork provenance

The owner approved the light lavender concept generated using the built-in image generation tool. Prompt: stacked white flashcards, elegant purple italic serif GR, golden reminder bell, lighter lavender background. The owner rejected the subsequent cutout preparation; only the exact approved lavender-background image is used. Selected project assets are stored in the repository; rejected explorations are not included.

## Status

GitHub [#18 — M10](https://github.com/ShriramSundaram/legendary-octo-flutter/issues/18) created in milestone 1. App implementation and signed release preparation complete; store listing publication and physical launcher confirmation remain pending. No commit, push or Play publication is claimed.

## Implemented assets and configuration

- Exact approved source: `assets/app_logo.png`, SHA-256 `5abefdb2b3510e9f549b94362acb1b5f34d892dc7d250855ca9a83b67a6fbd06`. It is byte-identical to the approved light-lavender preview. Neither rejected cutout is included.
- Android display label: German Reminder. Debug/release-check labels are spaced consistently and retain distinct test suffixes.
- Existing unspaced visible route titles and iOS display name are aligned. Internal package names and identifiers remain unchanged.
- Android legacy/adaptive launcher assets and iOS AppIcon images regenerated using `dart run flutter_launcher_icons`; adaptive foreground uses the approved lavender-background artwork with 20% inset and a matching lavender base.
- Play Store asset: `docs/store-listing/m10-icon-512.png`, 512 × 512 opaque PNG, 260,870 bytes.
- All 109 existing Flutter tests passed after the branding edits. Launcher raster inspected visually; no screenshots were taken. Physical launcher appearance and an iOS build have not been verified.
- Release version: 1.0.8 (23), including the M05 reminder/logout hotfix. Earlier bundles remain preserved.
- Signed production bundle: `build/releases/1.0.8+23/app-release.aab`, 50,408,697 bytes, SHA-256 `9696ac6d58704e061f541678c8a081cbae4c3c63f660f35fcce31241cec33e18`. Signature matches the previous release; production label/package, packaged approved icon, expected receiver/permissions, approved vocabulary and absence of private test credentials were verified. Evidence: [release manifest](m10-release-candidate.json). [Release notes](m10-play-release-notes.txt).

## Store listing handoff

When publishing the update, open Play Console → Store listings → Main store listing. Set the app name to **German Reminder** and upload `docs/store-listing/m10-icon-512.png` as the app icon. Submit the listing changes with the new release. Publication remains an owner action; the ticket stays open until store and device appearance are confirmed.
