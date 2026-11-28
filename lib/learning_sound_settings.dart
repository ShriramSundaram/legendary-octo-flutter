import 'package:flutter/material.dart';
import 'dart:async';
import 'data/learning_audio.dart';

class LearningSoundSettings extends StatefulWidget {
  const LearningSoundSettings({super.key, this.audio});
  final LearningAudio? audio;
  @override
  State<LearningSoundSettings> createState() => _LearningSoundSettingsState();
}

class _LearningSoundSettingsState extends State<LearningSoundSettings> {
  late final LearningAudio audio = widget.audio ?? LearningAudio.instance;
  bool loading = true, saving = false;
  String? error;
  @override
  void initState() {
    super.initState();
    audio.load().then((_) {
      if (mounted) setState(() => loading = false);
    });
  }

  Future<void> change({bool? sounds, bool? spoken}) async {
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await audio.configure(soundEffects: sounds, voiceCues: spoken);
    } catch (_) {
      error = 'Could not save audio settings. Please retry.';
    }
    if (mounted) setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) => Card(
      color: const Color(0xfff1e9fc),
      elevation: 0,
      child: ExpansionTile(
          leading: const Icon(Icons.volume_up_outlined),
          title: const Text('Learning audio'),
          subtitle: const Text('Sounds and spoken cues'),
          children: [
            Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('On this device · Uses media volume'),
                      SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Button and answer sounds'),
                          value: audio.sounds,
                          onChanged: loading || saving
                              ? null
                              : (v) => change(sounds: v)),
                      SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Spoken activity cues'),
                          subtitle: const Text(
                              'Short English introductions. Needs an installed English voice.'),
                          value: audio.spoken,
                          onChanged: loading || saving
                              ? null
                              : (v) => change(spoken: v)),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        OutlinedButton.icon(
                            onPressed: loading || saving || !audio.sounds
                                ? null
                                : () =>
                                    unawaited(audio.play(LearningCue.correct)),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Preview correct sound')),
                        OutlinedButton.icon(
                            onPressed: loading || saving || !audio.sounds
                                ? null
                                : () =>
                                    unawaited(audio.play(LearningCue.wrong)),
                            icon: const Icon(Icons.replay),
                            label: const Text('Preview wrong sound')),
                      ]),
                      const Text(
                          'German pronunciation and reminder notifications keep their own controls.',
                          style: TextStyle(fontSize: 12)),
                      if (error != null) Text(error!),
                    ]))
          ]));
}
