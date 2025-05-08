import 'package:firebase_backend/services/storage_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_backend/services/api_service.dart';
import '../main.dart';
import '../models/notification.dart';

class FirebaseService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize({required String userId}) async {
    // Request notification permissions
    await _requestPermission();

    // Get and send FCM token
    String? token = await _messaging.getToken();
    if (token != null) {
      await _sendTokenToBackend(token, userId);
    }

    // Handle token refresh
    _messaging.onTokenRefresh.listen((token) async {
      await _sendTokenToBackend(token, userId);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('Foreground message: ${message.notification?.title}');
      if (message.notification != null) {
        final notification = AppNotification(
          id: null, // Local notifications don't have a server ID
          title: message.notification!.title ?? 'No Title',
          body: message.notification!.body ?? 'No Body',
          taskId: message.data['task_id'] ?? '',
          timestamp: DateTime.now(),
        );
        await StorageService.saveNotification(notification);
      }
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle notification tap when app is opened
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification opened: ${message.notification?.title}');
      final taskId = message.data['task_id'];
      if (taskId != null) {
        navigatorKey.currentState?.pushNamed('/task_details', arguments: taskId);
      }
    });

    // Check initial message (e.g., app opened from terminated state)
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      final taskId = initialMessage.data['task_id'];
      if (taskId != null) {
        navigatorKey.currentState?.pushNamed('/task_details', arguments: taskId);
      }
    }
  }

  Future<void> _requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    }
  }

  Future<void> _sendTokenToBackend(String token, String userId) async {
    final success = await ApiService.sendToken(userId, token);
    print(success ? 'Token sent to backend' : 'Failed to send token');
  }
}

// Background message handler (top-level function)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (message.notification != null) {
    final notification = AppNotification(
      id: null, // Local notifications don't have a server ID
      title: message.notification!.title ?? 'No Title',
      body: message.notification!.body ?? 'No Body',
      taskId: message.data['task_id'] ?? '',
      timestamp: DateTime.now(),
    );
    await StorageService.saveNotification(notification);
  }
  print("Background message: ${message.notification?.title}");
}