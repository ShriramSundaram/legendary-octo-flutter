import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/rxdart.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
// These imports are used in the app but not directly in this file

class NotificationApi {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static final onNotifications = BehaviorSubject<String?>();

  /// Initialize the notification service
  /// [initScheduled] - Whether to initialize scheduled notifications
  static void initialize({bool initScheduled = false}) async {
    // Initialize timezone data (required for scheduled notifications)
    if (initScheduled) {
      tz_data.initializeTimeZones();
    }
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
      onDidReceiveLocalNotification: (id, title, body, payload) async {},
    );

    final InitializationSettings settings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: initializationSettingsDarwin,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
        final String? payload = notificationResponse.payload;
        if (payload != null) {
          onNotifications.add(payload);
        }
      },
    );
  }

  /// Creates notification details with default settings for Android and iOS
  ///
  /// Returns a [NotificationDetails] object configured for both platforms
  static NotificationDetails notificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'channel_id',
        'channel_name',
        channelDescription: 'German Reminder Notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Shows a notification with the provided details
  ///
  /// [id] - The notification ID (default: 0)
  /// [title] - The notification title
  /// [body] - The notification body text
  /// [description] - Additional description text (not used in basic notifications)
  /// [payload] - Optional payload data to be delivered when notification is tapped

  /// Request notification permissions for the application
  ///
  /// This is required for iOS and recommended for Android 13+
  static Future<bool?> requestPermissions() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final bool? granted =
            await androidImplementation.requestNotificationsPermission();
        return granted;
      }

      if (iosImplementation != null) {
        final bool? granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted;
      }

      return null;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return false;
    }
  }

  /// Shows a notification with the provided details
  ///
  /// [id] - The notification ID (default: 0)
  /// [title] - The notification title
  /// [body] - The notification body text
  /// [description] - Additional description text (not used in basic notifications)
  /// [payload] - Optional payload data to be delivered when notification is tapped
  static void showNotification(
      {int id = 0,
      String? title,
      String? body,
      String? description,
      String? payload}) async {
    try {
      final details = notificationDetails();
      await _notifications.show(id, title, body, details, payload: payload);
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  /// Cancel a specific notification by ID
  static void cancel(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all pending notifications
  static void cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Schedule a notification to show at a specific date and time
  ///
  /// [id] - The notification ID (default: 0)
  /// [title] - The notification title
  /// [body] - The notification body text
  /// [scheduledDate] - When to show the notification
  /// [payload] - Optional payload data to be delivered when notification is tapped
  static void scheduleNotification({
    int id = 0,
    String? title,
    String? body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      // Convert DateTime to TZDateTime
      final scheduledDateTZ = tz.TZDateTime.from(scheduledDate, tz.local);

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDateTZ,
        notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }
}
