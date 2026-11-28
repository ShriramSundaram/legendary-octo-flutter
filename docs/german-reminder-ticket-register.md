# German Reminder published ticket register

Planning tickets published 24 November 2026. Current delivery status is recorded below.

## Delivery status — updated 28 November 2026

Owner reports **1.0.15 (30) is in production**. The release includes M05 fixes, M07 progress, M10 branding and the approved M11 content/audio. Validation: 151 Flutter tests passed. See [production confirmation](m11-production-release.md). M06 cloud recovery is still pending.

| Task | Current evidence and remaining work |
| --- | --- |
| M01 | GitHub #3 independently confirmed closed on 27 November (last updated 26 November). Earlier manual account-isolation/pagination/migration checks were deferred by the owner; closure does not itself verify them. |
| M02 | Completed; GitHub #4 closed 26 November. Phone accepted; user reports Play upload of 1.0.3+16. Google publication not independently verified. |
| M03 | Completed; GitHub #5 closed 26 November. All feature criteria/core phone acceptance passed; 63 tests passed, analysis clean. Signed 1.0.4+17 bundle and release notes verified and ready for owner production upload. |
| M04 | Feature complete and owner accepted. Checkpoint 5acf20b is included in pushed M05 commit 180d077. GitHub #6 independently confirmed still open on 27 November; administrative closure remains pending. See m04-completion-review.md. |
| M07 | Account-local daily goals, due/today counts, seven-day activity, distinct quiz/recall statistics and improved Learning Library implemented. 120 Flutter tests passed; 8-file analysis clean. Full isolated test app 1.0.9 (24) installed/opened wirelessly; owner acceptance pending. M06 cloud synchronization/two-device reconciliation remains a dependency; #9 and UI01 #16 stay open. See m07-progress.md. |
| M05 | GitHub #7 remains open. Hotfix 1.0.7 (22) signed bundle rebuilt and verified; owner accepted full test-app login, timer Start/Stop/Cancel and logout. 109 Flutter tests, 11 native checks and five optimized-release phone checks passed. Remaining reboot/timezone/permission/pending-alarm account-cancellation and tap checks remain unconfirmed. See m05-play-reminder-hotfix.md. |

Next implementation task: **M06 (#8), cloud session recovery and offline synchronization**. Owner requires completed and unfinished learning sessions, schedules, results, goals and progress to restore after reinstall/sign-in to the same account. M06 must migrate remaining local data, cloud-confirm checkpoints, retry safely, restore before uploading defaults and preserve account isolation without duplicate credit. M07 and M11 depend on this; current 1.0.15 (30) remains device-local. See [cloud recovery plan](m06-cloud-session-recovery-plan.md).

Details: [M03 completion review and progress visibility](m03-review-progress.md).
GitHub closure was independently re-read and confirmed; see `docs/m02-m03-issue-closure.json`.

Milestone: [German Reminder daily review foundation](https://github.com/ShriramSundaram/legendary-octo-flutter/milestone/1)

Reviewable plan and cost model: [Overview issue](https://github.com/ShriramSundaram/legendary-octo-flutter/issues/2). Local plan: `docs/german-reminder-next-milestone.md`.

| Planning ID | Priority | Issue | Scope |
| --- | --- | --- | --- |
| M01 | P0 | [#3 Learning data and access foundation](https://github.com/ShriramSundaram/legendary-octo-flutter/issues/3) | Required milestone |
| M02 | P0 | [#4 Reviewed German starter content](https://github.com/ShriramSundaram/legendary-octo-flutter/issues/4) | Required milestone |
| M03 | P1 | [#5 Spaced review scheduler and recall session](https://github.com/ShriramSundaram/legendary-octo-flutter/issues/5) | Required milestone |
| M04 | P1 | [#6 Short lessons and honest quiz feedback](https://github.com/ShriramSundaram/legendary-octo-flutter/issues/6) | Required milestone |
| M05 | P0 | [#7 Durable opt in reminders](https://github.com/ShriramSundaram/legendary-octo-flutter/issues/7) | Required milestone |
| M06 | P1 | [#8 Offline practice and bounded synchronization](https://github.com/ShriramSundaram/legendary-octo-flutter/issues/8) | Required milestone |
| M07 | P1 | [#9 Daily goal and useful progress](https://github.com/ShriramSundaram/legendary-octo-flutter/issues/9) | Required milestone |
| M08 | P0 | [#10 Privacy completion and operational measurement](https://github.com/ShriramSundaram/legendary-octo-flutter/issues/10) | Required milestone |
| M09 | P0 | [#11 Wireless phone beta and release evidence](https://github.com/ShriramSundaram/legendary-octo-flutter/issues/11) | Required milestone |
| M10 | P1 | [#18 German Reminder name and launcher icon](https://github.com/ShriramSundaram/legendary-octo-flutter/issues/18) | Owner requested branding update; approved light lavender GR/bell icon and spaced display name |
| M11 | P1 | [#19 Real-life German missions and streamlined learning navigation](https://github.com/ShriramSundaram/legendary-octo-flutter/issues/19) | Owner reports production 1.0.15 (30): 30 ten-exchange missions with three replies per step, 280 added offline vocabulary entries, follow-up review goals and audio. 151 tests passed. M06 cloud recovery remains pending; see docs/m11-production-release.md. |
| UI01 | P1 | [#16 App navigation and learning experience design](https://github.com/ShriramSundaram/legendary-octo-flutter/issues/16) | Parent UI task; shared design for M02/M03/M04/M07/M09 |
| L01 | P2 | [#12 Speaking practice experiment](https://github.com/ShriramSundaram/legendary-octo-flutter/issues/12) | Later backlog |
| L02 | P2 | [#13 Limited AI explanations and roleplay](https://github.com/ShriramSundaram/legendary-octo-flutter/issues/13) | Later backlog |
| L03 | P2 | [#14 More curriculum and contextual media](https://github.com/ShriramSundaram/legendary-octo-flutter/issues/14) | Later backlog |
| L04 | P3 | [#15 Paid plan feasibility](https://github.com/ShriramSundaram/legendary-octo-flutter/issues/15) | Later backlog |

Dependencies are linked in each issue body. M09 references the independently owned [GitHub Actions issue #1](https://github.com/ShriramSundaram/legendary-octo-flutter/issues/1); no duplicate CI issue was created.

Verification: milestone contains the overview and nine required feature issues. Four later feature issues have no milestone commitment. No due date was invented.
