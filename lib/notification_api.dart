import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'data/reminder_controller.dart';
import 'data/reminder_models.dart';

class NotificationApi extends ReminderBackend {
  static const _native = MethodChannel('german_reminder/reminders');
  static final instance = NotificationApi();
  final plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _initialized;
  static String? pendingPayload;
  static final List<void Function()> _handlers = [];
  static void registerTapHandler(void Function() handler) {
    _handlers.remove(handler);
    _handlers.add(handler);
  }

  static void unregisterTapHandler(void Function() handler) {
    _handlers.remove(handler);
  }

  Future<void> initialize() => _initialized ??= _initialize();
  Future<void> _initialize() async {
    tz_data.initializeTimeZones();
    await plugin.initialize(
        const InitializationSettings(
            android: AndroidInitializationSettings('ic_stat_reminder'),
            iOS: DarwinInitializationSettings(
                requestAlertPermission: false,
                requestBadgePermission: false,
                requestSoundPermission: false)),
        onDidReceiveNotificationResponse: (response) {
      pendingPayload = response.payload;
      if (_handlers.isNotEmpty) _handlers.last();
    });
    final launch = await plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true)
      pendingPayload = launch?.notificationResponse?.payload;
  }

  @override
  Future<String> timezone() async {
    final name = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(name));
    return name;
  }

  @override
  Future<bool> permission({bool request = false}) async {
    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null)
      return (request
              ? await android.requestNotificationsPermission()
              : await android.areNotificationsEnabled()) ??
          false;
    if (request)
      return await plugin
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    return false;
  }

  @override
  Future<void> schedule(int id, tz.TZDateTime date, ReminderPayload payload,
      {bool weekly = false, int? wallHour, int? wallMinute}) async {
    if (Platform.isAndroid) {
      await _native.invokeMethod<void>('schedule', {
        'id': id,
        'payload': payload.encode(),
        'at': date.millisecondsSinceEpoch,
        'hour': wallHour ?? date.hour,
        'minute': wallMinute ?? date.minute
      });
      return;
    }
    await plugin.zonedSchedule(
        id,
        'Time for German 🌱',
        'A few words today. Tap to review.',
        date,
        const NotificationDetails(
            android: AndroidNotificationDetails(
                'study_reminders_v1', 'Study reminders',
                channelDescription: 'Your optional German study reminders',
                icon: 'ic_stat_reminder',
                importance: Importance.defaultImportance,
                priority: Priority.defaultPriority,
                visibility: NotificationVisibility.private),
            iOS: DarwinNotificationDetails()),
        payload: payload.encode(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents:
            weekly ? DateTimeComponents.dayOfWeekAndTime : null);
  }

  @override
  Future<void> cancel(int id) async {
    await plugin.cancel(id);
    if (Platform.isAndroid)
      await _native.invokeMethod<void>('cancel', {'id': id});
  }

  @override
  Future<Map<int, String?>> pending() async {
    if (Platform.isAndroid) {
      final rows =
          await _native.invokeMapMethod<String, String>('pending') ?? {};
      return {for (final row in rows.entries) int.parse(row.key): row.value};
    }
    return {
      for (final n in await plugin.pendingNotificationRequests())
        n.id: n.payload
    };
  }

  @override
  Future<void> rebaseClock() async {
    if (Platform.isAndroid) await _native.invokeMethod<void>('reconcile');
  }

  @override
  Future<void> bindOwner(String? owner) async {
    if (Platform.isAndroid)
      await _native.invokeMethod<void>('owner', {'owner': owner});
  }
}
