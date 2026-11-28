import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:germanreminder/data/account_store.dart';
import 'package:germanreminder/notification_api.dart';
import 'package:germanreminder/reminder_runtime.dart';

/// Run only in the isolated releasecheck package. No Firebase or sign-in, no
/// permission prompt, and no notification is scheduled. Real Play data is never
/// opened. Explicit runtime checks remain enabled in optimized release builds.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var stage = 'isolation';
  var passed = false;
  final checks = <String>[];
  try {
    final context = await const MethodChannel('german_reminder/reminders')
        .invokeMapMethod<String, dynamic>('context');
    if (!kReleaseMode ||
        !const bool.fromEnvironment('REMINDER_RELEASE_SMOKE') ||
        context?['packageName'] != 'com.sundaram.germanreminder.releasecheck' ||
        context?['debuggable'] != false) {
      throw StateError(
          'Refusing to touch any non-isolated or non-release installation.');
    }
    checks.add('isolated-nondebuggable-release');
    stage = 'plugin-cache';
    await NotificationApi.instance.initialize();
    // Exact production failure: the first cancel writes an empty plugin cache;
    // the second needs the generic TypeToken signature retained by R8.
    await NotificationApi.instance.plugin.cancel(0);
    await NotificationApi.instance.plugin.cancel(2100);
    await NotificationApi.instance.plugin.cancel(2101);
    checks.add('repeated-real-plugin-cancellation');
    stage = 'fresh-reminder-binding';
    await Hive.initFlutter();
    final box = await Hive.openBox('LocalDatabase');
    await box.clear(); // Guard above guarantees this is only fake QA storage.
    const uid = 'release-smoke-account';
    AccountStore.activeUid = uid;
    await ReminderRuntime.bindAccount(uid);
    final controller = await ReminderRuntime.current();
    if (controller.settings.enabled || controller.settings.hasTimer)
      throw StateError('Unexpected opt-in');
    checks.add('fresh-reminder-initialization');
    final good = controller.settings.toMap();
    stage = 'retry-after-failure';
    AccountStore.activeUid = null;
    await ReminderRuntime.bindAccount(null);
    AccountStore.activeUid = uid;
    final store = AccountStore(box, uid);
    await store.put('remindersV1', {'schemaVersion': 999});
    var failed = false;
    try {
      await ReminderRuntime.current();
    } catch (_) {
      failed = true;
    }
    if (!failed || (store.get('remindersV1') as Map)['schemaVersion'] != 999)
      throw StateError('Bad settings were reset');
    await store.put('remindersV1', good);
    await ReminderRuntime.current();
    checks.add('retry-recovers-without-reset');
    stage = 'cleanup-after-failure';
    AccountStore.activeUid = null;
    await ReminderRuntime.bindAccount(null);
    AccountStore.activeUid = uid;
    await store.put('remindersV1', {'schemaVersion': 999});
    try {
      await ReminderRuntime.current();
    } catch (_) {}
    if (!await ReminderRuntime.disableBeforeSignOut())
      throw StateError('Emergency cleanup failed');
    if ((await NotificationApi.instance.pending()).isNotEmpty)
      throw StateError('Alarms remain');
    checks.add('logout-cleanup-survives-initialization-failure');
    AccountStore.activeUid = null;
    await ReminderRuntime.bindAccount(null);
    await Hive.close();
    passed = true;
    print('REMINDER_RELEASE_SMOKE ' +
        jsonEncode({'result': 'PASS', 'checks': checks}));
  } catch (error) {
    print('REMINDER_RELEASE_SMOKE ' +
        jsonEncode({
          'result': 'FAIL',
          'stage': stage,
          'type': '${error.runtimeType}',
          if (error is PlatformException) 'code': error.code
        }));
  }
  runApp(MaterialApp(
      home: Scaffold(
          body: Center(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(passed
                      ? 'Release checks passed. Your Play app was not changed.'
                      : 'Release check failed at $stage. Your Play app was not changed.'))))));
}
