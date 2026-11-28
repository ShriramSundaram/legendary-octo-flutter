import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'data/learning_repository.dart';
import 'data/learning_models.dart';
import 'vocabulary_browser_widgets.dart';

class UserCollectionDatabase extends StatefulWidget {
  const UserCollectionDatabase({super.key, this.embedded = false});
  final bool embedded;
  @override
  State<UserCollectionDatabase> createState() => _UserCollectionDatabaseState();
}

class _UserCollectionDatabaseState extends State<UserCollectionDatabase> {
  final _tts = FlutterTts(),
      _newWord = TextEditingController(),
      _search = TextEditingController();
  LearningRepository? _repository;
  final _words = <PersonalWord>[];
  WordPage? _page;
  bool _loading = false, _migrated = false, _saving = false;
  String query = '';
  String? _error, _warning, selected;
  StreamSubscription<User?>? _auth;
  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (_repository != null && user?.uid != _repository!.uid && mounted)
        setState(() {
          _words.clear();
          _search.clear();
          _newWord.clear();
          query = '';
          selected = null;
          _warning = null;
          _error = 'Your account changed. Reopen My words after signing in.';
        });
    });
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repository = _repository ??= LearningRepository.current();
      if (!_migrated) {
        final report = await repository.migrate();
        _warning = report.invalidEntries == 0
            ? null
            : report.invalidEntries.toString() +
                ' older entries need repair; originals are preserved.';
        _migrated = true;
      }
      final page = await repository.page(after: _page?.cursor);
      if (!mounted) return;
      setState(() {
        final ids = _words.map((w) => w.id).toSet();
        _words.addAll(page.words.where((w) => ids.add(w.id)));
        _page = page;
      });
    } catch (_) {
      if (mounted)
        setState(() => _error =
            'Could not load your words. Check your connection and sign-in, then retry.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    if (_loading || _saving) return;
    setState(() {
      _words.clear();
      _page = null;
      selected = null;
    });
    await _load();
  }

  Future<void> _speak(String word) async {
    try {
      await _tts.setLanguage('de-DE');
      await _tts.speak(word);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Speech is unavailable.')));
    }
  }

  Future<void> _addDialog() async {
    final add = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Add a personal word'),
                content: TextField(
                    controller: _newWord,
                    autofocus: true,
                    decoration: const InputDecoration(
                        labelText: 'German word or phrase'),
                    onSubmitted: (_) => Navigator.pop(context, true)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Save word'))
                ]));
    if (add == true)
      await _add();
    else
      _newWord.clear();
  }

  Future<void> _add() async {
    final text = _newWord.text.trim();
    if (_saving || text.isEmpty) return;
    setState(() => _saving = true);
    try {
      final word = PersonalWord.fromText(text);
      await (_repository ??= LearningRepository.current()).ensureWord(word);
      if (!mounted) return;
      _newWord.clear();
      _search.clear();
      setState(() {
        query = '';
        _error = null;
        _words.removeWhere((w) => w.id == word.id);
        _words.insert(0, word);
        selected = word.id;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Word saved.')));
      if (_page == null) await _load();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not save your word. Please retry.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _auth?.cancel();
    unawaited(_tts.stop());
    _newWord.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: const Text('My words'),
          centerTitle: true,
          automaticallyImplyLeading: !widget.embedded,
          actions: [
            IconButton(
                tooltip: 'Reload my words',
                icon: const Icon(Icons.refresh),
                onPressed: _loading ? null : _refresh)
          ]),
      floatingActionButton: FloatingActionButton(
          tooltip: 'Add a personal word',
          onPressed: _saving ? null : _addDialog,
          child: const Icon(Icons.add)),
      body: Column(children: [
        VocabularySearchField(
            controller: _search,
            onChanged: (s) => setState(() => query = s.trim().toLowerCase())),
        if (_saving || _loading) const LinearProgressIndicator(),
        if (_warning != null)
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_warning!)),
        if (_error != null)
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!)),
        Expanded(
            child: VocabularyCards(
                entries: _words
                    .where((w) => w.lemma.toLowerCase().contains(query))
                    .map((w) => VocabularyEntry(w.id, w.lemma))
                    .toList(),
                selectedId: selected,
                onSelect: (id) => setState(() => selected = id),
                onSpeak: _speak,
                emptyMessage: _loading
                    ? 'Loading words…'
                    : query.isEmpty
                        ? 'You have no saved words yet. Tap + to add one.'
                        : 'No matching saved words.')),
        if (_page?.hasMore == true)
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                  'Search covers loaded words. Load more to include the rest.',
                  style: TextStyle(fontSize: 12))),
        if (!_loading && (_error != null || (_page?.hasMore ?? false)))
          TextButton(
              onPressed: _load,
              child: Text(_error == null ? 'Load more' : 'Try again')),
        const SizedBox(height: 12),
      ]));
}
