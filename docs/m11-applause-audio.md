# M11 outcome sound polish — 27 November 2026

Candidate: German Reminder Test 1.0.14 (29).

- Correct submissions use a short original applause effect: layered, filtered hand-clap bursts with a brief room reflection and fade, about 0.92 seconds.
- Wrong submissions use a gentle two-part descending wah-wah, about 0.43 seconds.
- Non-tap effects use playback gain 0.95 instead of 0.75. The new outcomes are normalized below clipping. Neutral taps keep their earlier gain; phone/system volume is never changed.
- Existing Profile → Learning audio switches and correct/wrong previews remain in place. German speech, answer scoring, saved mission sessions and notification settings are unchanged.
- Effects are generated locally from original PCM synthesis, so no downloaded recordings, new permissions or dependencies are introduced.

Native checks passed for non-silent samples, distinct outcomes, peak bounds, fades and short durations. Android build/installation evidence is recorded with the candidate. No Dart learning-flow changes were made; the preceding 145-test regression baseline remains applicable. Audible preference acceptance remains for the owner.

Level verification: applause peak 22,500 / RMS 10,278; try-again peak 18,000 / RMS 9,983 (16-bit PCM, before playback gain). Smooth compression raises the applause body while retaining fades and headroom. The native check now also rejects outcome effects whose RMS falls below 9,000. Both effects use gain 0.95; taps remain at 0.75.
