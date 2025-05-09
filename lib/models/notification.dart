import 'package:flutter/foundation.dart';

class AppNotification {
  final String? id;
  final String title;
  final String body;
  final String taskId;
  final DateTime timestamp;
  final bool isRead;

  AppNotification({
    this.id,
    required this.title,
    required this.body,
    required this.taskId,
    required this.timestamp,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String?,
      title: json['title'] as String,
      body: json['body'] as String,
      taskId: json['task_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'task_id': taskId,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
    };
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? taskId,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      taskId: taskId ?? this.taskId,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}