import 'dart:math';

String learningDay(DateTime local) =>
    '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';

String newReviewSessionId() => List.generate(16,
        (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'))
    .join();

class PracticeDay {
  final int again, remembered, sessions;
  const PracticeDay({this.again = 0, this.remembered = 0, this.sessions = 0});
  int get reviews => again + remembered;
  Map<String, dynamic> toMap() =>
      {'again': again, 'remembered': remembered, 'sessions': sessions};
  factory PracticeDay.fromMap(Map value) {
    for (final key in ['again', 'remembered', 'sessions']) {
      if (value[key] is! int || value[key] < 0 || value[key] > 1000000000) {
        throw const FormatException('Invalid daily progress');
      }
    }
    return PracticeDay(
        again: value['again'],
        remembered: value['remembered'],
        sessions: value['sessions']);
  }
}

/// Account-local aggregates. Credit day is fixed at answer time, never
/// recomputed after travel. Stored with the review cursor in one atomic write.
/// M06 will own cross-device synchronization; these are not cloud totals.
class LearningProgress {
  final int goal;
  final Map<String, PracticeDay> days;
  final List<String> credited;
  LearningProgress(
      {this.goal = 10, Map<String, PracticeDay>? days, List<String>? credited})
      : days = Map.unmodifiable(days ?? {}),
        credited = List.unmodifiable(credited ?? []);
  factory LearningProgress.fromMap(Map? value) {
    if (value == null) return LearningProgress();
    if (value['schemaVersion'] != 1 ||
        value['goal'] is! int ||
        value['goal'] < 1 ||
        value['goal'] > 100 ||
        value['days'] is! Map ||
        value['credited'] is! List ||
        (value['days'] as Map).length > 400 ||
        (value['credited'] as List).length > 5000) {
      throw const FormatException('Unsupported daily progress');
    }
    final days = <String, PracticeDay>{};
    for (final entry in (value['days'] as Map).entries) {
      if (entry.key is! String ||
          !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(entry.key) ||
          entry.value is! Map)
        throw const FormatException('Invalid progress day');
      days[entry.key] = PracticeDay.fromMap(entry.value);
    }
    final credited = List<String>.from(value['credited']);
    if (credited.toSet().length != credited.length ||
        credited.any((id) => id.isEmpty || id.length > 100)) {
      throw const FormatException('Invalid review credit');
    }
    return LearningProgress(
        goal: value['goal'], days: days, credited: credited);
  }
  PracticeDay on(DateTime local) =>
      days[learningDay(local)] ?? const PracticeDay();
  LearningProgress withGoal(int value) {
    if (value < 1 || value > 100) throw ArgumentError('Invalid daily goal');
    return LearningProgress(goal: value, days: days, credited: credited);
  }

  LearningProgress record(
      {required String id,
      required DateTime local,
      required bool remembered,
      required bool sessionComplete}) {
    if (credited.contains(id)) return this;
    final day = learningDay(local), previous = on(local);
    final next = Map<String, PracticeDay>.from(days)..remove(day);
    next[day] = PracticeDay(
        again: previous.again + (remembered ? 0 : 1),
        remembered: previous.remembered + (remembered ? 1 : 0),
        sessions: previous.sessions + (sessionComplete ? 1 : 0));
    if (next.length > 400) next.remove(next.keys.first);
    final ids = [...credited, id];
    return LearningProgress(
        goal: goal,
        days: next,
        credited: ids.skip(max(0, ids.length - 5000)).toList());
  }

  Map<String, dynamic> toMap() => {
        'schemaVersion': 1,
        'goal': goal,
        'days': {
          for (final entry in days.entries) entry.key: entry.value.toMap()
        },
        'credited': credited
      };
}

class QuizAccuracy {
  final int correct, answered;
  const QuizAccuracy(this.correct, this.answered);

  /// Last seven local calendar days; only scored, submitted choices count.
  factory QuizAccuracy.recent(Iterable<dynamic> history, DateTime localNow) {
    var correct = 0, answered = 0;
    final today = DateTime(localNow.year, localNow.month, localNow.day);
    final earliest = DateTime(today.year, today.month, today.day - 6);
    final seen = <String>{};
    for (final raw in history) {
      if (raw is! Map ||
          raw['id'] is! String ||
          !seen.add(raw['id']) ||
          raw['correct'] is! int ||
          raw['wrong'] is! int ||
          raw['correct'] < 0 ||
          raw['wrong'] < 0) continue;
      final at = DateTime.tryParse('${raw['completedAt']}')?.toLocal();
      if (at == null || at.isBefore(earliest) || at.isAfter(localNow)) continue;
      correct += raw['correct'] as int;
      answered += (raw['correct'] as int) + (raw['wrong'] as int);
    }
    return QuizAccuracy(correct, answered);
  }
}
