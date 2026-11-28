# M11 mission choice and outcome-audio correction

Candidate: German Reminder Test 1.0.13 (28), Android, 27 November 2026.

The expanded pack mistakenly supplied only two replies per step. All 30 missions now have three distinct replies at every one of their 300 steps, with the correct position distributed across all three positions. The third responses are editable original draft content in tools/content/m11-third-replies.txt. Existing vocabulary entries and their IDs are unchanged.

Previous definitions are archived. An unfinished ten-exchange session can upgrade when only reply choices changed: the controller maps first/submitted answers by their exact text, preserving the stable attempt ID, cursor, feedback, text alternative and first-choice score. The upgrade is checkpointed before resuming. Failed or stale writes preserve the original stored version. The older five-step café continues against its own archived definition because its conversation structure differs.

System ToneGenerator feedback has been replaced by original, faded PCM chimes using AudioTrack with explicit media usage. Correct answers use rising notes; wrong answers use a gentler descending pair. Remembered/Again and completion retain distinct melodies. No system volume or silent-mode settings are changed. No sound files or dependencies are downloaded. Foreground cancellation and preference switches remain in place, and native playback resources are released after each short cue.

Profile → Learning audio now includes Preview correct sound and Preview wrong sound. These use the same outcome events as submitted mission answers and respect the sound-effects switch. They let the owner verify speaker output directly without completing a mission. Debug logs include only the cue name and playback state; no answer text or personal data is logged.

Validation includes three-choice coverage/position checks, saved two-choice answer migration with failed-write retry, first-choice score preservation, native PCM signal/duration/fade checks, missing audio handling and Profile preview/mute behaviour. The final audio suite has seven passing tests; affected Dart analysis is clean. Android build and wireless installation evidence are recorded with the candidate. Audible phone acceptance remains pending the owner until reported.

M06 cloud recovery and new content/editorial release gates remain open. No production rollout, commit or push is part of this correction.

Final verification: all 145 Flutter tests passed; analysis of six affected files is clean; native chime checks and Android compilation passed. Candidate 1.0.13 (28) was installed and opened wirelessly without uninstalling or clearing data. Play app version stayed unchanged. The packaged APK was independently checked for 30 missions / 300 steps / three choices each. Its mission-related text assets, including compatibility archives and vocabulary, occupy 135,552 compressed bytes. Audible acceptance is still awaiting the owner response.
