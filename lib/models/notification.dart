class AppNotification {
  final int? id; // Nullable to support local notifications without ID
  final String title;
  final String body;
  final String taskId;
  final DateTime timestamp;

  AppNotification({
    this.id,
    required this.title,
    required this.body,
    required this.taskId,
    required this.timestamp,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      taskId: json['task_id'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'task_id': taskId,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}