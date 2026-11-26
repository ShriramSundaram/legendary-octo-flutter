import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:timezone/timezone.dart' as tz;
import 'content_catalog.dart';

String reminderOwner(String uid) => sha256.convert(utf8.encode(uid)).toString();
String reminderRevision() => List.generate(16,
        (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'))
    .join();
const reminderTimerId = 2100;
const reminderWeeklyIds = [2101, 2102, 2103, 2104, 2105, 2106, 2107];

class ReminderPayload {
  final String owner, revision, level, kind;
  final String? itemId;
  const ReminderPayload(
      {required this.owner,
      required this.revision,
      required this.level,
      required this.kind,
      this.itemId});
  String encode() => jsonEncode({
        'v': 1,
        'owner': owner,
        'revision': revision,
        'level': level,
        'kind': kind,
        if (itemId != null) 'itemId': itemId
      });
  static ReminderPayload? parse(String? text) {
    try {
      if (text == null || text.length > 1024) return null;
      final row = jsonDecode(text) as Map<String, dynamic>;
      if (row.keys.any((k) => ![
                'v',
                'owner',
                'revision',
                'level',
                'kind',
                'itemId'
              ].contains(k)) ||
          row['v'] != 1 ||
          row['owner'] is! String ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(row['owner']) ||
          row['revision'] is! String ||
          !RegExp(r'^[a-f0-9]{32}$').hasMatch(row['revision']) ||
          !contentLevels.contains(row['level']) ||
          !['timer', 'weekly'].contains(row['kind']) ||
          (row['itemId'] != null &&
              (row['itemId'] is! String ||
                  !RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(row['itemId']))))
        return null;
      return ReminderPayload(
          owner: row['owner'],
          revision: row['revision'],
          level: row['level'],
          kind: row['kind'],
          itemId: row['itemId']);
    } catch (_) {
      return null;
    }
  }
}

class ReminderSettings {
  final bool enabled;
  final int hour, minute;
  final Set<int> days;
  final String level, timerLevel, weeklyRevision, timerRevision;
  final String? itemId;
  final int totalMs, pausedMs;
  final DateTime? dueAt;
  ReminderSettings(
      {this.enabled = false,
      this.hour = 18,
      this.minute = 0,
      Set<int> days = const {1, 2, 3, 4, 5, 6, 7},
      this.level = 'A1',
      this.timerLevel = 'A1',
      String? weeklyRevision,
      String? timerRevision,
      this.itemId,
      this.totalMs = 0,
      this.pausedMs = 0,
      this.dueAt})
      : days = Set.unmodifiable(days),
        weeklyRevision = weeklyRevision ?? reminderRevision(),
        timerRevision = timerRevision ?? reminderRevision() {
    if (hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59 ||
        days.any((d) => d < 1 || d > 7) ||
        (enabled && days.isEmpty) ||
        !contentLevels.contains(level) ||
        !contentLevels.contains(timerLevel) ||
        totalMs < 0 ||
        totalMs > 86400000 ||
        pausedMs < 0 ||
        pausedMs > totalMs ||
        (dueAt != null && pausedMs > 0) ||
        (totalMs > 0 && pausedMs == 0 && dueAt == null) ||
        (totalMs == 0 && dueAt != null) ||
        (itemId != null &&
            !RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(itemId!)) ||
        !RegExp(r'^[a-f0-9]{32}$').hasMatch(this.weeklyRevision) ||
        !RegExp(r'^[a-f0-9]{32}$').hasMatch(this.timerRevision)) {
      throw const FormatException('Invalid reminder settings');
    }
  }
  bool get hasTimer => totalMs > 0;
  bool get paused => pausedMs > 0;
  Duration remaining(DateTime now) => Duration(
      milliseconds: paused
          ? pausedMs
          : dueAt == null
              ? 0
              : max(0, dueAt!.difference(now.toUtc()).inMilliseconds));
  Map<String, dynamic> toMap() => {
        'schemaVersion': 1,
        'enabled': enabled,
        'hour': hour,
        'minute': minute,
        'days': days.toList()..sort(),
        'level': level,
        'timerLevel': timerLevel,
        'weeklyRevision': weeklyRevision,
        'timerRevision': timerRevision,
        'itemId': itemId,
        'totalMs': totalMs,
        'pausedMs': pausedMs,
        'dueAt': dueAt?.toUtc().toIso8601String()
      };
  factory ReminderSettings.fromMap(Map<String, dynamic> row) {
    if (row['schemaVersion'] != 1 ||
        row['enabled'] is! bool ||
        row['days'] is! List)
      throw const FormatException('Unsupported reminder settings');
    return ReminderSettings(
        enabled: row['enabled'],
        hour: row['hour'] as int,
        minute: row['minute'] as int,
        days: Set<int>.from(row['days']),
        level: row['level'] as String,
        timerLevel: row['timerLevel'] as String,
        weeklyRevision: row['weeklyRevision'] as String,
        timerRevision: row['timerRevision'] as String,
        itemId: row['itemId'] as String?,
        totalMs: row['totalMs'] as int,
        pausedMs: row['pausedMs'] as int,
        dueAt: row['dueAt'] == null
            ? null
            : DateTime.parse(row['dueAt'] as String).toUtc());
  }
  ReminderSettings copy(
          {bool? enabled,
          int? hour,
          int? minute,
          Set<int>? days,
          String? level,
          String? timerLevel,
          String? weeklyRevision,
          String? timerRevision,
          String? itemId,
          int? totalMs,
          int? pausedMs,
          DateTime? dueAt,
          bool clearTimer = false}) =>
      ReminderSettings(
          enabled: enabled ?? this.enabled,
          hour: hour ?? this.hour,
          minute: minute ?? this.minute,
          days: days ?? this.days,
          level: level ?? this.level,
          timerLevel: timerLevel ?? this.timerLevel,
          weeklyRevision: weeklyRevision ?? this.weeklyRevision,
          timerRevision: timerRevision ?? this.timerRevision,
          itemId: clearTimer ? null : itemId ?? this.itemId,
          totalMs: clearTimer ? 0 : totalMs ?? this.totalMs,
          pausedMs: clearTimer ? 0 : pausedMs ?? this.pausedMs,
          dueAt: clearTimer || ((pausedMs ?? this.pausedMs) > 0)
              ? null
              : dueAt ?? this.dueAt);
}

tz.TZDateTime nextReminderDay(
    tz.Location zone, DateTime now, int weekday, int hour, int minute) {
  final local = tz.TZDateTime.from(now, zone);
  for (var offset = 0; offset <= 7; offset++) {
    final day = tz.TZDateTime(
        zone, local.year, local.month, local.day + offset, hour, minute);
    if (day.weekday == weekday && day.isAfter(local)) return day;
  }
  throw StateError('No next reminder day');
}
