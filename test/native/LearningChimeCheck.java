import java.util.Arrays;
import com.sundaram.germanreminder.app.LearningChime;

public class LearningChimeCheck {
    public static void main(String[] args) {
        for (String cue : new String[]{"tap", "correct", "wrong", "remembered", "again", "complete", "testIntro"}) {
            short[] pcm = LearningChime.samples(cue);
            if (pcm.length < 500 || pcm.length > LearningChime.SAMPLE_RATE) throw new AssertionError("Unbounded duration: " + cue);
            int peak = 0;
            double energy = 0;
            for (short sample : pcm) {
                peak = Math.max(peak, Math.abs((int)sample));
                energy += (double)sample * sample;
            }
            if (peak < 8000 || peak > 24000) throw new AssertionError("Silent or clipped: " + cue);
            if (pcm[0] != 0 || pcm[pcm.length - 1] != 0) throw new AssertionError("Missing fade: " + cue);
            if ((cue.equals("correct") || cue.equals("wrong")) && Math.sqrt(energy / pcm.length) < 9000)
                throw new AssertionError("Outcome body is too quiet: " + cue);
            if (cue.equals("correct") || cue.equals("wrong"))
                System.out.printf("%s: peak %d, RMS %.0f%n", cue, peak, Math.sqrt(energy / pcm.length));
        }
        if (Arrays.equals(LearningChime.samples("correct"), LearningChime.samples("wrong"))) throw new AssertionError("Identical outcome sounds");
        if (LearningChime.samples("correct").length < LearningChime.SAMPLE_RATE * 0.7) throw new AssertionError("Applause is too short");
        if (LearningChime.samples("wrong").length > LearningChime.SAMPLE_RATE * 0.5) throw new AssertionError("Try-again sound is too long");
        if (Arrays.equals(LearningChime.samples("remembered"), LearningChime.samples("again"))) throw new AssertionError("Identical recall sounds");
        System.out.println("Chime checks passed: audible signal, distinct events, bounded duration and fades.");
    }
}
