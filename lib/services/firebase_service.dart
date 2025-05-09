import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../models/notification.dart';
import 'api_service.dart';
import 'storage_service.dart';

// Must be top-level
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (message.notification != null) {
    final notification = AppNotification(
      id: null,
      title: message.notification!.title ?? 'No Title',
      body: message.notification!.body ?? 'No Body',
      taskId: message.data['task_id'] ?? '',
      timestamp: DateTime.now(),
    );
    await StorageService.saveNotification(notification);
  }
  print('🔙 Background message: ${message.notification?.title}');
}

class FirebaseService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> initialize({required String userId}) async {
    await _requestPermission();
    await _initializeLocalNotifications();

    String? token = await _messaging.getToken();
    if (token != null) {
      await _sendTokenToBackend(token, userId);
    }

    _messaging.onTokenRefresh.listen((token) async {
      await _sendTokenToBackend(token, userId);
    });

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('📲 Foreground message: ${message.notification?.title}');
      if (message.notification != null) {
        final notification = AppNotification(
          id: null,
          title: message.notification!.title ?? 'No Title',
          body: message.notification!.body ?? 'No Body',
          taskId: message.data['task_id'] ?? '',
          timestamp: DateTime.now(),
        );
        await StorageService.saveNotification(notification);
        await showNotification(message);
      }
    });

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // App opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📦 Notification opened: ${message.notification?.title}');
      final taskId = message.data['task_id'];
      if (taskId != null) {
        navigatorKey.currentState?.pushNamed('/task_details', arguments: taskId);
      }
    });

    // App opened from terminated state
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      final taskId = initialMessage.data['task_id'];
      if (taskId != null) {
        navigatorKey.currentState?.pushNamed('/task_details', arguments: taskId);
      }
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotificationsPlugin.initialize(settings);
  }

  Future<void> _requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('🔐 Notification permission: ${settings.authorizationStatus}');
  }

  Future<void> _sendTokenToBackend(String token, String userId) async {
    final success = await ApiService.sendToken(userId, token);
    print(success ? '✅ Token sent to backend' : '❌ Failed to send token');
  }

  Future<void> showNotification(RemoteMessage message) async {
    final String channelId = message.notification?.android?.channelId ?? 'default_channel';

    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      'Default Notifications',
      importance: Importance.high,
      showBadge: true,
      playSound: true,
    );

    final AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      0,
      message.notification?.title ?? '',
      message.notification?.body ?? '',
      notificationDetails,
      payload: "my_data",
    );
  }
}
