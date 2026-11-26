import 'package:flutter/material.dart';
import 'data/practice_session.dart';
import 'data/test_report.dart';

/// Shared presentation for topic tests and the profile vocabulary snapshot.
class PracticeResults extends StatelessWidget {
  const PracticeResults(
      {super.key,
      required this.session,
      required this.level,
      required this.quickCheck,
      required this.textAlternatives,
      required this.onPractice,
      required this.onRetake,
      required this.onDone,
      required this.onRetrySave,
      required this.saving,
      required this.saved,
      this.topic,
      this.saveError});
  final PracticeSession session;
  final String level;
  final bool quickCheck, saving, saved;
  final String? topic, saveError;
  final Set<String> textAlternatives;
  final VoidCallback onPractice, onRetake, onDone, onRetrySave;

  @override
  Widget build(BuildContext context) {
    final report = TestReport(session);
    final suggested = quickCheck ? report.suggestedLevel ?? 'B2' : level;
    final recognition =
        session.cards.where((c) => c.mode == PracticeMode.recognition).toList();
    final listening = session.cards
        .where((c) =>
            c.mode == PracticeMode.listening &&
            !textAlternatives.contains(c.id))
        .toList();
    final alternatives =
        session.cards.where((c) => textAlternatives.contains(c.id)).toList();
    final theme = Theme.of(context);
    final missed = report.reviewNext;
    final fraction =
        session.scoredTotal == 0 ? 0.0 : session.correct / session.scoredTotal;
    final perfect = session.scoredTotal > 0 &&
        session.correct == session.scoredTotal &&
        !session.timedOut;
    final emoji = session.timedOut
        ? '⏳'
        : perfect
            ? '🎉'
            : fraction >= .7
                ? '🌟'
                : '🌱';
    final encouragement = session.timedOut
        ? 'A snapshot of where you got to'
        : perfect
            ? 'Every sampled answer correct!'
            : fraction >= .7
                ? 'A strong effort — keep building on it'
                : 'Every attempt gives you a place to grow';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xff4939a5),
                    Color(0xff30266c),
                    Color(0xff185a70)
                  ]),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xff4939a5).withAlpha(40),
                    blurRadius: 24,
                    offset: const Offset(0, 8))
              ]),
          child: Column(children: [
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white.withAlpha(28),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(quickCheck ? 'VOCABULARY SNAPSHOT' : 'TOPIC TEST',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2))),
            const SizedBox(height: 16),
            TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: MediaQuery.of(context).disableAnimations
                    ? Duration.zero
                    : const Duration(milliseconds: 550),
                curve: Curves.easeOutBack,
                builder: (_, value, child) =>
                    Transform.scale(scale: .6 + value * .4, child: child),
                child: ExcludeSemantics(
                    child: Text(emoji, style: const TextStyle(fontSize: 48)))),
            const SizedBox(height: 8),
            Text(session.timedOut ? 'Time is up' : 'Test complete',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
                quickCheck
                    ? 'Vocabulary snapshot • A1–B2'
                    : '$level • ${topic ?? 'All topics'}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xffdddafa))),
            const SizedBox(height: 12),
            Semantics(
                label:
                    '${session.correct} of ${session.scoredTotal} answers correct',
                child: ExcludeSemantics(
                    child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                      Text('${session.correct}',
                          style: const TextStyle(
                              fontSize: 56,
                              height: 1.1,
                              color: Colors.white,
                              fontWeight: FontWeight.w800)),
                      Text('/ ${session.scoredTotal}',
                          style: const TextStyle(
                              fontSize: 28,
                              color: Color(0xffdddafa),
                              fontWeight: FontWeight.w600)),
                    ]))),
            const SizedBox(height: 8),
            Text('${(fraction * 100).round()}% correct',
                style: const TextStyle(
                    color: Color(0xffa6f0dc),
                    fontWeight: FontWeight.w700,
                    fontSize: 18)),
            const SizedBox(height: 16),
            ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 8,
                    color: const Color(0xffa6f0dc),
                    backgroundColor: Colors.white.withAlpha(32),
                    semanticsLabel: 'Correct answers',
                    semanticsValue: '${(fraction * 100).round()} percent')),
            const SizedBox(height: 16),
            Text(encouragement,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w500)),
          ])),
      const SizedBox(height: 20),
      LayoutBuilder(builder: (context, constraints) {
        final large = MediaQuery.textScalerOf(context).scale(14) > 19;
        final columns = !large && constraints.maxWidth >= 330 ? 3 : 1;
        final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
        final tiles = <Widget>[
          _ScoreTile(
              width: width,
              label: 'Correct: ${session.correct}',
              icon: Icons.check_circle_outline,
              tint: const Color(0xff087858)),
          _ScoreTile(
              width: width,
              label: 'Wrong: ${session.wrong}',
              icon: Icons.refresh_rounded,
              tint: const Color(0xffae3d48)),
          _ScoreTile(
              width: width,
              label: 'Unanswered: ${session.unanswered}',
              icon: Icons.hourglass_empty_rounded,
              tint: const Color(0xff81520b)),
        ];
        if (columns == 3) {
          return IntrinsicHeight(
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                tiles[0],
                const SizedBox(width: 10),
                tiles[1],
                const SizedBox(width: 10),
                tiles[2]
              ]));
        }
        return Column(children: [
          tiles[0],
          const SizedBox(height: 10),
          tiles[1],
          const SizedBox(height: 10),
          tiles[2]
        ]);
      }),
      const SizedBox(height: 20),
      _ResultSection(
          title: 'What was tested',
          icon: Icons.insights_rounded,
          children: [
            Text(
                '${session.cards.map((c) => c.answer).toSet().length} words • ${session.cards.length} questions',
                style: theme.textTheme.bodyMedium),
            if (recognition.isNotEmpty)
              _Breakdown(
                  label: 'Meaning recognition',
                  cards: recognition,
                  report: report,
                  color: const Color(0xff6754c0)),
            if (listening.isNotEmpty)
              _Breakdown(
                  label: 'Listening',
                  cards: listening,
                  report: report,
                  color: const Color(0xff087f8c)),
            if (alternatives.isNotEmpty)
              _Breakdown(
                  label: 'Text alternatives (not listening)',
                  cards: alternatives,
                  report: report,
                  color: const Color(0xff9a640f)),
          ]),
      if (quickCheck) ...[
        const SizedBox(height: 16),
        _ResultSection(
            title: 'Vocabulary by level',
            icon: Icons.stacked_bar_chart_rounded,
            children: [
              for (final l in ['A1', 'A2', 'B1', 'B2'])
                _Breakdown(
                    label: l,
                    cards: session.cards.where((c) => c.level == l).toList(),
                    report: report,
                    color: const Color(0xff6754c0)),
              Text(
                  'C1/C2 not assessed. This sample does not measure grammar, speaking or establish a CEFR level.',
                  style: theme.textTheme.bodySmall),
              Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(14)),
                  child: Text(report.suggestedLevel == null
                      ? 'All sampled answers were correct. Try more B2 vocabulary; this does not establish a B2 level.'
                      : 'Suggested practice: $suggested. Some sampled words at this level need another look; this does not assign your German level.')),
            ]),
      ],
      if (!quickCheck) ...[
        const SizedBox(height: 16),
        Text(
            'The selected level describes this vocabulary, not your assessed ability. This test does not establish or certify a CEFR level.',
            style: theme.textTheme.bodySmall),
      ],
      const SizedBox(height: 16),
      _ResultSection(
          title: 'Review next',
          icon: Icons.auto_stories_rounded,
          children: [
            if (missed.isEmpty)
              const Text(
                  'All sampled answers were correct. Continue Start practice with new or due words.')
            else ...[
              const Text(
                  'Revisit these missed or unanswered words before testing again:'),
              for (var i = 0; i < missed.length; i++)
                Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(10),
                        borderRadius: BorderRadius.circular(14)),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.bookmark_outline_rounded,
                              size: 20, color: theme.colorScheme.primary),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(
                                  '${missed[i].answer} — ${missed[i].prompt}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500))),
                        ])),
            ],
            FilledButton.icon(
                onPressed: onPractice,
                icon: const Icon(Icons.school_outlined),
                label: Text('Start practice • $suggested')),
          ]),
      const SizedBox(height: 20),
      if (saving) const _SaveStatus(icon: Icons.sync, text: 'Saving result…'),
      if (saved)
        const _SaveStatus(
            icon: Icons.check_circle_outline,
            text: 'Result saved on this device for your account.'),
      if (saveError != null) ...[
        _SaveStatus(icon: Icons.info_outline, text: saveError!),
        TextButton(onPressed: onRetrySave, child: const Text('Retry saving')),
      ],
      const SizedBox(height: 12),
      OutlinedButton.icon(
          onPressed: saving ? null : onRetake,
          icon: const Icon(Icons.replay_rounded),
          label: const Text('Retake test')),
      const SizedBox(height: 8),
      TextButton(onPressed: onDone, child: const Text('Done')),
    ]);
  }
}

class _ScoreTile extends StatelessWidget {
  const _ScoreTile(
      {required this.width,
      required this.label,
      required this.icon,
      required this.tint});
  final double width;
  final String label;
  final IconData icon;
  final Color tint;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
        width: width,
        child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: tint.withAlpha(dark ? 38 : 16),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: tint.withAlpha(45))),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon,
                  color: dark ? Color.lerp(tint, Colors.white, .6) : tint),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      color: dark ? Color.lerp(tint, Colors.white, .7) : tint,
                      fontWeight: FontWeight.w700)),
            ])));
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection(
      {required this.title, required this.icon, required this.children});
  final String title;
  final IconData icon;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.colorScheme.outline.withAlpha(35))),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
                child: Text(title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)))
          ]),
          const SizedBox(height: 16),
          ...children.expand((child) => [child, const SizedBox(height: 12)]),
        ]));
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown(
      {required this.label,
      required this.cards,
      required this.report,
      required this.color});
  final String label;
  final List<PracticeCard> cards;
  final TestReport report;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final correct =
        cards.where((c) => report.outcome(c)?['correct'] == true).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('$label: ${report.count(cards)}',
          style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
              value: cards.isEmpty ? 0 : correct / cards.length,
              minHeight: 7,
              backgroundColor: color.withAlpha(24),
              color: color,
              semanticsLabel: label,
              semanticsValue: report.count(cards))),
    ]);
  }
}

class _SaveStatus extends StatelessWidget {
  const _SaveStatus({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
      ]);
}
