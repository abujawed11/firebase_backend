// import 'dart:convert';
//
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../main.dart';
// import '../models/notification.dart';
// import 'api_service.dart';
// import 'storage_service.dart';
//
// // Must be top-level
// Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   if (message.notification != null) {
//     final notification = AppNotification(
//       id: null,
//       title: message.notification!.title ?? 'No Title',
//       body: message.notification!.body ?? 'No Body',
//       taskId: message.data['task_id'] ?? '',
//       timestamp: DateTime.now(),
//     );
//     await StorageService.saveNotification(notification);
//   }
//   print('🔙 Background message: ${message.notification?.title}');
// }
//
// class FirebaseService {
//   final FirebaseMessaging _messaging = FirebaseMessaging.instance;
//   final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
//   FlutterLocalNotificationsPlugin();
//
//   Future<void> initialize({required String userId}) async {
//     await _requestPermission();
//     await _initializeLocalNotifications();
//
//     String? token = await _messaging.getToken();
//     if (token != null) {
//       await _sendTokenToBackend(token, userId);
//     }
//
//     _messaging.onTokenRefresh.listen((token) async {
//       await _sendTokenToBackend(token, userId);
//     });
//
//     // Foreground messages
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
//       print('📲 Foreground message: ${message.notification?.title}');
//       if (message.notification != null) {
//         final notification = AppNotification(
//           id: null,
//           title: message.notification!.title ?? 'No Title',
//           body: message.notification!.body ?? 'No Body',
//           taskId: message.data['task_id'] ?? '',
//           timestamp: DateTime.now(),
//         );
//         await StorageService.saveNotification(notification);
//         await showNotification(message);
//       }
//     });
//
//     FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
//
//     // App opened from background
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       print('📦 Notification opened: ${message.notification?.title}');
//       final taskId = message.data['task_id'];
//       if (taskId != null) {
//         navigatorKey.currentState?.pushNamed('/task_details', arguments: taskId);
//       }
//     });
//
//     // App opened from terminated state
//     RemoteMessage? initialMessage = await _messaging.getInitialMessage();
//     if (initialMessage != null) {
//       final taskId = initialMessage.data['task_id'];
//       if (taskId != null) {
//         navigatorKey.currentState?.pushNamed('/task_details', arguments: taskId);
//       }
//     }
//   }
//
//   Future<void> _initializeLocalNotifications() async {
//     const AndroidInitializationSettings androidSettings =
//     AndroidInitializationSettings('@mipmap/ic_launcher');
//
//     const DarwinInitializationSettings iosSettings =
//     DarwinInitializationSettings();
//
//     const InitializationSettings settings = InitializationSettings(
//       android: androidSettings,
//       iOS: iosSettings,
//     );
//
//     await _localNotificationsPlugin.initialize(settings);
//   }
//
//   Future<void> _requestPermission() async {
//     NotificationSettings settings = await _messaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );
//     print('🔐 Notification permission: ${settings.authorizationStatus}');
//   }
//
//   Future<void> _sendTokenToBackend(String token, String userId) async {
//     final success = await ApiService.sendToken(userId, token);
//     print(success ? '✅ Token sent to backend' : '❌ Failed to send token');
//   }
//
//   // Future<void> showNotification(RemoteMessage message) async {
//   //   final String channelId = message.notification?.android?.channelId ?? 'default_channel';
//   //
//   //   final AndroidNotificationChannel channel = AndroidNotificationChannel(
//   //     channelId,
//   //     'Default Notifications',
//   //     importance: Importance.high,
//   //     showBadge: true,
//   //     playSound: true,
//   //   );
//   //
//   //   final AndroidNotificationDetails androidDetails =
//   //   AndroidNotificationDetails(
//   //     channel.id,
//   //     channel.name,
//   //     channelDescription: 'This channel is used for important notifications.',
//   //     importance: Importance.high,
//   //     priority: Priority.high,
//   //     playSound: true,
//   //   );
//   //
//   //   const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
//   //     presentAlert: true,
//   //     presentBadge: true,
//   //     presentSound: true,
//   //   );
//   //
//   //   final NotificationDetails notificationDetails = NotificationDetails(
//   //     android: androidDetails,
//   //     iOS: iosDetails,
//   //   );
//   //
//   //   await _localNotificationsPlugin.show(
//   //     0,
//   //     message.notification?.title ?? '',
//   //     message.notification?.body ?? '',
//   //     notificationDetails,
//   //     payload: "my_data",
//   //   );
//   // }
//
//   Future<void> showNotification(RemoteMessage message) async {
//     final String channelId = message.notification?.android?.channelId ?? 'default_channel';
//
//     final AndroidNotificationChannel channel = AndroidNotificationChannel(
//       channelId,
//       'Default Notifications',
//       importance: Importance.high,
//       showBadge: true,
//       playSound: true,
//     );
//
//     final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//       channel.id,
//       channel.name,
//       channelDescription: 'This channel is used for important notifications.',
//       importance: Importance.high,
//       priority: Priority.high,
//       playSound: true,
//     );
//
//     const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
//       presentAlert: true,
//       presentBadge: true,
//       presentSound: true,
//     );
//
//     final NotificationDetails notificationDetails = NotificationDetails(
//       android: androidDetails,
//       iOS: iosDetails,
//     );
//
//     // Create AppNotification
//     final notification = AppNotification(
//       title: message.notification?.title ?? message.data['title'] ?? 'New Task',
//       body: message.notification?.body ?? message.data['body'] ?? 'A new task has been assigned',
//       taskId: message.data['task_id'] ?? '',
//       timestamp: DateTime.now(),
//     );
//
//     // Store notification in SharedPreferences
//     final prefs = await SharedPreferences.getInstance();
//     List<String> storedNotifications = prefs.getStringList('notifications') ?? [];
//     storedNotifications.add(jsonEncode(notification.toJson()));
//     await prefs.setStringList('notifications', storedNotifications);
//     print('Stored notification: ${notification.toJson()}');
//     print('All stored notifications: $storedNotifications');
//
//     // Show notification
//     await _localNotificationsPlugin.show(
//       0,
//       notification.title,
//       notification.body,
//       notificationDetails,
//       payload: notification.taskId,
//     );
//   }
//
//
// }

import 'dart:async';

import 'package:firebase_backend/services/api_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_backend/models/notification.dart';
import 'dart:convert';

// Initialize FirebaseMessaging
final FirebaseMessaging _messaging = FirebaseMessaging.instance;

// Initialize local notifications
final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Assume navigatorKey is defined globally
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class FirebaseService {

  static final StreamController<AppNotification> _notificationStreamController =
  StreamController.broadcast();

  static Stream<AppNotification> get onNotification => _notificationStreamController.stream;

  Future<void> initialize({required String userId}) async {
    try {
      print('Starting FirebaseService initialization for user: $userId');
      await Firebase.initializeApp();
      print('Firebase initialized successfully');

      //await _requestPermission();
      await _initializeLocalNotifications();

      String? token = await _messaging.getToken();
      if (token != null) {
        await _sendTokenToBackend(token, userId);
        print('FCM Token sent: $token');
      } else {
        print('Failed to get FCM token');
      }

      _messaging.onTokenRefresh.listen((token) async {
        await _sendTokenToBackend(token, userId);
        print('FCM Token refreshed: $token');
      });

      // Moved onMessage listener to FirebaseService to prevent duplicates
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        print('📲 Foreground message: ${message.notification?.title ?? message.data['title']}');
        try {
          final notification = AppNotification(
            id: null,
            title: message.notification?.title ?? message.data['title'] ?? 'No Title',
            body: message.notification?.body ?? message.data['body'] ?? 'No Body',
            taskId: message.data['task_id'] ?? '',
            timestamp: DateTime.now(),
            isRead: false,
          );
          // Deduplicate notifications by taskId
          final prefs = await SharedPreferences.getInstance();
          List<String> storedNotifications = prefs.getStringList('notifications') ?? [];
          // Check for existing notification with the same taskId
          final existingIndex = storedNotifications.indexWhere((json) {
            try {
              final stored = AppNotification.fromJson(jsonDecode(json));
              return stored.taskId == notification.taskId;
            } catch (e) {
              return false;
            }
          });
          if (existingIndex != -1) {
            // Update existing notification (e.g., update timestamp)
            storedNotifications[existingIndex] = jsonEncode(notification.toJson());
            print('Updated existing notification with taskId: ${notification.taskId}');
          } else {
            // Add new notification
            storedNotifications.add(jsonEncode(notification.toJson()));
            print('Added new notification with taskId: ${notification.taskId}');
          }
          await prefs.setStringList('notifications', storedNotifications);
          print('Stored notification in SharedPreferences: ${notification.toJson()}');
          await showNotification(message);
          // Broadcast the new notification
          _notificationStreamController.add(notification);
        } catch (e) {
          print('Error handling foreground message: $e');
        }
      });

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // App opened from background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print(
          '📦 Notification opened: ${message.notification?.title ?? message.data['title']}',
        );
        final taskId = message.data['task_id'];
        if (taskId != null) {
          navigatorKey.currentState?.pushNamed(
            '/task_details',
            arguments: taskId,
          );
        }
      });

      // App opened from terminated state
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        print(
          'Initial message: ${initialMessage.notification?.title ?? initialMessage.data['title']}',
        );
        final taskId = initialMessage.data['task_id'];
        if (taskId != null) {
          navigatorKey.currentState?.pushNamed(
            '/task_details',
            arguments: taskId,
          );
        }
      }

      print('FirebaseService initialization completed');
    } catch (e) {
      print('Error initializing FirebaseService: $e');
    }
  }

  static Future<void> requestPermission() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      print('Notification permission: ${settings.authorizationStatus}');
    } catch (e) {
      print('Error requesting permission: $e');
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings();
      const InitializationSettings initializationSettings =
          InitializationSettings(android: androidSettings, iOS: iosSettings);
      await _localNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (response) {
          print('Notification tapped, payload: ${response.payload}');
        },
      );
      print('Local notifications initialized');
    } catch (e) {
      print('Error initializing local notifications: $e');
    }
  }

  static Future<void> _sendTokenToBackend(String token, String userId) async {
    try {
      // Assume ApiService.sendToken exists
      bool success = await ApiService.sendToken(userId, token);
      print('Token sent to backend: $success');
    } catch (e) {
      print('Error sending token to backend: $e');
    }
  }

  // static Future<void> firebaseMessagingBackgroundHandler(
  //   RemoteMessage message,
  // ) async {
  //   try {
  //     await Firebase.initializeApp();
  //     print(
  //       'Background message: ${message.notification?.title ?? message.data['title']}',
  //     );
  //     final notification = AppNotification(
  //       id: null,
  //       title:
  //           message.notification?.title ?? message.data['title'] ?? 'No Title',
  //       body: message.notification?.body ?? message.data['body'] ?? 'No Body',
  //       taskId: message.data['task_id'] ?? '',
  //       timestamp: DateTime.now(),
  //       isRead: false,
  //     );
  //     // Store in SharedPreferences
  //     final prefs = await SharedPreferences.getInstance();
  //     List<String> storedNotifications =
  //         prefs.getStringList('notifications') ?? [];
  //     storedNotifications.add(jsonEncode(notification.toJson()));
  //     await prefs.setStringList('notifications', storedNotifications);
  //     print('Stored background notification: ${notification.toJson()}');
  //     await showNotification(message);
  //   } catch (e) {
  //     print('Error handling background message: $e');
  //   }
  // }

  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    try {
      await Firebase.initializeApp();
      print('Background message: ${message.notification?.title ?? message.data['title']}');
      final notification = AppNotification(
        id: null,
        title: message.notification?.title ?? message.data['title'] ?? 'No Title',
        body: message.notification?.body ?? message.data['body'] ?? 'No Body',
        taskId: message.data['task_id'] ?? '',
        timestamp: DateTime.now(),
        isRead: false,
      );
      // Deduplicate notifications in background handler
      final prefs = await SharedPreferences.getInstance();
      List<String> storedNotifications = prefs.getStringList('notifications') ?? [];
      final existingIndex = storedNotifications.indexWhere((json) {
        try {
          final stored = AppNotification.fromJson(jsonDecode(json));
          return stored.taskId == notification.taskId;
        } catch (e) {
          return false;
        }
      });
      if (existingIndex != -1) {
        storedNotifications[existingIndex] = jsonEncode(notification.toJson());
        print('Updated existing background notification with taskId: ${notification.taskId}');
      } else {
        storedNotifications.add(jsonEncode(notification.toJson()));
        print('Added new background notification with taskId: ${notification.taskId}');
      }
      await prefs.setStringList('notifications', storedNotifications);
      print('Stored background notification: ${notification.toJson()}');
      await showNotification(message);
      // Note: Cannot broadcast in background, screens will reload on resume
    } catch (e) {
      print('Error handling background message: $e');
    }
  }

  static Future<void> showNotification(RemoteMessage message) async {
    try {
      print('Processing notification: ${message.messageId}');
      final String channelId =
          message.notification?.android?.channelId ?? 'default_channel';

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
            channelDescription:
                'This channel is used for important notifications.',
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

      // Use notification data for consistency
      final title =
          message.notification?.title ?? message.data['title'] ?? 'No Title';
      final body =
          message.notification?.body ?? message.data['body'] ?? 'No Body';
      final taskId = message.data['task_id'] ?? '';

      await _localNotificationsPlugin.show(
        0,
        title,
        body,
        notificationDetails,
        payload: taskId,
      );
      print('Notification shown: $title');
    } catch (e) {
      print('Error in showNotification: $e');
    }
  }
  // Added method to close the stream controller
  static void dispose() {
    _notificationStreamController.close();
  }


}

// Assume ApiService exists
// class ApiService {
//   static Future<bool> sendToken(String userId, String token) async {
//     // Placeholder implementation
//     print('Sending token for user: $userId, token: $token');
//     return true;
//   }
// }
