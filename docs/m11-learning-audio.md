# M11 learning audio — 27 November 2026

Android test candidate: German Reminder Test 1.0.12 (27).

## Behaviour

| Learning action | Feedback |
| --- | --- |
| Open Start Test | “Let's start your vocabulary test.” and a brief start tone |
| Open Quick vocabulary check | “Let's try a quick vocabulary check.” |
| Open new recall practice | “Let's practise vocabulary. Reveal the meaning, then choose how it went.” |
| Open saved recall practice | “Let's continue your saved vocabulary practice.” |
| Begin/resume a mission | “Let's practise a real life conversation.” |
| Remembered / Again | Distinct short tones, preserving honest self-ratings |
| Submit mission/test answer | Different correct/wrong tones after submission; mission cues wait for a successful save |
| Select a reply, reveal meaning, continue, switch main tabs | Neutral short tap feedback |
| Complete mission/test | Completion tone |

Selecting a reply does not reveal correctness through sound. Retrying a mission reply keeps the original first-choice result. Audio failures never change saved learning data or block a lesson.

Profile → Learning audio expands to independent switches for button/answer sounds and spoken activity cues. Preferences persist on this device using SharedPreferences; they are not cloud-synced account progress. German pronunciation and reminder notifications retain their own controls.

The Android channel uses ToneGenerator on the media stream and a separate TextToSpeech instance for English introductions. It does not raise system volume. Spoken cues use an installed English voice without a network requirement; if unavailable, the learner can continue with on-screen context and tones. Neutral taps preserve a spoken introduction; listening/pronunciation stops it, and backgrounding or leaving the activity stops cues. Native resources are released when the Activity is destroyed. No audio recordings, permissions or new dependencies were added.

Implementation reference: https://developer.android.com/reference/android/media/ToneGenerator

## Verification

143 Flutter tests passed after fixing the Profile layout regression. Nine affected Dart source/test files passed analysis. Android debug compilation passed. Tests cover persisted independent mute controls, missing audio platform, cancellation of pending introductions, and mission outcome cues occurring only after saved submissions while retaining first-answer scoring. Profile actions remain accessible at narrow widths and large text.

Physical listening acceptance remains for the owner. Check Start Test, Continue saved session, Remembered/Again, a wrong mission submission followed by a correct retry, German listening priority, both audio switches and background/back behaviour. These changes do not close M06 cloud recovery or the content/UI release gates. No production rollout, commit or push is claimed.

## Subsequent correction
The ToneGenerator implementation above describes candidate 27. Candidate 28 replaces it with generated media chimes, adds outcome preview controls and restores three mission replies. See [current correction](m11-mission-choice-audio-fix.md).
