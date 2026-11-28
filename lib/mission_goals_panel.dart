import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/account_store.dart';
import 'data/missions.dart';
import 'data/review_store.dart';
import 'mission_review_goal.dart';

List<({Mission mission, Map<String, dynamic> attempt})> completedMissionGoals(
    List<Mission> definitions, List<Map<String, dynamic>> history) {
  final latest = <String, ({Mission mission, Map<String, dynamic> attempt})>{};
  for (final saved in history) {
    final definition = definitions
        .where((m) =>
            m.id == saved['missionId'] && m.version == saved['contentVersion'])
        .firstOrNull;
    if (definition == null)
      throw const FormatException('Missing saved mission');
    MissionController.validateSnapshot(definition, saved);
    if (saved['position'] != definition.steps.length) continue;
    final completed = DateTime.tryParse(saved['completedAt']?.toString() ?? '');
    if (completed == null)
      throw const FormatException('Missing completion time');
    final previous = latest[definition.id];
    if (previous == null ||
        completed.isAfter(DateTime.parse(previous.attempt['completedAt']))) {
      latest[definition.id] = (mission: definition, attempt: saved);
    }
  }
  return latest.values.toList()
    ..sort((a, b) => (b.attempt['completedAt'] as String)
        .compareTo(a.attempt['completedAt'] as String));
}

class MissionGoalsPanel extends StatefulWidget {
  const MissionGoalsPanel({super.key, required this.account});
  final AccountStore account;
  @override
  State<MissionGoalsPanel> createState() => _MissionGoalsPanelState();
}

class _MissionGoalsPanelState extends State<MissionGoalsPanel> {
  bool expanded = false;
  late final data = Future.wait([
    rootBundle.loadString('assets/missions_catalog_v1.json'),
    rootBundle.loadString('assets/missions_archive_v1.json'),
  ]).then((s) => [
        ...decodeMissions(s[0], preview: kDebugMode),
        ...decodeMissions(s[1], preview: kDebugMode, archive: true),
      ]);
  @override
  Widget build(BuildContext context) => FutureBuilder<List<Mission>>(
      future: data,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return const Text('Could not load mission review goals.');
        if (!snapshot.hasData) return const SizedBox.shrink();
        try {
          final storage = AccountMissionStorage(widget.account);
          final review = AccountReviewStorage(widget.account);
          final history = storage.history();
          final ids = <String>{};
          for (final m in snapshot.requireData) {
            if (!ids.add(m.id)) continue;
            final saved = storage.read(m.id);
            if (saved != null && !history.any((r) => r['id'] == saved['id']))
              history.add(saved);
          }
          final records = completedMissionGoals(snapshot.requireData, history);
          if (records.isEmpty) return const SizedBox.shrink();
          final pending = records
              .where((r) =>
                  missionReviewedCount(r.mission, r.attempt, review.read()) <
                  r.mission.usefulWords.toSet().length)
              .toList();
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Text(
                    '🗺️ ${records.length} missions completed · ${pending.length} review goals open',
                    style: Theme.of(context).textTheme.titleMedium),
                ...pending.take(expanded ? pending.length : 3).map((r) =>
                    MissionReviewGoal(
                        key: ValueKey(r.attempt['id']),
                        mission: r.mission,
                        attempt: r.attempt,
                        storage: review,
                        onReviewed: () => setState(() {}))),
                if (pending.length > 3)
                  TextButton(
                      onPressed: () => setState(() => expanded = !expanded),
                      child: Text(expanded
                          ? 'Show fewer goals'
                          : 'Show all mission goals')),
              ]);
        } catch (_) {
          return const Text(
              'Could not open mission goals. Saved progress has not been reset.');
        }
      });
}
