# [P1][UI01] App navigation and learning experience design

Parent UI task requested after wireless M02 testing on 25 November 2026.
Created as https://github.com/ShriramSundaram/legendary-octo-flutter/issues/16.

## Problem and outcome

The learning library is currently a top-bar icon leading to a plain list and
collapsed level dropdown. Its zero counts and empty content do not explain the
draft workflow well. Make learning easy to find and comfortable to browse,
with a coherent visual language reused by review, lessons and progress.

M03 (#5) owns review-session behaviour; M04 (#6) owns lesson and quiz feedback.
Neither issue owns the overall visual design or library navigation. This parent
task supplies shared design decisions; it does not duplicate their feature work.

## Design direction

- Warm off-white surfaces, dark navy text and one teal accent; readable contrast.
- Consistent typography, 8/16/24 spacing, rounded cards and restrained elevation.
- A named Learn entry in primary navigation, instead of relying on a top-bar
  book icon alone. Keep account and saved-word access easy to find.
- Library header with level context and actual word counts; visible level pills
  for A1–C2, topic cards with meaningful icons, and search within the chosen level.
- Word cards emphasise article + German lemma, English meaning, then examples
  and translation. Keep plural/usage notes and German audio easy to discover.
- Distinct empty, loading, offline, error, draft-preview and reviewed states.
- Review and lesson screens reuse the components; progress is based on real
  recorded practice. Do not display fabricated streaks, mastery or completion.

## Work and dependencies

1. Define colours, type, spacing, reusable cards, buttons and state components.
2. Update home/library navigation and level/topic browsing from M02 (#4).
3. Apply shared visual components to M03 review and M04 lessons/feedback.
4. Integrate genuine goal/progress information when M07 (#9) provides it.
5. Verify navigation and accessibility during M09 (#11) wireless-phone testing.

## Acceptance criteria

- All supported levels are clearly discoverable and retain separate counts.
- A learner can enter Learn, choose a level/topic and inspect a word without
  understanding the app's implementation or content-review pipeline.
- Debug-only preview words are labelled pending review and excluded from release
  learner content. Approved starter packs do not claim complete CEFR coverage.
- No overflow at 320 px width or large system text; keyboard and screen-reader
  labels, tap targets, contrast and disabled states are usable.
- Loading/error/empty behaviour and level/topic/search changes have useful tests.
- Test on the wireless Android phone. Do not use an emulator or take screenshots.
- Keep this as one parent UI issue; use its checklist rather than create
  duplicate design issues for M03/M04. No CI or Firebase permission changes.

Plan: https://github.com/ShriramSundaram/legendary-octo-flutter/issues/2
