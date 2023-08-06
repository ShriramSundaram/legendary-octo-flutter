import 'package:flutter/material.dart';
import 'package:germanreminder/main.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:germanreminder/secondPage.dart';
import 'package:rxdart/rxdart.dart';

class NotificationApi {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static final onNotifications = BehaviorSubject<String?>();

  static Future initialize({bool initScheduled = false}) async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwing =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
      onDidReceiveLocalNotification: (id, title, body, payload) {},
    );

    final InitializationSettings settings =
        InitializationSettings(android: androidInitializationSettings);

    await _notifications.initialize(settings, onDidReceiveNotificationResponse:
        (NotificationResponse notificationResponse) async {
      final String? payload = notificationResponse.payload;
    });
  }

  static Future notificationDetails() async {
    return NotificationDetails(
        android: AndroidNotificationDetails('channel id', 'channel name',
            importance: Importance.high, icon: '@mipmap/ic_launcher'));
  }

  static Future showNotification(
          {int id = 0,
          String? title,
          String? body,
          String? description,
          String? payload}) async =>
      _notifications.show(id, title, body, await notificationDetails(),
          payload: payload);
}
