import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'data/offline_vocabulary.dart';
import 'data/offline_vocabulary_loader.dart';
import 'data/practice_speech.dart';
import 'vocabulary_browser_widgets.dart';

class ViewGenericDatabase extends StatefulWidget {
  final String GermanLevel;
  final Future<OfflineVocabulary> Function()? load;
  final PracticeSpeech? speech;
  const ViewGenericDatabase(
      {super.key, required this.GermanLevel, this.load, this.speech});
  @override
  State<ViewGenericDatabase> createState() => _ViewGenericDatabaseState();
}

class _ViewGenericDatabaseState extends State<ViewGenericDatabase> {
  List<VocabularyEntry>? words;
  String query = '';
  String? selected, error;
  PracticeSpeech? speaker;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      error = null;
      words = null;
    });
    try {
      final vocabulary = await (widget.load?.call() ??
          loadOfflineVocabulary(includeDrafts: kDebugMode));
      final entries = vocabulary
          .atLevel(OfflineVocabulary.levelForCollection(widget.GermanLevel))
          .map((w) => VocabularyEntry(w.id, w.display, preview: w.preview))
          .toList();
      if (mounted) setState(() => words = entries);
    } catch (_) {
      if (mounted) setState(() => error = 'Could not load offline vocabulary.');
    }
  }

  Future<void> _speak(String text) async {
    final voice = speaker ??= widget.speech ?? GermanPracticeSpeech();
    final ok = await voice.prepare() && await voice.speak(text);
    if (!ok && mounted)
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('German speech is unavailable.')));
  }

  @override
  void dispose() {
    unawaited(speaker?.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: Text(
              'Offline vocabulary ' +
                  OfflineVocabulary.levelForCollection(widget.GermanLevel),
              style: const TextStyle(fontSize: 18)),
          centerTitle: true,
          actions: [
            IconButton(
                tooltip: 'Reload offline vocabulary',
                icon: const Icon(Icons.refresh),
                onPressed: _load)
          ]),
      body: Column(children: [
        VocabularySearchField(
            onChanged: (value) =>
                setState(() => query = value.trim().toLowerCase())),
        if (error != null)
          Expanded(
              child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(error!),
            TextButton(onPressed: _load, child: const Text('Try Again'))
          ])))
        else if (words == null)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
              child: VocabularyCards(
                  entries: words!
                      .where((e) => e.text.toLowerCase().contains(query))
                      .toList(),
                  selectedId: selected,
                  onSelect: (id) => setState(() => selected = id),
                  onSpeak: _speak,
                  emptyMessage: 'No words found for this level.')),
      ]));
}
