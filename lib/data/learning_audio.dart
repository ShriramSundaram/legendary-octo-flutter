import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LearningCue {
  tap,
  testIntro,
  quickIntro,
  practiceIntro,
  resumeIntro,
  missionIntro,
  remembered,
  again,
  correct,
  wrong,
  complete
}

/// Optional feedback never blocks a learning action or changes saved scores.
class LearningAudio {
  static final instance = LearningAudio();
  static const channel = MethodChannel('german_reminder/learning_feedback');
  static const soundsKey = 'learningSoundsV1', voiceKey = 'learningVoiceCuesV1';
  bool sounds = true, spoken = true;
  Future<void>? _loaded;
  int _generation = 0;
  Future<void> load() => _loaded ??= _load();
  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      sounds = prefs.getBool(soundsKey) ?? true;
      spoken = prefs.getBool(voiceKey) ?? true;
    } catch (_) {/* Audio remains optional when settings are unavailable. */}
  }

  Future<void> configure({bool? soundEffects, bool? voiceCues}) async {
    await load();
    final prefs = await SharedPreferences.getInstance();
    if (soundEffects != null) {
      if (!await prefs.setBool(soundsKey, soundEffects))
        throw StateError('Could not save sound preference');
      sounds = soundEffects;
    }
    if (voiceCues != null) {
      if (!await prefs.setBool(voiceKey, voiceCues))
        throw StateError('Could not save voice preference');
      spoken = voiceCues;
    }
    await stop();
  }

  Future<void> play(LearningCue cue) async {
    final generation = ++_generation;
    try {
      await load();
      if (generation != _generation || (!sounds && !spoken)) return;
      await channel.invokeMethod<void>(
          'play', {'event': cue.name, 'sounds': sounds, 'spoken': spoken});
    } catch (_) {/* No audio device/plugin/voice must never fail a lesson. */}
  }

  Future<void> stop() async {
    _generation++;
    try {
      await channel.invokeMethod<void>('stop');
    } catch (_) {}
  }
}
