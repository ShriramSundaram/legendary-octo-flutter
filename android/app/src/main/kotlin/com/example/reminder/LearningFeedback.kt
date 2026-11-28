package com.sundaram.germanreminder.app

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.util.Log
import android.speech.tts.TextToSpeech
import android.os.Handler
import android.os.Looper
import java.util.Locale

/** Optional foreground UI feedback. Never changes system volume or reminder alarms. */
class LearningFeedback(private val context: Context) {
    private var tone: AudioTrack? = null
    private val handler = Handler(Looper.getMainLooper())
    private var toneGeneration = 0L
    private val chimes = mutableMapOf<String, ShortArray>()
    private var voice: TextToSpeech? = null
    private var ready = false
    private var initializing = false
    private var pending: Pair<Long, String>? = null
    private var generation = 0L
    private var active = true
    private var destroyed = false

    fun resume() { active = true }
    fun stop() {
        generation++
        pending = null
        stopTone()
        try { voice?.stop() } catch (_: Exception) { }
    }
    fun pause() { active = false; stop() }
    fun close() {
        destroyed = true
        pause()
        try { voice?.shutdown() } catch (_: Exception) { }
        voice = null
    }
    fun play(event: String, sounds: Boolean, spoken: Boolean) {
        if (!active || destroyed) return
        // A neutral tap must not cut an activity introduction mid-sentence.
        if (event == "tap") {
            stopTone()
        } else stop()
        if (sounds) playChime(event)
        val text = when (event) {
            "testIntro" -> "Let's start your vocabulary test."
            "quickIntro" -> "Let's try a quick vocabulary check."
            "practiceIntro" -> "Let's practise vocabulary. Reveal the meaning, then choose how it went."
            "resumeIntro" -> "Let's continue your saved vocabulary practice."
            "missionIntro" -> "Let's practise a real life conversation."
            else -> null
        }
        if (!spoken || text == null) return
        pending = Pair(generation, text)
        if (ready) speakPending()
        else if (!initializing) {
            initializing = true
            voice = TextToSpeech(context.applicationContext) { status ->
              Handler(Looper.getMainLooper()).post {
                initializing = false
                if (destroyed) { voice?.shutdown(); return@post }
                if (status == TextToSpeech.SUCCESS) try {
                    val localEnglish = voice?.voices?.filter {
                        it.locale.language == Locale.ENGLISH.language && !it.isNetworkConnectionRequired
                    }?.sortedBy { if (it.locale.country == "GB") 0 else 1 }?.firstOrNull()
                    if (localEnglish != null) {
                        voice?.voice = localEnglish
                        voice?.setSpeechRate(0.95f)
                        voice?.setAudioAttributes(AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_MEDIA)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build())
                        ready = true
                        speakPending()
                    } else {
                        voice?.shutdown()
                        voice = null
                        pending = null
                    }
                } catch (_: Exception) {
                    voice?.shutdown()
                    voice = null
                    pending = null
                } else {
                    voice?.shutdown()
                    voice = null
                    pending = null
                }
              }
            }
        }
    }
    private fun stopTone() {
        toneGeneration++
        try { tone?.stop() } catch (_: Exception) { }
        try { tone?.release() } catch (_: Exception) { }
        tone = null
    }
    private fun playChime(event: String) {
        try {
            val pcm = chimes.getOrPut(event) { LearningChime.samples(event) }
            val track = AudioTrack.Builder()
                .setAudioAttributes(AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build())
                .setAudioFormat(AudioFormat.Builder().setSampleRate(LearningChime.SAMPLE_RATE)
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT).setChannelMask(AudioFormat.CHANNEL_OUT_MONO).build())
                .setTransferMode(AudioTrack.MODE_STATIC).setBufferSizeInBytes(pcm.size * 2).build()
            tone = track
            if (track.write(pcm, 0, pcm.size) != pcm.size) throw IllegalStateException("Incomplete chime buffer")
            track.setVolume(if (event == "tap") 0.75f else 0.95f)
            track.play()
            if ((context.applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0)
                Log.d("LearningFeedback", "chime=$event state=${track.playState}")
            val token = toneGeneration
            handler.postDelayed({ if (token == toneGeneration) stopTone() },
                pcm.size.toLong() * 1000 / LearningChime.SAMPLE_RATE + 80)
        } catch (error: Exception) {
            Log.w("LearningFeedback", "Chime unavailable", error)
            stopTone()
        }
    }
    private fun speakPending() {
        val request = pending ?: return
        pending = null
        if (!active || destroyed || request.first != generation) return
        try { voice?.speak(request.second, TextToSpeech.QUEUE_FLUSH, null, "learning-" + generation) }
        catch (_: Exception) { }
    }
}
