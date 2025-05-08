class Task {
  final String taskId;
  final String userId;
  final String title;
  final String status;
  final DateTime createdAt;

  Task({
    required this.taskId,
    required this.userId,
    required this.title,
    required this.status,
    required this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      taskId: json['task_id'],
      userId: json['user_id'],
      title: json['title'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task_id': taskId,
      'user_id': userId,
      'title': title,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}