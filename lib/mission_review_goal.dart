import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'data/account_store.dart';
import 'data/missions.dart';
import 'data/review_store.dart';
import 'review_session_page.dart';

/// Derived from persisted answers, never from opening a result screen.
int missionReviewedCount(Mission mission, Map<String, dynamic> attempt,
    Map<String, dynamic>? review) {
  final completed = DateTime.tryParse(attempt['completedAt']?.toString() ?? '');
  if (completed == null || review == null) return 0;
  if (review['schemaVersion'] != 1 || review['states'] is! Map) {
    throw const FormatException('Unsupported review progress');
  }
  final states = review['states'] as Map;
  return mission.usefulWords.toSet().where((id) {
    final state = states[id];
    final last = state is Map
        ? DateTime.tryParse(state['lastAttempt']?.toString() ?? '')
        : null;
    return last != null && !last.isBefore(completed);
  }).length;
}

class MissionReviewGoal extends StatefulWidget {
  const MissionReviewGoal(
      {super.key,
      required this.mission,
      required this.attempt,
      this.storage,
      this.onReviewed});
  final Mission mission;
  final Map<String, dynamic> attempt;
  final ReviewStorage? storage;
  final VoidCallback? onReviewed;
  @override
  State<MissionReviewGoal> createState() => _MissionReviewGoalState();
}

class _MissionReviewGoalState extends State<MissionReviewGoal> {
  @override
  Widget build(BuildContext context) {
    final m = widget.mission;
    if (m.usefulWords.isEmpty) return const SizedBox.shrink();
    try {
      final storage =
          widget.storage ?? AccountReviewStorage(AccountStore.current());
      final count = missionReviewedCount(m, widget.attempt, storage.read());
      final total = m.usefulWords.toSet().length;
      final done = count == total;
      return Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: done ? const Color(0xffe4f5ec) : const Color(0xffffefd8),
              borderRadius: BorderRadius.circular(24)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(done ? '🌟 Review goal achieved!' : '🎯 Your next review goal',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(m.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
                '$count / $total words and expressions reviewed since this mission.'),
            const SizedBox(height: 12),
            LinearProgressIndicator(
                value: count / total,
                semanticsLabel: 'Mission vocabulary review goal'),
            const SizedBox(height: 8),
            Text(done
                ? 'Well done! Keep your daily review rhythm.'
                : 'Reveal each meaning and choose Again or Remembered. Finish any saved review first; this goal stays here.'),
            if (kDebugMode && m.status == 'draft')
              const Text('Preview vocabulary · Editorial review pending',
                  style: TextStyle(fontSize: 12)),
            TextButton.icon(
                icon: const Icon(Icons.style_outlined),
                label: Text(done
                    ? 'Practise these words again'
                    : 'Review mission words'),
                onPressed: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ReviewSessionPage(
                              level: m.level,
                              itemIds: m.usefulWords.toSet(),
                              storage: storage,
                              previewDraftWords: m.status == 'draft')));
                  if (mounted) {
                    setState(() {});
                    widget.onReviewed?.call();
                  }
                }),
          ]));
    } catch (_) {
      return const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
              'Could not open this review goal. Saved progress has not been reset.'));
    }
  }
}
