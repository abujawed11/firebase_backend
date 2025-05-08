import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_backend/models/app_notification.dart';

import '../models/notification.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> saveNotification(AppNotification notification) async {
    final notifications = await getNotifications();
    notifications.add(notification);
    final notificationJson = notifications.map((n) => n.toJson()).toList();
    await _prefs?.setString('notifications', jsonEncode(notificationJson));
  }

  static Future<List<AppNotification>> getNotifications() async {
    final notificationJson = _prefs?.getString('notifications');
    if (notificationJson != null) {
      final List<dynamic> decoded = jsonDecode(notificationJson);
      return decoded.map((json) => AppNotification.fromJson(json)).toList();
    }
    return [];
  }
}