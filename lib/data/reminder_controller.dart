import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'account_store.dart';
import 'reminder_models.dart';

abstract class ReminderBackend {
  Future<String> timezone();
  Future<bool> permission({bool request = false});
  Future<void> schedule(int id, tz.TZDateTime date, ReminderPayload payload,
      {bool weekly = false, int? wallHour, int? wallMinute});
  Future<void> cancel(int id);
  Future<Map<int, String?>> pending();
  Future<void> rebaseClock() async {}
  Future<void> bindOwner(String? owner) async {}
}

abstract class ReminderStorage {
  String get owner;
  bool get current;
  Map<String, dynamic>? read();
  Future<void> write(Map<String, dynamic> settings);
}

class AccountReminderStorage implements ReminderStorage {
  final AccountStore account;
  AccountReminderStorage(this.account);
  @override
  String get owner => reminderOwner(account.uid);
  @override
  bool get current => AccountStore.activeUid == account.uid;
  @override
  Map<String, dynamic>? read() {
    final value = account.get('remindersV1');
    return value == null ? null : Map<String, dynamic>.from(value as Map);
  }

  @override
  Future<void> write(Map<String, dynamic> settings) async {
    await account.put('remindersV1', settings);
    if (settings['enabled'] == true || (settings['totalMs'] as int) > 0)
      await account.box.delete('reminderSuppressed:' + owner);
  }
}

class ReminderController extends ChangeNotifier {
  final ReminderStorage storage;
  final ReminderBackend backend;
  final DateTime Function() clock;
  late ReminderSettings settings;
  bool busy = false, permissionGranted = false, closed = false;
  String timezoneName = '', error = '';
  Future<void> _tail = Future.value();
  Future<void> get idle => _tail;
  ReminderController(this.storage, this.backend, {DateTime Function()? clock})
      : clock = clock ?? DateTime.now {
    final saved = storage.read();
    settings =
        saved == null ? ReminderSettings() : ReminderSettings.fromMap(saved);
  }
  void _check() {
    if (closed || !storage.current)
      throw StateError('Account changed. Reopen reminders.');
  }

  Future<void> _run(Future<void> Function() action) {
    final operation = _tail.then((_) async {
      _check();
      busy = true;
      error = '';
      notifyListeners();
      try {
        await action();
        _check();
      } catch (_) {
        error =
            'Could not update reminders. Check notification permission and try again.';
        rethrow;
      } finally {
        busy = false;
        notifyListeners();
      }
    });
    _tail = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> _cancelAll() async {
    for (final id in [reminderTimerId, ...reminderWeeklyIds]) {
      await backend.cancel(id);
    }
  }

  Future<void> _permission() async {
    permissionGranted = await backend.permission(request: true);
    _check();
    if (!permissionGranted)
      throw StateError('Notification permission is needed.');
    await backend.bindOwner(storage.owner);
    _check();
  }

  ReminderPayload payload(String kind) => ReminderPayload(
      owner: storage.owner,
      revision:
          kind == 'timer' ? settings.timerRevision : settings.weeklyRevision,
      level: kind == 'timer' ? settings.timerLevel : settings.level,
      kind: kind,
      itemId: kind == 'timer' ? settings.itemId : null);
  bool accepts(ReminderPayload value) =>
      storage.current &&
      !closed &&
      value.owner == storage.owner &&
      (value.kind == 'weekly'
          ? settings.enabled &&
              value.revision == settings.weeklyRevision &&
              value.level == settings.level &&
              value.itemId == null
          : settings.hasTimer &&
              !settings.paused &&
              value.revision == settings.timerRevision &&
              value.level == settings.timerLevel &&
              value.itemId == settings.itemId);
  Future<void> _apply(ReminderSettings next) async {
    _check();
    await storage.write(next.toMap());
    _check();
    settings = next;
    try {
      timezoneName = await backend.timezone();
      _check();
      final zone = tz.getLocation(timezoneName);
      for (final id in reminderWeeklyIds) {
        await backend.cancel(id);
        _check();
      }
      if (next.enabled) {
        for (final day in next.days) {
          await backend.schedule(
              2100 + day,
              nextReminderDay(zone, clock(), day, next.hour, next.minute),
              payload('weekly'),
              weekly: true,
              wallHour: next.hour,
              wallMinute: next.minute);
          _check();
        }
      }
      if (!next.hasTimer || next.paused) {
        await backend.cancel(reminderTimerId);
      } else if (next.dueAt!.isAfter(clock().toUtc())) {
        await backend.schedule(reminderTimerId,
            tz.TZDateTime.from(next.dueAt!, tz.UTC), payload('timer'));
        _check();
      }
      await backend.rebaseClock();
      _check();
    } catch (_) {
      // Stable IDs prevent duplicate alarms. Failed schedules are not shown as active.
      try {
        await _cancelAll();
      } catch (_) {/* The UI must report unconfirmed status. */}
      if (storage.current && !closed) {
        settings = next.copy(enabled: false, clearTimer: true);
        try {
          await storage.write(settings.toMap());
        } catch (_) {/* Preserve the visible error. */}
      }
      rethrow;
    }
  }

  Future<void> refresh() => _run(() async {
        timezoneName = await backend.timezone();
        _check();
        permissionGranted = await backend.permission();
        _check();
        if (permissionGranted) {
          await _apply(settings);
        } else {
          await _cancelAll();
        }
      });
  Future<void> saveDaily(
          {required bool enabled,
          required int hour,
          required int minute,
          required Set<int> days,
          required String level}) =>
      _run(() async {
        final next = settings.copy(
            enabled: enabled,
            hour: hour,
            minute: minute,
            days: days,
            level: level,
            weeklyRevision: reminderRevision());
        if (enabled) await _permission();
        await _apply(next);
      });
  Future<void> startTimer(Duration duration,
          {required String level, String? itemId}) =>
      _run(() async {
        if (duration.inSeconds < 5 ||
            duration.inHours > 24 ||
            duration.inMilliseconds > 86400000)
          throw ArgumentError('Choose between 5 seconds and 24 hours.');
        await _permission();
        await _apply(settings.copy(clearTimer: true).copy(
            timerLevel: level,
            itemId: itemId,
            totalMs: duration.inMilliseconds,
            pausedMs: 0,
            dueAt: clock().toUtc().add(duration),
            timerRevision: reminderRevision()));
      });
  Future<void> pauseTimer() => _run(() async {
        final remaining = settings.remaining(clock());
        if (!settings.hasTimer || settings.paused || remaining == Duration.zero)
          return;
        await _apply(settings.copy(pausedMs: remaining.inMilliseconds));
      });
  Future<void> resumeTimer() => _run(() async {
        if (!settings.paused) return;
        await _permission();
        await _apply(settings.copy(
            pausedMs: 0,
            dueAt:
                clock().toUtc().add(Duration(milliseconds: settings.pausedMs)),
            timerRevision: reminderRevision()));
      });
  Future<void> cancelTimer() => _run(() async {
        await _apply(
            settings.copy(clearTimer: true, timerRevision: reminderRevision()));
      });
  Future<void> disableAll() => _run(() async {
        await _apply(settings.copy(
            enabled: false,
            clearTimer: true,
            weeklyRevision: reminderRevision(),
            timerRevision: reminderRevision()));
      });
}
