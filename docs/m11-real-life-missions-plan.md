# M11 — real-life German missions and streamlined learning navigation

Planning ticket: [M11 #19](https://github.com/ShriramSundaram/legendary-octo-flutter/issues/19).

**Required revision:** sessions must persist in the cloud and restore after reinstall/sign-in to the same account. The owner chose the M11 pilot first, then shared [M06 cloud recovery](m06-cloud-session-recovery-plan.md) before production. Device-only resume is not sufficient for M11 acceptance.

Planning requested 27 November 2026. **Pilot implementation authorized; final content/UI and cloud-release acceptance remain pending.** This ticket delivers the missions slice of [L03 #14](https://github.com/ShriramSundaram/legendary-octo-flutter/issues/14); navigation/design cleanup stays coordinated with [UI01 #16](https://github.com/ShriramSundaram/legendary-octo-flutter/issues/16). No additional standalone UI ticket is needed. This proposal does not mark M06–M09 complete or add a delivery date.

## Outcome

Help a learner apply German to everyday situations through short, purposeful conversations. Missions complement the existing recall practice and vocabulary tests. Their value is choosing a useful response in context and understanding the result; they do not repeat Reveal / Again / Remembered as another lesson mode.

## Placement and navigation cleanup

Bottom navigation becomes **Home | Learn | My words | Profile**, with visible text labels and accessible touch targets.

- **Home:** daily goal/progress, one due-review action, timer controls. Remove the middle Explore learning library button and the book icon beside Logout. Remove duplicated welcome/instruction blocks; use a simple title. Logout remains available. The timer remains on Home rather than being duplicated in learning screens.
- **Learn:** one destination titled Learning library, with **Words | Missions** tabs. A single shared A1–C2 level selector applies to the current Learn view. Do not repeat level pickers on the mission detail screen.
- **Words:** existing topic cards, German/English search, expandable meanings/examples/audio and clearly scoped Practice selected topic / Test selected topic actions. Full offline vocabulary remains reachable from this view. The old generic-word navigation destination is consolidated here so it does not become a second library tab.
- **Missions:** scenario cards grouped by selected level. Each shows a clear task, approximate duration, number of steps and honest Not started / In progress / Completed state. A completed mission can be replayed.
- **My words:** personal vocabulary only. **Profile:** preferences, account controls and the existing quick vocabulary check. Do not add a second copy of the quick check in Missions.

Home owns the full daily-goal and seven-day dashboard. Remove the repeated full progress dashboard and lengthy instructional copy from Learn. Show only a contextual mission/word status where it helps the current action. Practice and Test actions belong to Words; do not leave those unrelated controls pinned over the Missions view.

## Example interaction

Learn → Missions → A1 → **Order at a café**

1. Short situation: you would like a drink and a snack. One concrete objective and Begin / Continue action.
2. A barista message appears in a dialogue bubble. The learner chooses one of a few plausible responses. Controls provide a text alternative to audio.
3. The conversation continues with a follow-up, such as size or eating in/taking away. The chosen response remains visible in the dialogue.
4. An optional listening step uses device German TTS; replay and an explicitly labeled text mode remain available. No microphone or paid AI is required for the first version.
5. Result: show what was practised, choices that need another look, concise explanations and a few useful words/phrases. Link those words to the existing review experience, rather than adding another recall stage inside Missions.

Use ten conversational exchanges per mission, with a 6–8 minute estimate as a guide rather than a deadline. The owner expanded the scope to five missions on each A1–C2 level. Give feedback immediately after submission and wait for Continue. Incorrect choices get a supportive explanation and another chance; no artificial lives or shame messages. Make scored first choices and retries distinguishable if a score is shown.

## Expanded content pack

Owner-requested scope: five missions per A1–C2 level, ten conversational exchanges each. All 30 are implemented as labeled draft previews; editorial approval is pending.

| Level tag | Five missions |
| --- | --- |
| A1 | At the café; A small shopping trip; Meet your course partner; Find the station; Check in at the hotel |
| A2 | Catch your connection; Dinner with a friend; Return a jacket; Plan a weekend outing; Arrange a delivery |
| B1 | View a shared apartment; Arrange a routine appointment; Follow up on an application; When the train is cancelled; Organize a neighborhood event |
| B2 | A job interview; A productive team meeting; Resolve a purchase problem; Plan a realistic project; Discuss a news report |
| C1 | Negotiate a workable scope; Discuss a research presentation; Clarify a workplace misunderstanding; Contribute to a public consultation; Discuss a novel with others |
| C2 | Weigh a proposal; Discuss an editorial; Explore a literary passage; Mediate a disagreement; Refine a formal agreement |

The same engine runs all levels. The original five-step café is archived for compatible saved-session recovery. Level tags guide complexity and are not certified CEFR assessments. Bundled draft scenarios are playable only in the debug preview; production excludes them until approved.

## Interactive design requirements

- Match the approved light-lavender GR identity with warm accents, readable dark text and clean card spacing.
- Use small scenario illustrations/icons, dialogue bubbles, clear selected choices, an accessible step indicator and restrained completion animation. Respect reduced-motion settings.
- Keep one obvious next action, one short instruction per step and comfortable tap targets. Avoid screens dominated by explanatory paragraphs.
- Preserve progress after interruption and expose Continue mission. Let learners leave without losing completed steps.
- Show whether a checkpoint is Saving, Synced, Waiting for connection or needs Retry. Restore the last server-confirmed checkpoint after reinstall; do not label local-only changes Synced.
- Keep all levels discoverable; offer useful empty/loading/retry states. No paid locks or fabricated mastery/streaks.
- Explain pronunciation/listening fallbacks when needed. Do not claim an accent or speaking assessment from TTS or text-based choices.

## To-do / action checklist

- [x] Agree the Home/Learn/My words/Profile map and Words/Missions tab placement.
- [ ] Complete M06 cloud save/restore for existing sessions and M07 progress, including same-account reinstall recovery and migration of data still present on the device.
- [x] Remove the duplicate library routes and consolidate generic offline vocabulary under Words; preserve personal-word navigation and timer behavior.
- [x] Reduce repeated headings, instructions, full progress cards and duplicate actions. Verify a learner can identify where to go without guessing icons.
- [x] Define versioned mission, step, choice, explanation and referenced-word IDs. Keep authored content separate from private attempt state.
- [x] Implement one end-to-end café mission using reusable dialogue/choice/audio components and a concise result screen.
- [ ] Save mission ID/content version, stable attempt ID, cursor and choices through the shared per-account local/cloud checkpoint layer; make interrupted/reinstalled resume and duplicate completion safe. A failed write must not silently erase progress or claim cloud confirmation.
- [ ] Record mission completions separately from M07 recall-review totals. Replaying a saved completion must not duplicate credit. Coordinate cloud upload/conflicts with M06; never sum retried summary snapshots blindly.
- [x] Author 30 original scenarios with explanations, text alternatives, rights/provenance and four linked vocabulary entries each.
- [ ] Obtain editorial approval of all new mission/vocabulary wording before release inclusion.
- [x] Connect useful mission words to the existing review flow. Preserve Start practice, Start Test and Profile quick check as distinct existing functions.
- [x] Test duplicate/stale submissions, resume after restart, failed saves, version changes, offline content, audio fallback and two-account isolation.
- [ ] Test navigation for exactly one canonical Learn destination, all A1–C2 selections, 320px width, large text, keyboard/screen-reader use and reduced motion.
- [ ] Run existing login/App Check, review, quiz, timer and profile regressions. Validate on the wireless phone without screenshots or an emulator.
- [ ] Obtain owner content/UI acceptance, then prepare a versioned bundle/release notes and record the remaining M06/M08/M09 dependencies.

## Boundaries and dependencies

M03/M04 supply reusable review/test behavior; M07 supplies the honest progress display; M06 owns cross-device synchronization. Wider rollout retains the existing M08 privacy and M09 release gates from L03. The first authored, bundled/TTS implementation adds no paid AI or commissioned media service. Recorded audio/video, microphone assessment and open AI conversations stay in their own later scopes.

The expanded 30-mission preview is implemented. See [expanded content progress](m11-expanded-content-progress.md) and [initial pilot history](m11-pilot-progress.md). M11 remains open for M06 cloud recovery, content/UI approval and release gates.



## Release inclusion decision
On 27 November 2026 the owner explicitly approved including the thirty missions and 280 added vocabulary entries in the production bundle. Current scope, validation and remaining device-only progress limitation are recorded in [release review](m11-release-review.md). Cloud recovery remains pending under M06; M11 is not closed by preparing this artifact.
