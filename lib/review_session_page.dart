import 'package:flutter/material.dart';
import 'dart:async';
import 'data/learning_audio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'data/learning_catalog_loader.dart';
import 'data/content_catalog.dart';
import 'data/review_controller.dart';
import 'data/review_scheduler.dart';
import 'data/review_store.dart';
import 'data/practice_speech.dart';
import 'pronunciation_button.dart';

class ReviewSessionPage extends StatefulWidget {
  final String level;
  final String? topic;
  final ReviewStorage? storage;
  final DateTime Function()? clock;
  final Future<ContentCatalog> Function()? loadCatalog;
  final PracticeSpeech? speech;
  final Set<String>? itemIds;
  final bool previewDraftWords;
  const ReviewSessionPage(
      {super.key,
      this.level = 'A1',
      this.topic,
      this.storage,
      this.clock,
      this.speech,
      this.itemIds,
      this.previewDraftWords = false,
      this.loadCatalog});
  @override
  State<ReviewSessionPage> createState() => _ReviewSessionPageState();
}

class _ReviewSessionPageState extends State<ReviewSessionPage> {
  ReviewController? _controller;
  bool _loading = true,
      _busy = false,
      _started = false,
      _revealed = false,
      _includeNew = true;
  String? _error, _notice;
  bool _announced = false;
  @override
  void dispose() {
    unawaited(LearningAudio.instance.stop());
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Capture the account before awaiting content, so switches cannot rebind it.
      final storage = widget.storage ?? AccountReviewStorage.current();
      final catalog = await (widget.loadCatalog?.call() ??
          loadLearningCatalog(includeDrafts: kDebugMode));
      final controller = ReviewController(catalog, storage,
          clock: widget.clock,
          onlyItemIds: widget.itemIds,
          previewDrafts: kDebugMode);
      if (!mounted) return;
      if (!_announced) {
        _announced = true;
        unawaited(LearningAudio.instance.play(controller.canResume
            ? LearningCue.resumeIntro
            : LearningCue.practiceIntro));
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _error =
              'Could not open review data. Your saved progress has not been reset. Reopen this screen after signing in, or try again.';
        });
    }
  }

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final started = await _controller!
          .start(widget.level, widget.topic, includeNew: _includeNew);
      if (mounted && started)
        unawaited(LearningAudio.instance.play(LearningCue.tap));
      if (mounted)
        setState(() {
          _started = started;
          _revealed = false;
          if (!started)
            _notice =
                'No words to practise right now. Come back when words are due, or include new words.';
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _error =
              'Could not save the session. Check that you are still signed in and try again.';
        });
    } finally {
      if (mounted)
        setState(() {
          _busy = false;
        });
    }
  }

  Future<void> _answer(RecallAnswer answer) async {
    if (_busy || !_revealed) return;
    final controller = _controller!;
    final active = controller.session!;
    final id = active.ids[active.position];
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final saved = await controller.answer(answer,
          expectedPosition: active.position, expectedItemId: id);
      if (mounted && saved)
        unawaited(LearningAudio.instance.play(answer == RecallAnswer.remembered
            ? LearningCue.remembered
            : LearningCue.again));
      if (mounted && saved)
        setState(() {
          _revealed = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _error =
              'Your answer was not confirmed. Please try again; the current card is unchanged.';
        });
    } finally {
      if (mounted)
        setState(() {
          _busy = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final active = controller?.session;
    final theme = Theme.of(context);
    return Scaffold(
        appBar: AppBar(title: const Text('Review words')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : controller == null
                ? Center(
                    child: Padding(
                        padding: const EdgeInsets.all(24),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(_error ?? 'Review unavailable.'),
                          TextButton(
                              onPressed: _load, child: const Text('Retry')),
                        ])))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                        child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 640),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                      _started
                                          ? '${active!.level} · ${active.topic ?? 'All topics'}'
                                          : '${widget.level} · ${widget.topic ?? 'All topics'}',
                                      style: theme.textTheme.titleMedium),
                                  const SizedBox(height: 8),
                                  const Text(
                                      'Self-reported recall, not a quiz score. Progress is saved on this device for your account.'),
                                  const SizedBox(height: 20),
                                  if (kDebugMode && widget.previewDraftWords)
                                    const Text(
                                        'Preview vocabulary · Editorial review pending'),
                                  if (_error != null)
                                    Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 16),
                                        child: Text(_error!,
                                            style: TextStyle(
                                                color:
                                                    theme.colorScheme.error))),
                                  if (!_started) ...[
                                    Text(
                                        'Recall first. Reveal, then choose how it went.',
                                        style: theme.textTheme.headlineSmall),
                                    const SizedBox(height: 12),
                                    Text(
                                        '${controller.dueCount(widget.level, widget.topic)} due · ${controller.newCount(widget.level, widget.topic)} new words'),
                                    Text(widget.itemIds == null
                                        ? 'Up to 10 words per session. Due words come first.'
                                        : 'Review this mission’s words, including words already scheduled for later. Your normal review dates are preserved for early Remembered answers.'),
                                    if (!controller.canResume &&
                                        widget.itemIds == null)
                                      CheckboxListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title:
                                              const Text('Include new words'),
                                          value: _includeNew,
                                          onChanged: _busy
                                              ? null
                                              : (value) => setState(() =>
                                                  _includeNew = value ?? true)),
                                    if (controller.canResume)
                                      Text(
                                          'Saved session: ${active!.level} · ${active.topic ?? 'All topics'} · ${active.position}/${active.ids.length} answered'),
                                    if (active != null &&
                                        !active.complete &&
                                        !controller.canResume)
                                      const Text(
                                          'Saved session content has changed. Starting again keeps completed word progress.'),
                                    const SizedBox(height: 16),
                                    FilledButton.icon(
                                        onPressed: _busy ? null : _start,
                                        icon: const Icon(Icons.play_arrow),
                                        label: Text(_busy
                                            ? 'Saving…'
                                            : controller.canResume
                                                ? 'Continue saved session'
                                                : 'Start practice')),
                                    if (_notice != null)
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(top: 16),
                                          child: Text(_notice!)),
                                  ] else if (active!.complete) ...[
                                    const Icon(Icons.auto_awesome_rounded,
                                        color: Color(0xff9969cf), size: 56),
                                    const SizedBox(height: 12),
                                    Text('Session complete',
                                        style: theme.textTheme.headlineMedium),
                                    const SizedBox(height: 16),
                                    Text(
                                        '${active.remembered} Remembered · ${active.again} Again'),
                                    const SizedBox(height: 16),
                                    Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                            color: const Color(0xffeee5fb),
                                            borderRadius:
                                                BorderRadius.circular(20)),
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  '${controller.progress.on((widget.clock?.call() ?? DateTime.now()).toLocal()).reviews} / ${controller.progress.goal} reviews today',
                                                  style: theme
                                                      .textTheme.titleLarge),
                                              const SizedBox(height: 8),
                                              const Text(
                                                  'Every honest answer is a step forward. Your daily activity is saved on this device.')
                                            ])),
                                    const SizedBox(height: 16),
                                    const Text(
                                        'Again words return after 10 minutes. Remembered words return at increasing intervals, starting at 1 day.'),
                                    const SizedBox(height: 20),
                                    FilledButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('Done')),
                                  ] else ...[
                                    Text(
                                        'Word ${active.position + 1} of ${active.ids.length}'),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                        value:
                                            active.position / active.ids.length,
                                        semanticsLabel:
                                            'Review session progress'),
                                    const SizedBox(height: 20),
                                    Card(
                                        child: Padding(
                                            padding: const EdgeInsets.all(24),
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  Text(
                                                      '${controller.current!.item.article} ${controller.current!.item.lemma}'
                                                          .trim(),
                                                      style: theme.textTheme
                                                          .headlineMedium,
                                                      textAlign:
                                                          TextAlign.center),
                                                  const SizedBox(height: 20),
                                                  PronunciationButton(
                                                      key: ValueKey(controller
                                                          .current!.item.id),
                                                      text:
                                                          '${controller.current!.item.article} ${controller.current!.item.lemma}'
                                                              .trim(),
                                                      speech: widget.speech),
                                                  if (!_revealed)
                                                    const Text(
                                                        'Try to recall the meaning before revealing it.',
                                                        textAlign:
                                                            TextAlign.center),
                                                  if (_revealed) ...[
                                                    Text(
                                                        controller.current!.item
                                                            .meaning,
                                                        style: theme.textTheme
                                                            .titleLarge),
                                                    const SizedBox(height: 12),
                                                    Text(controller
                                                        .current!.item.example),
                                                    const SizedBox(height: 8),
                                                    Text(controller.current!
                                                        .exampleTranslation),
                                                    if (controller.current!
                                                            .partOfSpeech ==
                                                        'noun')
                                                      Text(
                                                          'Plural: ${controller.current!.item.plural}'),
                                                    if (controller.current!
                                                        .usageNotes.isNotEmpty)
                                                      Text(controller
                                                          .current!.usageNotes),
                                                  ],
                                                ]))),
                                    const SizedBox(height: 20),
                                    if (!_revealed)
                                      FilledButton(
                                          onPressed: () {
                                            unawaited(LearningAudio.instance
                                                .play(LearningCue.tap));
                                            setState(() => _revealed = true);
                                          },
                                          child: const Text('Reveal meaning')),
                                    if (_revealed)
                                      Wrap(
                                          alignment: WrapAlignment.center,
                                          spacing: 16,
                                          runSpacing: 12,
                                          children: [
                                            OutlinedButton(
                                                onPressed: _busy
                                                    ? null
                                                    : () => _answer(
                                                        RecallAnswer.again),
                                                child: const Text('Again')),
                                            FilledButton(
                                                onPressed: _busy
                                                    ? null
                                                    : () => _answer(RecallAnswer
                                                        .remembered),
                                                child:
                                                    const Text('Remembered')),
                                          ]),
                                    if (_busy)
                                      const Padding(
                                          padding: EdgeInsets.only(top: 12),
                                          child: Text('Saving answer…')),
                                  ],
                                  const SizedBox(height: 24),
                                ])))));
  }
}
