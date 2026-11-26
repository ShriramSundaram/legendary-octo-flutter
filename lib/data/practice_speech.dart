import 'package:flutter_tts/flutter_tts.dart';

abstract class PracticeSpeech {
  Future<bool> prepare();
  Future<bool> speak(String text);
  Future<void> stop();
}

class GermanPracticeSpeech implements PracticeSpeech {
  final FlutterTts _tts = FlutterTts();
  @override
  Future<bool> prepare() async {
    try {
      if (await _tts.isLanguageAvailable('de-DE') != true) return false;
      final voices = await _tts.getVoices;
      if (voices is! List) return false;
      final german = voices
          .whereType<Map>()
          .where((v) => '${v['locale']}'
              .toLowerCase()
              .replaceAll('_', '-')
              .startsWith('de-'))
          .toList();
      if (german.isEmpty) return false;
      german.sort((a, b) => ('${a['network_required']}' == 'true' ? 1 : 0)
          .compareTo('${b['network_required']}' == 'true' ? 1 : 0));
      final voice = german.first;
      await _tts.setLanguage('${voice['locale']}');
      await _tts.setVoice(
          {'name': '${voice['name']}', 'locale': '${voice['locale']}'});
      await _tts.setSpeechRate(0.45);
      await _tts.awaitSpeakCompletion(true);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> speak(String text) async {
    try {
      return await _tts.speak(text) == 1;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {/* Playback is optional. */}
  }
}
