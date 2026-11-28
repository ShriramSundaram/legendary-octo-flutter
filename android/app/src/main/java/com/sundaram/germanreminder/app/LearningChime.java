package com.sundaram.germanreminder.app;
import java.util.Random;

/** Original short PCM chimes. Pure Java so envelopes and event distinctions are testable. */
public final class LearningChime {
    public static final int SAMPLE_RATE = 22050;
    private LearningChime() {}
    public static short[] samples(String event) {
        if (event.equals("correct")) return applause();
        if (event.equals("wrong")) return tryAgain();
        final double[] notes;
        switch (event) {
            case "remembered": notes = new double[]{783.99, 1046.50}; break;
            case "again": notes = new double[]{523.25, 440}; break;
            case "complete": notes = new double[]{523.25, 659.25, 783.99, 1046.50}; break;
            case "tap": notes = new double[]{880}; break;
            default: notes = new double[]{659.25, 783.99}; break;
        }
        int noteSamples = (int)(SAMPLE_RATE * (event.equals("tap") ? 0.045 : 0.13));
        int gap = (int)(SAMPLE_RATE * 0.015);
        short[] pcm = new short[(noteSamples + gap) * notes.length];
        for (int n = 0; n < notes.length; n++) {
            for (int i = 0; i < noteSamples; i++) {
                double attack = Math.min(1, i / (SAMPLE_RATE * 0.008));
                double release = Math.min(1, (noteSamples - 1 - i) / (SAMPLE_RATE * 0.045));
                double phase = 2 * Math.PI * notes[n] * i / SAMPLE_RATE;
                pcm[n * (noteSamples + gap) + i] = (short)(18000 * attack * release *
                    (Math.sin(phase) + 0.12 * Math.sin(2 * phase)) / 1.12);
            }
        }
        return pcm;
    }

    /** A short crowd clap: overlapping, independently filtered hand-clap bursts. */
    private static short[] applause() {
        double[] mix = new double[(int)(SAMPLE_RATE * 0.92)];
        Random random = new Random(72419);
        for (int group = 0; group < 10; group++) {
            for (int hand = 0; hand < 3; hand++) {
                int start = (int)(SAMPLE_RATE * (0.025 + group * 0.071 + random.nextDouble() * 0.026));
                double low = 0;
                double gain = 0.55 + random.nextDouble() * 0.45;
                for (int i = 0; i < SAMPLE_RATE * 0.085; i++) {
                    double seconds = (double)i / SAMPLE_RATE;
                    double noise = random.nextDouble() * 2 - 1;
                    low += 0.42 * (noise - low);
                    double attack = Math.min(1, seconds / 0.0015);
                    double envelope = attack * Math.exp(-seconds / 0.016);
                    double clap = gain * envelope * (0.82 * (noise - 0.6 * low)
                        + 0.18 * Math.sin(2 * Math.PI * 1250 * seconds));
                    add(mix, start + i, clap);
                    add(mix, start + i + (int)(SAMPLE_RATE * 0.039), clap * 0.16);
                    add(mix, start + i + (int)(SAMPLE_RATE * 0.082), clap * 0.07);
                }
            }
        }
        return normalize(mix, 22500, true);
    }

    /** A warm, descending wah-wah rather than a harsh error alarm. */
    private static short[] tryAgain() {
        double[] mix = new double[(int)(SAMPLE_RATE * 0.43)];
        for (int note = 0; note < 2; note++) {
            int start = (int)(SAMPLE_RATE * (0.015 + note * 0.20));
            double phase = 0;
            for (int i = 0; i < SAMPLE_RATE * 0.18; i++) {
                double t = i / (SAMPLE_RATE * 0.18);
                double frequency = (note == 0 ? 280 : 210) - 65 * t;
                phase += 2 * Math.PI * frequency / SAMPLE_RATE;
                double envelope = Math.pow(Math.sin(Math.PI * t), 0.8);
                double wah = (Math.sin(phase) + 0.20 * Math.sin(3 * phase)
                    + 0.08 * Math.sin(5 * phase)) / 1.28;
                add(mix, start + i, wah * envelope);
            }
        }
        return normalize(mix, 18000, false);
    }

    private static void add(double[] mix, int position, double value) {
        if (position >= 0 && position < mix.length) mix[position] += value;
    }
    private static short[] normalize(double[] mix, int targetPeak, boolean crowdCompression) {
        double peak = 0;
        // Explicit fades also protect against clicks at buffer boundaries.
        for (int i = 0; i < mix.length; i++) {
            mix[i] *= Math.min(1, i / (SAMPLE_RATE * 0.008))
                * Math.min(1, (mix.length - 1 - i) / (SAMPLE_RATE * 0.035));
            peak = Math.max(peak, Math.abs(mix[i]));
        }
        short[] pcm = new short[mix.length];
        if (peak == 0) return pcm;
        // A crowd's rare clap transients must not make the rest of its applause
        // too quiet. Smooth compression raises the body without hard clipping.
        if (crowdCompression) {
            double inputPeak = peak;
            peak = 0;
            for (int i = 0; i < mix.length; i++) {
                mix[i] = Math.tanh(6 * mix[i] / inputPeak);
                peak = Math.max(peak, Math.abs(mix[i]));
            }
        }
        for (int i = 0; i < mix.length; i++) pcm[i] = (short)(mix[i] * targetPeak / peak);
        return pcm;
    }
}
