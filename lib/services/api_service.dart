import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_backend/models/task.dart';

class ApiService {
  static const String baseUrl = 'http://10.20.0.248:5000/api';

  static Future<Map<String, dynamic>?> signup(String userId, String email, String password, String fcm) async {
    final response = await http.post(
      Uri.parse('$baseUrl/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'email': email,
        'password': password,
        'fcm_token' : fcm
      }),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    return jsonDecode(response.body); // Return error details
  }

  static Future<Map<String, dynamic>?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  static Future<bool> sendToken(String userId, String fcmToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/store-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'fcm_token': fcmToken}),
    );
    return response.statusCode == 200;
  }

  static Future<bool> createTask(String userId, Task task) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add-task'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'title': task.title,
        'task_id': task.taskId,
      }),
    );
    return response.statusCode == 200;
  }

  static Future<Task?> getTask(String taskId) async {
    final response = await http.get(Uri.parse('$baseUrl/task/$taskId'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        return Task.fromJson(data['task']);
      }
    }
    return null;
  }

  static Future<List<Task>> getTasks(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/tasks/$userId'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        return List<Map<String, dynamic>>.from(data['tasks'])
            .map((task) => Task.fromJson(task))
            .toList();
      }
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/notifications/$userId'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['notifications']);
    }
    return [];
  }

  static Future<List<String>> getUsers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<String>.from(data['users']);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }


}