import 'dart:async';
import 'data/learning_audio.dart';
import 'package:flutter/material.dart';
import 'data/missions.dart';
import 'data/account_store.dart';
import 'data/practice_speech.dart';
import 'mission_review_goal.dart';

class MissionPage extends StatefulWidget {
  const MissionPage(
      {super.key,
      required this.mission,
      this.previousVersion,
      this.storage,
      this.speech});
  final Mission mission;
  final Mission? previousVersion;
  final MissionStorage? storage;
  final PracticeSpeech? speech;
  @override
  State<MissionPage> createState() => _MissionPageState();
}

class _MissionPageState extends State<MissionPage> with WidgetsBindingObserver {
  MissionController? controller;
  PracticeSpeech? _speech;
  bool started = false,
      working = false,
      playing = false,
      textMode = false,
      retrying = false;
  int? selected;
  String? error;
  int speechGeneration = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  void _load() {
    try {
      controller = MissionController(widget.mission,
          widget.storage ?? AccountMissionStorage(AccountStore.current()),
          previousVersion: widget.previousVersion);
      if (controller!.complete) started = true;
      error = null;
    } catch (_) {
      error = 'Could not open your saved mission. It has not been reset.';
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      speechGeneration++;
      unawaited(_speech?.stop());
      if (mounted) setState(() => playing = false);
    }
  }

  @override
  void dispose() {
    unawaited(LearningAudio.instance.stop());
    speechGeneration++;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_speech?.stop());
    super.dispose();
  }

  Future<void> _act(Future<bool> Function() action,
      {bool begin = false, bool advance = false, LearningCue? cue}) async {
    if (working) return;
    setState(() {
      working = true;
      error = null;
    });
    try {
      final saved = await action();
      if (!mounted || !saved) return;
      speechGeneration++;
      await _speech?.stop();
      if (!mounted) return;
      unawaited(LearningAudio.instance.play(begin
          ? LearningCue.missionIntro
          : controller!.complete
              ? LearningCue.complete
              : cue ?? LearningCue.tap));
      setState(() {
        playing = false;
        if (begin) started = true;
        if (advance) {
          selected = null;
          textMode = false;
          retrying = false;
          playing = false;
        } else
          retrying = false;
      });
    } on StaleMission {
      if (mounted)
        setState(() {
          _load();
          selected = null;
          retrying = false;
          error =
              'Your saved place changed on another screen. The latest step is open.';
        });
    } catch (_) {
      if (mounted)
        setState(() => error =
            'Could not save this step. Please retry; your saved place is unchanged.');
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> _listen() async {
    if (playing || controller == null || controller!.complete) return;
    final generation = ++speechGeneration;
    final step = widget.mission.steps[controller!.position];
    setState(() => playing = true);
    final speech = _speech ??= widget.speech ?? GermanPracticeSpeech();
    var ok = false;
    try {
      ok = await speech.prepare() && await speech.speak(step.prompt);
    } catch (_) {}
    if (!mounted || generation != speechGeneration) return;
    setState(() {
      playing = false;
      if (!ok) textMode = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mission, c = controller, theme = Theme.of(context);
    return Scaffold(
        backgroundColor: const Color(0xfffaf8ff),
        appBar: AppBar(
            title: Text(m.title), backgroundColor: const Color(0xfffaf8ff)),
        body: c == null
            ? Center(
                child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(error ?? 'Mission unavailable.'),
                      TextButton(
                          onPressed: () => setState(_load),
                          child: const Text('Retry'))
                    ])))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (m.status == 'draft')
                                const Padding(
                                    padding: EdgeInsets.only(bottom: 12),
                                    child: Text(
                                        'Pilot preview · Content review pending',
                                        style: TextStyle(
                                            color: Color(0xff79589b)))),
                              if (error != null)
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Text(error!,
                                        style: TextStyle(
                                            color: theme.colorScheme.error))),
                              if (!started) ...[
                                Text(m.emoji,
                                    style: const TextStyle(fontSize: 60)),
                                const SizedBox(height: 16),
                                Text(m.objective,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                Text(
                                    '${m.level} · About ${m.minutes} minutes · ${m.steps.length} steps'),
                                const SizedBox(height: 24),
                                _bubble(m.situation, 'Your situation',
                                    const Color(0xffede2fc)),
                                const SizedBox(height: 20),
                                const Text(
                                    'Choose replies, hear the conversation and learn from each choice.'),
                                const SizedBox(height: 20),
                                FilledButton.icon(
                                    onPressed: working
                                        ? null
                                        : () => _act(c.begin, begin: true),
                                    icon: const Icon(Icons.play_arrow_rounded),
                                    label: Text(c.canResume
                                        ? 'Continue mission'
                                        : c.complete
                                            ? 'Play again'
                                            : 'Begin mission')),
                              ] else if (c.complete) ...[
                                const Text('🎉',
                                    style: TextStyle(fontSize: 56),
                                    textAlign: TextAlign.center),
                                Text('Mission complete!',
                                    style: theme.textTheme.headlineSmall,
                                    textAlign: TextAlign.center),
                                const SizedBox(height: 20),
                                _bubble(
                                    '${c.firstCorrect} / ${m.steps.length} first choices matched the situation.\nRetries helped you practise; they do not change this count.',
                                    'Your mission',
                                    const Color(0xffe9defb)),
                                const SizedBox(height: 16),
                                Text('You practised: ${m.objective}'),
                                const SizedBox(height: 16),
                                ...m.steps
                                    .where((s) =>
                                        (c.answers[s.id] as Map?)?['first'] !=
                                        s.correct)
                                    .map((s) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: _bubble(
                                            s.explanation,
                                            'Worth another look',
                                            Colors.white))),
                                if (m.steps.any((s) =>
                                    s.listening &&
                                    (c.answers[s.id] as Map?)?['textMode'] ==
                                        true))
                                  const Text(
                                      'Listening included a text alternative. This is not a listening-only score.'),
                                const SizedBox(height: 20),
                                MissionReviewGoal(
                                    mission: m, attempt: c.attempt!),
                                OutlinedButton.icon(
                                    onPressed: working
                                        ? null
                                        : () => _act(c.begin,
                                            begin: true, advance: true),
                                    icon: const Icon(Icons.replay),
                                    label: const Text('Play again')),
                                FilledButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Back to missions')),
                              ] else
                                ..._step(m, c, theme),
                              const SizedBox(height: 20),
                              const Text(
                                  'Progress is saved on this device. Cloud recovery is not available yet.',
                                  style: TextStyle(fontSize: 12)),
                            ])))));
  }

  List<Widget> _step(Mission m, MissionController c, ThemeData theme) {
    final step = m.steps[c.position];
    final feedback = c.feedback && !retrying;
    final answer = c.answers[step.id] as Map?;
    final correct = answer?['choice'] == step.correct;
    final chosen = feedback && answer != null ? answer['choice'] : selected;
    return [
      Text('Step ${c.position + 1} of ${m.steps.length}',
          style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
      LinearProgressIndicator(
          value: c.position / m.steps.length,
          semanticsLabel: 'Mission progress'),
      const SizedBox(height: 24),
      if (c.position > 0)
        ExpansionTile(
            title: const Text('Conversation so far'),
            children: List.generate(c.position, (i) {
              final previous = m.steps[i];
              final response = c.answers[previous.id] as Map;
              return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _bubble(previous.prompt, previous.speaker,
                            const Color(0xffeee5fb)),
                        const SizedBox(height: 8),
                        _bubble(previous.choices[response['choice'] as int],
                            'You', const Color(0xffffefdf))
                      ]));
            })),
      _bubble(
          step.listening && !textMode && !feedback
              ? 'Listen to the speaker, then choose a suitable reply.'
              : step.prompt,
          step.speaker,
          const Color(0xffeee5fb)),
      const SizedBox(height: 8),
      Text(
          step.listening && textMode
              ? 'Text mode'
              : step.listening
                  ? 'Listening step'
                  : step.translation,
          style: theme.textTheme.bodySmall),
      Wrap(spacing: 12, children: [
        TextButton.icon(
            onPressed: playing ? null : _listen,
            icon: const Icon(Icons.volume_up_outlined),
            label: Text(playing ? 'Playing…' : 'Listen / replay')),
        if (step.listening && !textMode && !feedback)
          TextButton(
              onPressed: () => setState(() => textMode = true),
              child: const Text('Use text instead'))
      ]),
      const SizedBox(height: 16),
      if (!feedback)
        ...List.generate(
            step.choices.length,
            (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.all(18),
                        backgroundColor: chosen == index
                            ? const Color(0xffe7d9fb)
                            : Colors.white),
                    onPressed: working || feedback
                        ? null
                        : () {
                            if (!playing)
                              unawaited(
                                  LearningAudio.instance.play(LearningCue.tap));
                            setState(() => selected = index);
                          },
                    child: Row(children: [
                      Icon(
                          chosen == index
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(step.choices[index],
                              style: const TextStyle(color: Color(0xff35254e))))
                    ])))),
      if (feedback) ...[
        _bubble(step.choices[answer!['choice'] as int], 'Your reply',
            const Color(0xffffefdf)),
        const SizedBox(height: 12),
        if (!correct) ...[
          _bubble(step.choices[step.correct], 'A helpful reply', Colors.white),
          const SizedBox(height: 12)
        ],
        _bubble(
            step.explanation,
            correct ? '✨ That fits the situation!' : 'A useful learning moment',
            correct ? const Color(0xffe6f3ed) : const Color(0xffffefdf)),
        if (!correct)
          TextButton(
              onPressed: working
                  ? null
                  : () => setState(() {
                        retrying = true;
                        selected = null;
                      }),
              child: const Text('Try another reply')),
        const SizedBox(height: 16),
        FilledButton(
            onPressed: working
                ? null
                : () {
                    speechGeneration++;
                    unawaited(_speech?.stop());
                    _act(() => c.advance(expectedPosition: c.position),
                        advance: true);
                  },
            child: Text(c.position == m.steps.length - 1
                ? 'Finish mission'
                : 'Continue')),
      ] else
        FilledButton(
            onPressed: selected == null || working
                ? null
                : () => _act(
                    () => c.submit(selected!,
                        expectedPosition: c.position,
                        textMode: textMode,
                        retry: retrying),
                    cue: selected == step.correct
                        ? LearningCue.correct
                        : LearningCue.wrong),
            child: const Text('Check response')),
    ];
  }

  Widget _bubble(String text, String title, Color color) => Container(
      padding: const EdgeInsets.all(20),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(22)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(text)
      ]));
}
