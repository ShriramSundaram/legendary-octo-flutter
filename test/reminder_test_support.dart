import 'dart:convert';
import 'package:timezone/timezone.dart' as tz;
import 'package:germanreminder/data/reminder_controller.dart';
import 'package:germanreminder/data/reminder_models.dart';

class MemoryReminderStorage implements ReminderStorage {
  @override
  final String owner;
  @override
  bool current = true;
  Map<String, dynamic>? data;
  bool fail = false;
  int writes = 0;
  MemoryReminderStorage([String uid = 'A']) : owner = reminderOwner(uid);
  @override
  Map<String, dynamic>? read() => data == null
      ? null
      : Map<String, dynamic>.from(jsonDecode(jsonEncode(data)));
  @override
  Future<void> write(Map<String, dynamic> row) async {
    if (!current || fail) throw StateError('Fixture failure');
    writes++;
    data = Map<String, dynamic>.from(jsonDecode(jsonEncode(row)));
  }
}

class FakeReminderJob {
  final tz.TZDateTime date;
  final ReminderPayload payload;
  final bool weekly;
  final int? hour, minute;
  FakeReminderJob(this.date, this.payload, this.weekly, this.hour, this.minute);
}

class FakeReminderBackend extends ReminderBackend {
  String zone = 'Europe/Berlin';
  bool granted = true, failSchedule = false;
  int requests = 0;
  Future<void> Function()? beforeSchedule;
  final jobs = <int, FakeReminderJob>{};
  @override
  Future<String> timezone() async => zone;
  @override
  Future<bool> permission({bool request = false}) async {
    if (request) requests++;
    return granted;
  }

  @override
  Future<void> schedule(int id, tz.TZDateTime date, ReminderPayload payload,
      {bool weekly = false, int? wallHour, int? wallMinute}) async {
    await beforeSchedule?.call();
    if (failSchedule) throw StateError('Fixture failure');
    jobs[id] = FakeReminderJob(date, payload, weekly, wallHour, wallMinute);
  }

  @override
  Future<void> cancel(int id) async {
    jobs.remove(id);
  }

  @override
  Future<Map<int, String?>> pending() async =>
      {for (final e in jobs.entries) e.key: e.value.payload.encode()};
}
