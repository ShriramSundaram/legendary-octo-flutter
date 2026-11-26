import 'dart:async';
import 'package:flutter/material.dart';
import 'data/account_store.dart';
import 'data/practice_session.dart';
import 'data/practice_speech.dart';
import 'data/practice_history.dart';
import 'data/test_report.dart';
import 'review_session_page.dart';
import 'practice_results.dart';

class PracticePage extends StatefulWidget {
  const PracticePage(
      {super.key,
      required this.cards,
      required this.level,
      this.topic,
      this.limit,
      this.speech,
      this.quickCheck = false,
      this.saveResult});
  final List<PracticeCard> cards;
  final String level;
  final String? topic;
  final Duration? limit;
  final PracticeSpeech? speech;
  final bool quickCheck;
  final Future<void> Function(Map<String, dynamic>)? saveResult;
  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage>
    with WidgetsBindingObserver {
  late PracticeSession session;
  late PracticeSpeech speech;
  Timer? ticker;
  AccountStore? account;
  bool fallback = false, playing = false, saving = false, saved = false;
  String? saveError;
  int generation = 0;
  late String sessionId;
  late DateTime startedAt;
  Map<String, dynamic>? summary;
  final Set<String> textAlternatives = {};
  final Set<String> heard = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    speech = widget.speech ?? GermanPracticeSpeech();
    try {
      account = AccountStore.current();
    } catch (_) {/* No signed-in storage. */}
    _reset();
    ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (widget.limit == null ||
          !session.started ||
          session.complete ||
          session.feedback) return;
      setState(session.checkTime);
      _finish();
    });
  }

  void _reset() {
    generation++;
    session = PracticeSession(widget.cards, limit: widget.limit);
    startedAt = DateTime.now().toUtc();
    sessionId = '${startedAt.microsecondsSinceEpoch}';
    summary = null;
    textAlternatives.clear();
    heard.clear();
    fallback = playing = saving = saved = false;
    saveError = null;
  }

  void _change(VoidCallback action) {
    setState(action);
    _finish();
  }

  void _finish() {
    if (!session.complete || summary != null) return;
    generation++;
    unawaited(speech.stop());
    summary = {
      'schemaVersion': 1,
      'kind': widget.quickCheck ? 'quickVocabularyCheck' : 'topicTest',
      'id': sessionId,
      'level': widget.level,
      'testedLevels': session.cards
          .map((c) => c.level)
          .where((l) => l.isNotEmpty)
          .toSet()
          .toList(),
      'topic': widget.topic,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': DateTime.now().toUtc().toIso8601String(),
      'correct': session.correct,
      'wrong': session.wrong,
      'unanswered': session.unanswered,
      'remembered': session.remembered,
      'again': session.again,
      'unrated': session.unrated,
      'timedOut': session.timedOut,
      'activeMilliseconds': session.clock.elapsedMilliseconds,
      'outcomes': session.outcomes,
      'textAlternativeActivities': textAlternatives.toList(),
    };
    unawaited(_save());
  }

  Future<void> _save() async {
    if (saving || saved || summary == null) return;
    setState(() {
      saving = true;
      saveError = null;
    });
    try {
      if (widget.saveResult != null) {
        await widget.saveResult!(Map.of(summary!));
      } else {
        final store = account;
        if (store == null) throw StateError('No account');
        await PracticeHistory(store).save(summary!);
      }
      if (mounted) setState(() => saved = true);
    } catch (_) {
      if (mounted)
        setState(
            () => saveError = 'Result could not be saved on this account.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _play() async {
    if (playing) return;
    final token = generation;
    final cardId = session.card.id;
    final answer = session.card.answer;
    setState(() => playing = true);
    final available = await speech.prepare();
    if (!mounted ||
        token != generation ||
        session.complete ||
        session.card.id != cardId) return;
    final ok = available && await speech.speak(answer);
    if (!mounted ||
        token != generation ||
        session.complete ||
        session.card.id != cardId) return;
    setState(() {
      playing = false;
      if (!ok) {
        fallback = true;
        textAlternatives.add(cardId);
      } else {
        heard.add(cardId);
      }
    });
  }

  void _advance(VoidCallback action) {
    generation++;
    unawaited(speech.stop());
    _change(() {
      fallback = playing = false;
      action();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      generation++;
      playing = false;
      unawaited(speech.stop());
    } else {
      _change(session.checkTime);
    }
  }

  @override
  void dispose() {
    generation++;
    ticker?.cancel();
    session.dispose();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(speech.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final children = <Widget>[];
    if (session.complete) {
      children.add(PracticeResults(
        key: ValueKey(sessionId),
        session: session,
        level: widget.level,
        topic: widget.topic,
        quickCheck: widget.quickCheck,
        textAlternatives: textAlternatives,
        saving: saving,
        saved: saved,
        saveError: saveError,
        onRetrySave: () => unawaited(_save()),
        onRetake: () => setState(_reset),
        onDone: () => Navigator.pop(context),
        onPractice: () {
          final suggestedLevel = widget.quickCheck
              ? TestReport(session).suggestedLevel ?? 'B2'
              : widget.level;
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ReviewSessionPage(
                      level: suggestedLevel,
                      topic: widget.quickCheck ? null : widget.topic)));
        },
      ));
    } else if (!session.started) {
      final modes = widget.cards.map((c) => c.mode).toSet();
      children.addAll([
        Text(
            widget.quickCheck
                ? 'Quick vocabulary check'
                : widget.topic ?? 'Topic test',
            style: theme.textTheme.headlineMedium),
        Text(widget.quickCheck
            ? '3 sampled questions per level • A1–B2'
            : 'Selected level: ${widget.level}'),
        Text('${widget.cards.length} activities'),
        Text(modes
            .map((m) => m == PracticeMode.recognition
                ? 'Meaning recognition'
                : m == PracticeMode.listening
                    ? 'Listening'
                    : 'Recall')
            .join(' • ')),
        const Text(
            'Check what you know. Read the answer explanation before continuing. Use Start practice to learn and recall words.'),
        if (widget.limit != null)
          const Text('The timer pauses while you read feedback.'),
        FilledButton(
            onPressed: widget.cards.isEmpty
                ? null
                : () => _change(() {
                      startedAt = DateTime.now().toUtc();
                      session.start();
                    }),
            child: const Text('Start')),
      ]);
    } else {
      final card = session.card;
      final listening = card.mode == PracticeMode.listening;
      final recall = card.mode == PracticeMode.recall;
      final remaining = session.remaining;
      children.addAll([
        Text(
            'Question ${session.index + 1} of ${session.cards.length} • ${card.level.isEmpty ? widget.level : card.level} • ${listening ? 'Listening' : 'Meaning recognition'}'),
        LinearProgressIndicator(value: session.index / session.cards.length),
        if (remaining != null)
          Text(
              'Time: ${remaining.inSeconds ~/ 60}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}${session.feedback ? ' (paused)' : ''}'),
        if (listening && !session.feedback) ...[
          const Text('Listen, then select the German word.'),
          OutlinedButton.icon(
              onPressed: playing ? null : _play,
              icon: const Icon(Icons.volume_up),
              label: Text(playing ? 'Playing…' : 'Play / replay German')),
          TextButton(
              onPressed: () {
                unawaited(speech.stop());
                generation++;
                setState(() {
                  fallback = true;
                  textAlternatives.add(card.id);
                  playing = false;
                });
              },
              child: const Text('Use text question')),
          if (fallback)
            const Text(
                'Text alternative • Audio may be unavailable. Answer the meaning question below.'),
        ],
        if (!listening || fallback || session.feedback)
          Text(card.prompt, style: theme.textTheme.headlineSmall),
        if (!recall)
          ...card.options.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: OutlinedButton(
                    onPressed: session.feedback
                        ? null
                        : () => _change(() => session.select(entry.key)),
                    style: OutlinedButton.styleFrom(
                        backgroundColor: session.selection == entry.key
                            ? theme.colorScheme.secondaryContainer
                            : null),
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(entry.value))),
              )),
        if (!session.feedback)
          FilledButton(
              onPressed: recall
                  ? () => _change(session.reveal)
                  : session.selection == null ||
                          (listening && !fallback && !heard.contains(card.id))
                      ? null
                      : () {
                          unawaited(speech.stop());
                          generation++;
                          _change(session.submit);
                        },
              child: Text(recall ? 'Reveal meaning' : 'Check answer')),
        if (session.feedback) ...[
          if (!recall)
            Text(
                session.selection == card.correctOption
                    ? 'Correct'
                    : 'Keep practising',
                style: theme.textTheme.titleLarge),
          Text('Correct response: ${card.answer}',
              style: theme.textTheme.titleLarge),
          Text(card.explanation),
          if (recall)
            Wrap(spacing: 12, children: [
              OutlinedButton(
                  onPressed: () => _advance(() => session.rate(false)),
                  child: const Text('Again')),
              FilledButton(
                  onPressed: () => _advance(() => session.rate(true)),
                  child: const Text('Remembered')),
            ])
          else
            FilledButton(
                onPressed: () => _advance(session.next),
                child: Text(session.index == session.cards.length - 1
                    ? 'Finish'
                    : 'Continue')),
        ],
      ]);
    }
    return Scaffold(
        backgroundColor: session.complete
            ? Color.alphaBlend(theme.colorScheme.primary.withAlpha(8),
                theme.colorScheme.surface)
            : null,
        appBar: AppBar(
            title: Text(
                widget.quickCheck ? 'Quick vocabulary check' : 'Topic test')),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: children
                            .expand((w) => [w, const SizedBox(height: 16)])
                            .toList())))));
  }
}
