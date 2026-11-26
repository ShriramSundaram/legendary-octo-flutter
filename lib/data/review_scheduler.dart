import 'learning_models.dart';

enum RecallAnswer { again, remembered }

/// Deliberately simple schedule, version 1. Intervals are elapsed UTC time.
class ReviewScheduler {
  static const version = 1;
  static const steps = [
    86400,
    259200,
    604800,
    1209600,
    2592000,
    5184000,
    10368000,
    15552000
  ];
  final DateTime Function() clock;
  ReviewScheduler({DateTime Function()? clock}) : clock = clock ?? DateTime.now;

  LearningState answer(
      String itemId, LearningState? previous, RecallAnswer answer) {
    if (previous != null &&
        (previous.itemId != itemId || previous.schedulerVersion != version)) {
      throw const FormatException('Unsupported review state');
    }
    var now = clock().toUtc();
    // A backwards device-clock adjustment must not move this word backwards.
    if (previous?.lastAttempt != null && now.isBefore(previous!.lastAttempt!)) {
      now = previous.lastAttempt!;
    }
    var interval = 600;
    if (answer == RecallAnswer.remembered) {
      interval = steps.firstWhere(
          (step) => step > (previous?.intervalSeconds ?? 0),
          orElse: () => steps.last);
    }
    final lapses =
        (previous?.lapseCount ?? 0) + (answer == RecallAnswer.again ? 1 : 0);
    return LearningState(
        itemId: itemId,
        dueAt: now.add(Duration(seconds: interval)),
        lastAttempt: now,
        intervalSeconds: interval,
        lapseCount: lapses.clamp(0, 1000000),
        schedulerVersion: version);
  }
}

Map<String, dynamic> encodeReviewState(LearningState state) => {
      'schemaVersion': 1,
      'itemId': state.itemId,
      'dueAt': state.dueAt.toIso8601String(),
      'lastAttempt': state.lastAttempt?.toIso8601String(),
      'intervalSeconds': state.intervalSeconds,
      'lapseCount': state.lapseCount,
      'schedulerVersion': state.schedulerVersion,
    };

LearningState decodeReviewState(Map<String, dynamic> data) {
  if (data['schemaVersion'] != 1 ||
      data['schedulerVersion'] != ReviewScheduler.version) {
    throw const FormatException('Unsupported review-state version');
  }
  return LearningState(
      itemId: data['itemId'] as String,
      dueAt: DateTime.parse(data['dueAt'] as String),
      lastAttempt: data['lastAttempt'] == null
          ? null
          : DateTime.parse(data['lastAttempt'] as String),
      intervalSeconds: data['intervalSeconds'] as int,
      lapseCount: data['lapseCount'] as int,
      schedulerVersion: data['schedulerVersion'] as int);
}
