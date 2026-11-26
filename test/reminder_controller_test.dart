import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:germanreminder/data/reminder_controller.dart';
import 'package:germanreminder/data/reminder_models.dart';
import 'reminder_test_support.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);
  late MemoryReminderStorage store;
  late FakeReminderBackend backend;
  late ReminderController controller;
  late DateTime now;
  setUp(() {
    store = MemoryReminderStorage();
    backend = FakeReminderBackend();
    now = DateTime.utc(2026, 11, 26, 10);
    controller = ReminderController(store, backend, clock: () => now);
  });
  test('first launch stays opted out and never requests permission', () async {
    await controller.refresh();
    expect(controller.settings.enabled, false);
    expect(backend.requests, 0);
    expect(backend.jobs, isEmpty);
  });
  test('selected days use stable IDs; edits replace rather than duplicate',
      () async {
    await controller.saveDaily(
        enabled: true, hour: 18, minute: 30, days: {4, 6}, level: 'A2');
    expect(backend.jobs.keys.toSet(), {2104, 2106});
    expect(
        backend.jobs[2104]!.date.toUtc(), DateTime.utc(2026, 11, 26, 17, 30));
    final old = backend.jobs[2104]!.payload;
    await controller.saveDaily(
        enabled: true, hour: 19, minute: 0, days: {1, 3}, level: 'B1');
    expect(backend.jobs.keys.toSet(), {2101, 2103});
    expect(controller.accepts(old), false);
    expect(controller.accepts(backend.jobs[2101]!.payload), true);
  });
  test('permission denial does not save or schedule a new opt in', () async {
    backend.granted = false;
    await expectLater(
        controller.startTimer(const Duration(minutes: 1), level: 'A1'),
        throwsStateError);
    expect(backend.jobs, isEmpty);
    expect(store.data, null);
    expect(controller.busy, false);
    expect(controller.error, isNotEmpty);
  });
  test(
      'failed native schedule rolls back the active state and cancels partial jobs',
      () async {
    backend.failSchedule = true;
    await expectLater(
        controller.saveDaily(
            enabled: true, hour: 18, minute: 0, days: {1, 2, 3}, level: 'A1'),
        throwsStateError);
    expect(backend.jobs, isEmpty);
    expect(controller.settings.enabled, false);
    expect(store.data!['enabled'], false);
  });
  test('failed preference save leaves the previous timer intact', () async {
    await controller.startTimer(const Duration(minutes: 5),
        level: 'B1', itemId: 'word_1');
    final original = backend.jobs[2100]!.payload.revision;
    store.fail = true;
    await expectLater(controller.pauseTimer(), throwsStateError);
    expect(controller.settings.paused, false);
    expect(backend.jobs[2100]!.payload.revision, original);
  });
  test(
      'timer captures context and survives pause, reload, resume and daily edits',
      () async {
    await controller.startTimer(const Duration(minutes: 10),
        level: 'A1', itemId: 'word_1');
    final original = backend.jobs[2100]!.payload;
    now = now.add(const Duration(seconds: 90));
    await controller.pauseTimer();
    expect(backend.jobs.containsKey(2100), false);
    expect(controller.settings.pausedMs, 510000);
    expect(controller.accepts(original), false);
    controller = ReminderController(store, backend, clock: () => now);
    now = now.add(const Duration(hours: 2));
    expect(controller.settings.remaining(now), const Duration(seconds: 510));
    await controller.resumeTimer();
    expect(backend.jobs[2100]!.date.toUtc(),
        now.add(const Duration(seconds: 510)));
    await controller.saveDaily(
        enabled: true, hour: 19, minute: 0, days: {1}, level: 'C1');
    final timer = backend.jobs[2100]!.payload;
    expect(timer.level, 'A1');
    expect(timer.itemId, 'word_1');
    expect(backend.jobs[2101]!.payload.level, 'C1');
  });
  test(
      'timezone changes rebase weekly wall time but preserve the timer UTC deadline',
      () async {
    await controller.startTimer(const Duration(minutes: 10), level: 'A1');
    final due = controller.settings.dueAt;
    await controller.saveDaily(
        enabled: true, hour: 18, minute: 0, days: {4}, level: 'A2');
    backend.zone = 'Asia/Kolkata';
    await controller.refresh();
    expect(controller.settings.dueAt, due);
    expect(backend.jobs[2100]!.date.toUtc(), due);
    expect(backend.jobs[2104]!.hour, 18);
    expect(backend.jobs[2104]!.date.location.name, 'Asia/Kolkata');
  });
  test('cancel timer retains daily schedule; disable all clears both',
      () async {
    await controller.saveDaily(
        enabled: true, hour: 18, minute: 0, days: {1, 2}, level: 'A1');
    await controller.startTimer(const Duration(minutes: 5), level: 'A1');
    final timer = backend.jobs[2100]!.payload;
    await controller.cancelTimer();
    expect(backend.jobs.keys.toSet(), {2101, 2102});
    expect(controller.accepts(timer), false);
    await controller.disableAll();
    expect(backend.jobs, isEmpty);
    expect(store.data!['enabled'], false);
    expect(store.data!['totalMs'], 0);
  });
  test('account switch during scheduling cancels the in-flight alarm',
      () async {
    backend.beforeSchedule = () async {
      store.current = false;
    };
    await expectLater(
        controller.startTimer(const Duration(minutes: 1), level: 'A1'),
        throwsStateError);
    expect(backend.jobs, isEmpty);
    final other = ReminderController(MemoryReminderStorage('B'), backend,
        clock: () => now);
    expect(other.settings.enabled, false);
    expect(other.settings.hasTimer, false);
  });
  test('corrupt or future settings are preserved rather than reset', () {
    store.data = {'schemaVersion': 9};
    expect(() => ReminderController(store, backend), throwsFormatException);
    expect(store.writes, 0);
    expect(
        () => ReminderSettings(enabled: true, days: {}), throwsFormatException);
    expect(() => ReminderSettings(totalMs: 10000), throwsFormatException);
  });
  test('invalid durations never ask permission', () async {
    await expectLater(
        controller.startTimer(Duration.zero, level: 'A1'), throwsArgumentError);
    await expectLater(
        controller.startTimer(const Duration(hours: 25), level: 'A1'),
        throwsArgumentError);
    expect(backend.requests, 0);
    expect(backend.jobs, isEmpty);
  });
  test('payload validation rejects malformed, oversized and forged contexts',
      () async {
    await controller.startTimer(const Duration(minutes: 1),
        level: 'B1', itemId: 'word_1');
    final valid = backend.jobs[2100]!.payload;
    expect(controller.accepts(ReminderPayload.parse(valid.encode())!), true);
    for (final value in [null, 'not json', '[]', '{}', 'x' * 1025])
      expect(ReminderPayload.parse(value), null);
    final row = jsonDecode(valid.encode()) as Map<String, dynamic>;
    for (final change in [
      {'v': 2},
      {'owner': 'bad'},
      {'level': 'A9'},
      {'itemId': '../private'},
      {'url': 'https://example.com'},
      {'kind': 'delete'}
    ]) {
      expect(ReminderPayload.parse(jsonEncode({...row, ...change})), null);
    }
    expect(
        controller.accepts(ReminderPayload(
            owner: valid.owner,
            revision: valid.revision,
            level: 'A1',
            kind: 'timer',
            itemId: 'word_1')),
        false);
    expect(
        controller.accepts(ReminderPayload(
            owner: reminderOwner('B'),
            revision: valid.revision,
            level: 'B1',
            kind: 'timer',
            itemId: 'word_1')),
        false);
  });
  test('Dart preview rolls over at the deadline and uses local weekdays', () {
    final zone = tz.getLocation('Europe/Berlin');
    expect(
        nextReminderDay(zone, DateTime.utc(2026, 11, 26, 17), 4, 18, 0).toUtc(),
        DateTime.utc(2026, 12, 3, 17));
  });
}
