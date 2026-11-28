import 'dart:async';
import 'package:flutter/material.dart';
import 'data/practice_speech.dart';

/// Playback stays on the visible recall card and never reveals its meaning.
class PronunciationButton extends StatefulWidget {
  const PronunciationButton({super.key, required this.text, this.speech});
  final String text;
  final PracticeSpeech? speech;
  @override
  State<PronunciationButton> createState() => _PronunciationButtonState();
}

class _PronunciationButtonState extends State<PronunciationButton>
    with WidgetsBindingObserver {
  PracticeSpeech? _speech;
  PracticeSpeech get speech =>
      _speech ??= widget.speech ?? GermanPracticeSpeech();
  bool playing = false, unavailable = false;
  int generation = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> play() async {
    final token = ++generation;
    setState(() {
      playing = true;
      unavailable = false;
    });
    final available = await speech.prepare();
    if (!mounted || generation != token) return;
    final ok = available && await speech.speak(widget.text);
    if (!mounted || generation != token) return;
    setState(() {
      playing = false;
      unavailable = !ok;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) return;
    generation++;
    unawaited(_speech?.stop());
    setState(() => playing = false);
  }

  @override
  void dispose() {
    generation++;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_speech?.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        OutlinedButton.icon(
            onPressed: playing ? null : play,
            icon: const Icon(Icons.volume_up),
            label: Text(playing ? 'Playing…' : 'Hear pronunciation')),
        if (unavailable)
          const Text(
              'German audio is unavailable. You can still practise using the word on the card.'),
      ]);
}
