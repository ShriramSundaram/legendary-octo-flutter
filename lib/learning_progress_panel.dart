import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'data/learning_catalog_loader.dart';
import 'mission_goals_panel.dart';
import 'data/account_store.dart';
import 'data/content_catalog.dart';
import 'data/learning_progress.dart';
import 'data/review_controller.dart';
import 'data/review_store.dart';
import 'review_session_page.dart';

final learningProgressRoutes = RouteObserver<ModalRoute<dynamic>>();

class LearningProgressPanel extends StatefulWidget {
  const LearningProgressPanel(
      {super.key,
      this.level = 'A1',
      this.storage,
      this.loadCatalog,
      this.loadHistory,
      this.clock,
      this.compact = false,
      this.showReviewAction = true});
  final String level;
  final ReviewStorage? storage;
  final Future<ContentCatalog> Function()? loadCatalog;
  final List<dynamic> Function()? loadHistory;
  final DateTime Function()? clock;
  final bool compact, showReviewAction;
  @override
  State<LearningProgressPanel> createState() => _LearningProgressPanelState();
}

class _LearningProgressPanelState extends State<LearningProgressPanel>
    with WidgetsBindingObserver, RouteAware {
  ModalRoute<dynamic>? route;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = ModalRoute.of(context);
    if (next != route) {
      learningProgressRoutes.unsubscribe(this);
      route = next;
      if (next != null) learningProgressRoutes.subscribe(this, next);
    }
  }

  @override
  void didPopNext() {
    _load();
  }

  ReviewController? controller;
  ReviewStorage? storage;
  AccountStore? account;
  ContentCatalog? catalog;
  QuizAccuracy accuracy = const QuizAccuracy(0, 0);
  String? error;
  bool details = false, saving = false;
  int generation = 0;
  Timer? timer;
  DateTime get now => (widget.clock?.call() ?? DateTime.now()).toLocal();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    try {
      account = AccountStore.current();
    } catch (_) {}
    storage = widget.storage ??
        (account == null ? null : AccountReviewStorage(account!));
    _load();
    timer = Timer.periodic(const Duration(minutes: 1), (_) => _load());
  }

  @override
  void didUpdateWidget(covariant LearningProgressPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.level != oldWidget.level) _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  @override
  void dispose() {
    generation++;
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    learningProgressRoutes.unsubscribe(this);
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++generation;
    try {
      if (storage == null) throw StateError('No account');
      final ContentCatalog content;
      final cached = catalog;
      if (cached != null) {
        content = cached;
      } else {
        content = await (widget.loadCatalog?.call() ??
            loadLearningCatalog(includeDrafts: kDebugMode));
      }
      final next = ReviewController(content, storage!,
          clock: widget.clock, previewDrafts: kDebugMode);
      final history = widget.loadHistory?.call() ??
          (account?.get('practiceSessionsV1', defaultValue: const [])
                  as List? ??
              []);
      final nextAccuracy = QuizAccuracy.recent(history, now);
      if (!mounted || request != generation) return;
      setState(() {
        catalog = content;
        controller = next;
        accuracy = nextAccuracy;
        error = null;
      });
    } catch (_) {
      if (mounted && request == generation)
        setState(() {
          controller = null;
          error = storage == null
              ? 'Sign in to see your daily progress.'
              : 'Could not open progress. Saved practice has not been reset.';
        });
    }
  }

  Future<void> _goal() async {
    final selected = await showModalBottomSheet<int>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your daily rhythm',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      const Text(
                          'A small goal you can enjoy. Every honest recall answer counts.'),
                      const SizedBox(height: 16),
                      Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [5, 10, 15, 20]
                              .map((value) => ChoiceChip(
                                  label: Text('$value reviews'),
                                  selected: controller!.progress.goal == value,
                                  onSelected: (_) =>
                                      Navigator.pop(context, value)))
                              .toList())
                    ]))));
    if (selected == null || !mounted) return;
    setState(() => saving = true);
    try {
      await controller!.setDailyGoal(selected);
      await _load();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not save your daily goal. Please retry.')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  String get reviewLevel {
    final c = controller!;
    if (c.canResume) return c.session!.level;
    if (c.dueCount(widget.level, null) > 0) return widget.level;
    for (final level in contentLevels) {
      if (c.dueCount(level, null) > 0) return level;
    }
    if (c.newCount(widget.level, null) > 0) return widget.level;
    return contentLevels.firstWhere((l) => c.newCount(l, null) > 0,
        orElse: () => widget.level);
  }

  Future<void> _review() async {
    final level = reviewLevel;
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ReviewSessionPage(
            level: level,
            storage: storage,
            clock: widget.clock,
            loadCatalog: () async => catalog!)));
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c == null)
      return Card(
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: error == null
                  ? const LinearProgressIndicator()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Text(error!),
                          if (storage != null)
                            TextButton(
                                onPressed: _load,
                                child: const Text('Retry progress'))
                        ])));
    final today = c.progress.on(now);
    final goal = c.progress.goal;
    final due = contentLevels.fold<int>(0, (n, l) => n + c.dueCount(l, null));
    final theme = Theme.of(context);
    final complete = today.reviews >= goal;
    return Container(
        padding: EdgeInsets.all(widget.compact ? 16 : 20),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xfff0eaff), Color(0xfffaf8ff)]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xffded2f7))),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Text(
                    complete
                        ? '🌟 You showed up today!'
                        : '🌱 Your daily rhythm',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                TextButton.icon(
                    onPressed: saving ? null : _goal,
                    icon: const Icon(Icons.tune, size: 18),
                    label: const Text('Edit goal'))
              ]),
          const SizedBox(height: 8),
          Text('${today.reviews} / $goal reviews today',
              style: theme.textTheme.headlineSmall?.copyWith(
                  color: const Color(0xff4939a5), fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                  minHeight: 10,
                  color: const Color(0xff7452c5),
                  backgroundColor: const Color(0xffe1d6f4),
                  value: (today.reviews / goal).clamp(0.0, 1.0),
                  semanticsLabel: 'Daily review goal',
                  semanticsValue: '${today.reviews} of $goal reviews')),
          const SizedBox(height: 12),
          Text(complete
              ? 'Goal reached. Enjoy a break, or keep exploring.'
              : '${goal - today.reviews} more to your goal. A few words is a good start.'),
          const SizedBox(height: 8),
          Text('$due words due • Saved on this device',
              style: theme.textTheme.bodySmall),
          if (widget.showReviewAction) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
                onPressed: _review,
                icon: Icon(c.canResume
                    ? Icons.play_arrow_rounded
                    : Icons.school_outlined),
                label: Text(
                    c.canResume ? 'Continue saved session' : 'Start review'))
          ],
          TextButton.icon(
              onPressed: () => setState(() => details = !details),
              icon: Icon(details ? Icons.expand_less : Icons.insights_outlined),
              label: Text(details ? 'Hide activity' : 'Your last 7 days')),
          if (details) ...[
            const Divider(),
            const SizedBox(height: 8),
            Text('A week of small steps', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            _week(c.progress, now),
            const SizedBox(height: 16),
            Text(
                'Today’s recall: ${today.remembered} Remembered · ${today.again} Again'),
            const Text('Recall ratings are your own assessment.'),
            Text('${today.sessions} practice sessions completed today'),
            const SizedBox(height: 12),
            Text(accuracy.answered == 0
                ? 'Quiz accuracy: no answered test questions in the last 7 days yet.'
                : 'Quiz accuracy: ${(100 * accuracy.correct / accuracy.answered).round()}% · ${accuracy.correct}/${accuracy.answered} answered questions correct'),
            const SizedBox(height: 8),
            Text(
                'Quiz accuracy uses saved results from the last 7 days, up to 50 tests.',
                style: theme.textTheme.bodySmall),
            Text(
                'Activity starts with reviews recorded in this update. Cross-device sync is not available yet.',
                style: theme.textTheme.bodySmall),
          ],
          if (account != null && !widget.compact)
            MissionGoalsPanel(
                key: ValueKey('mission-goals:$generation'), account: account!),
        ]));
  }

  Widget _week(LearningProgress progress, DateTime local) {
    final dates = List.generate(
        7, (i) => DateTime(local.year, local.month, local.day - 6 + i));
    final maxReviews = dates.fold<int>(
        1, (n, d) => progress.on(d).reviews > n ? progress.on(d).reviews : n);
    const names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: dates.map((date) {
          final count = progress.on(date).reviews;
          return Expanded(
              child: Semantics(
                  label: '${learningDay(date)}: $count reviews',
                  child: ExcludeSemantics(
                      child: Column(children: [
                    FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('$count',
                            style: const TextStyle(fontSize: 12))),
                    const SizedBox(height: 6),
                    SizedBox(
                        height: 56,
                        child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                                width: 16,
                                height: count == 0
                                    ? 4
                                    : 8 + 48 * count / maxReviews,
                                decoration: BoxDecoration(
                                    color: count == 0
                                        ? const Color(0xffded5ef)
                                        : const Color(0xff8b65cc),
                                    borderRadius: BorderRadius.circular(8))))),
                    const SizedBox(height: 6),
                    Text(names[date.weekday - 1],
                        style: const TextStyle(fontSize: 12))
                  ]))));
        }).toList());
  }
}
