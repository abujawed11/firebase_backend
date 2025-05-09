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

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_backend/models/notification.dart';
import 'dart:convert';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<AppNotification> notifications = [];

  @override
  void initState() {
    super.initState();
    print('NotificationScreen initState called');
    _loadNotifications();
    _listenForNotifications();
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

  void _listenForNotifications() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received in NotificationScreen: ${message.messageId}');
      _loadNotifications(); // Reload notifications when a new message arrives
    });
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
      ),
      body: notifications.isEmpty
          ? const Center(child: Text('No notifications'))
          : ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return ListTile(
            title: Text(notification.title),
            subtitle: Text(notification.body),
            trailing: Text(
              _formatTimestamp(notification.timestamp),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            onTap: () {
              print('Tapped notification: ${notification.taskId}');
              // Navigate to TaskDetailsScreen if needed
            },
          );
        },
      ),
    );
  }
}