// import 'package:flutter/material.dart';
// import 'package:firebase_backend/models/notification.dart';
//
// class NotificationScreen extends StatelessWidget {
//   final List<AppNotification> notifications;
//
//   const NotificationScreen({super.key, required this.notifications});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Notifications'),
//       ),
//       body: notifications.isEmpty
//           ? const Center(child: Text('No notifications'))
//           : ListView.builder(
//         itemCount: notifications.length,
//         itemBuilder: (context, index) {
//           final notification = notifications[index];
//           return ListTile(
//             title: Text(notification.title),
//             subtitle: Text(notification.body),
//             trailing: Text(
//               _formatTimestamp(notification.timestamp),
//               style: const TextStyle(fontSize: 12, color: Colors.grey),
//             ),
//             onTap: () {
//               // TODO: Navigate to TaskDetailsScreen with notification.taskId
//               print('Tapped notification: ${notification.taskId}');
//             },
//           );
//         },
//       ),
//     );
//   }
//
//   String _formatTimestamp(DateTime timestamp) {
//     final now = DateTime.now();
//     final difference = now.difference(timestamp);
//     if (difference.inMinutes < 1) {
//       return 'Just now';
//     } else if (difference.inHours < 1) {
//       return '${difference.inMinutes} min ago';
//     } else if (difference.inDays < 1) {
//       return '${difference.inHours} hr ago';
//     } else {
//       return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
//     }
//   }
// }

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_backend/models/notification.dart';
import 'dart:convert';

import '../services/firebase_service.dart';

class NotificationScreen extends StatefulWidget {
  final VoidCallback? onNotificationRead;

  const NotificationScreen({super.key, this.onNotificationRead});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with WidgetsBindingObserver {
  List<AppNotification> notifications = [];

  StreamSubscription<AppNotification>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    print('NotificationScreen initState called');
    _loadNotifications();
    _listenForNotifications();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('App resumed, reloading notifications in NotificationScreen');
      _loadNotifications();
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel(); // Added to cancel stream subscription
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    try {
      print('Loading notifications from SharedPreferences in NotificationScreen');
      final prefs = await SharedPreferences.getInstance();
      final storedNotifications = prefs.getStringList('notifications') ?? [];
      print('Loaded notifications from SharedPreferences: $storedNotifications');
      setState(() {
        notifications = storedNotifications
            .map((json) {
          try {
            return AppNotification.fromJson(jsonDecode(json));
          } catch (e) {
            print('Error parsing notification JSON: $e');
            return null;
          }
        })
            .where((notification) => notification != null)
            .cast<AppNotification>()
            .toList();
        print('Parsed notifications count: ${notifications.length}');
      });
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  // void _listenForNotifications() {
  //   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //     print('Foreground message received in NotificationScreen: ${message.messageId}');
  //     _loadNotifications(); // Reload notifications when a new message arrives
  //   });
  // }

  void _listenForNotifications() {
    // Replaced FirebaseMessaging.onMessage with stream subscription
    _notificationSubscription = FirebaseService.onNotification.listen((notification) {
      print('New notification received in NotificationScreen: ${notification.title}');
      _loadNotifications();
    });
  }

  Future<void> _markAsRead(int index) async {
    try {
      final updatedNotification = notifications[index].copyWith(isRead: true);
      final prefs = await SharedPreferences.getInstance();
      final storedNotifications = prefs.getStringList('notifications') ?? [];
      storedNotifications[index] = jsonEncode(updatedNotification.toJson());
      await prefs.setStringList('notifications', storedNotifications);
      setState(() {
        notifications[index] = updatedNotification;
      });
      print('Marked notification as read: ${notifications[index].title}');
      widget.onNotificationRead?.call(); // Notify HomeScreen
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hr ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building NotificationScreen');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('notifications');
              setState(() {
                notifications = [];
              });
              print('Notifications cleared in NotificationScreen');
              widget.onNotificationRead?.call();
            },
            tooltip: 'Clear Notifications',
          ),
        ],
      ),
      body: notifications.isEmpty
          ? const Center(child: Text('No notifications'))
          : ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return ListTile(
            title: Text(
              notification.title,
              style: TextStyle(
                fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            subtitle: Text(notification.body),
            trailing: Text(
              _formatTimestamp(notification.timestamp),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            onTap: () async {
              if (!notification.isRead) {
                await _markAsRead(index);
              }
            },
          );
        },
      ),
    );
  }
}