import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint(
          'Notification tapped. Payload: ${response.payload}',
        );
      },
    );

    const androidChannel = AndroidNotificationChannel(
      'announcements_channel',
      'Campus Announcements',
      description: 'Notifications about NITC campus announcements',
      importance: Importance.max,
    );

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(androidChannel);

    await androidPlugin?.requestNotificationsPermission();

    FirebaseMessaging.onMessage.listen(
      _showForegroundNotification,
    );

    _initialized = true;

    debugPrint('Notification service initialized.');
  }

  Future<void> _showForegroundNotification(
    RemoteMessage message,
  ) async {
    final notification = message.notification;

    if (notification == null) {
      debugPrint('Foreground message has no notification payload.');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'announcements_channel',
      'Campus Announcements',
      channelDescription: 'Notifications about NITC campus announcements',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: notification.title ?? 'NITC Campus Announcement',
      body: notification.body ?? '',
      notificationDetails: notificationDetails,
      payload: message.data['announcement_id'],
    );

    debugPrint('Foreground notification displayed.');
  }
}
