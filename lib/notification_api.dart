import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/rxdart.dart';

class NotificationApi {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static final onNotifications = BehaviorSubject<String?>();

  static Future initialize({bool initScheduled = false}) async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('app_logo');

    final InitializationSettings settings =
        InitializationSettings(android: androidInitializationSettings);

    await _notifications.initialize(
      settings,
      onSelectNotification: (payload) async {
        onNotifications.add(payload);
      },
    );
  }

  static Future notificationDetails() async {
    return NotificationDetails(
        android: AndroidNotificationDetails(
            'channel id', 'channel name', 'channel description',
            importance: Importance.high));
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
