import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'data/learning_repository.dart';
import 'data/learning_models.dart';

class UserCollectionDatabase extends StatefulWidget {
  const UserCollectionDatabase({Key? key}) : super(key: key);
  @override
  State<UserCollectionDatabase> createState() => _UserCollectionDatabaseState();
}

class _UserCollectionDatabaseState extends State<UserCollectionDatabase> {
  final _tts = FlutterTts();
  LearningRepository? _repository;
  final _words = <PersonalWord>[];
  WordPage? _page;
  bool _loading = false;
  bool _migrated = false;
  String? _error;
  String? _warning;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (_repository != null && user?.uid != _repository!.uid && mounted) {
        setState(() {
          _words.clear();
          _warning = null;
          _error =
              'Your account changed. Close this screen and reopen your words.';
        });
      }
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
            : '${report.invalidEntries} legacy entries need repair. Originals have been preserved.';
        _migrated = true;
      }
      final page = await repository.page(after: _page?.cursor);
      if (!mounted) return;
      setState(() {
        _words.addAll(page.words);
        _page = page;
      });
    } catch (_) {
      if (mounted)
        setState(() {
          _error =
              'Could not load your words. Check your connection and sign-in, then try again.';
        });
    } finally {
      if (mounted)
        setState(() {
          _loading = false;
        });
    }
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

  @override
  void dispose() {
    _authSubscription?.cancel();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Your words')),
        body: Column(children: [
          if (_warning != null)
            Padding(padding: const EdgeInsets.all(16), child: Text(_warning!)),
          if (_error != null)
            Padding(padding: const EdgeInsets.all(16), child: Text(_error!)),
          if (!_loading && _error == null && _words.isEmpty)
            const Padding(
                padding: EdgeInsets.all(16),
                child: Text('You have no saved words yet.')),
          Expanded(
              child: ListView.builder(
                  itemCount: _words.length,
                  itemBuilder: (context, index) => ListTile(
                      title: Text(_words[index].lemma),
                      trailing: IconButton(
                          tooltip: 'Speak',
                          icon: const Icon(Icons.volume_up),
                          onPressed: () => _speak(_words[index].lemma))))),
          if (_loading)
            const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator()),
          if (!_loading && (_error != null || (_page?.hasMore ?? false)))
            TextButton(
                onPressed: _load,
                child: Text(_error == null ? 'Load more' : 'Try again')),
        ]),
      );
}
