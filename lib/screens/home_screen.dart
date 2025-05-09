import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_backend/models/app_notification.dart';
import 'package:firebase_backend/models/task.dart';
import 'package:firebase_backend/screens/login_screen.dart';
import 'package:firebase_backend/services/api_service.dart';
import 'package:firebase_backend/services/storage_service.dart';

import '../models/notification.dart';
import 'notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _taskController = TextEditingController();
  List<Task> _tasks = [];
  List<Map<String, dynamic>> _notifications = [];
  String? _userId;
  bool _isLoading = false;
  TabController? _tabController;
  List<String> _users = [];
  String? _selectedUserId;
  List<AppNotification> notifications = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserIdAndData();
    _loadNotifications();
  }

  // Future<void> _checkSharedPreferences() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final storedNotifications = prefs.getStringList('notifications') ?? [];
  //   print('SharedPreferences notifications: $storedNotifications');
  //   if (storedNotifications.isNotEmpty) {
  //     print('Parsed notifications:');
  //     for (var json in storedNotifications) {
  //       final notification = AppNotification.fromJson(jsonDecode(json));
  //       print('- ${notification.title}: ${notification.body}');
  //     }
  //   }
  // }

  Future<void> _checkSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedNotifications = prefs.getStringList('notifications') ?? [];
      print('SharedPreferences notifications: $storedNotifications');
      if (storedNotifications.isNotEmpty) {
        print('Parsed notifications:');
        for (var json in storedNotifications) {
          try {
            final notification = AppNotification.fromJson(jsonDecode(json));
            print('- ${notification.title}: ${notification.body}');
          } catch (e) {
            print('Error parsing notification JSON: $e');
          }
        }
      } else {
        print('No notifications in SharedPreferences');
      }
    } catch (e) {
      print('Error checking SharedPreferences: $e');
    }
  }


  Future<void> _loadUserIdAndData() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');

    if (_userId != null) {
      // Fetch tasks from backend
      final tasks = await ApiService.getTasks(_userId!);

      // Fetch notifications from local storage and backend
      final localNotifications = await StorageService.getNotifications();
      final serverNotifications = await ApiService.getNotifications(_userId!);
      final users = await ApiService.getUsers();


      // Merge notifications (remove duplicates by task_id, prioritize newer timestamp)
      final mergedNotifications = <String, Map<String, dynamic>>{};
      for (var n in localNotifications) {
        final notificationMap = n.toJson();
        mergedNotifications[notificationMap['task_id']] = notificationMap;
      }
      for (var n in serverNotifications) {
        if (!mergedNotifications.containsKey(n['task_id']) ||
            DateTime.parse(n['timestamp']).isAfter(
                DateTime.parse(mergedNotifications[n['task_id']]!['timestamp']))) {
          mergedNotifications[n['task_id']] = n;
        }
      }

      // setState(() {
      //   _tasks = tasks;
      //   _notifications = mergedNotifications.values.toList()
      //     ..sort((a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
      //   _isLoading = false;
      // });
      setState(() {
        _tasks = tasks;
        _notifications = mergedNotifications.values.toList()
          ..sort((a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
        _users = users;
        _selectedUserId = _users.isNotEmpty ? _users[0] : null;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Future<void> _addTask() async {
  //   if (_taskController.text.isNotEmpty && _userId != null) {
  //     final task = Task(
  //       taskId: DateTime.now().toString(),
  //       userId: _userId!,
  //       title: _taskController.text,
  //       status: 'pending',
  //       createdAt: DateTime.now(),
  //     );
  //     final success = await ApiService.createTask(_userId!, task);
  //     if (success) {
  //       _taskController.clear();
  //       _loadUserIdAndData(); // Refresh tasks and notifications
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Task added successfully')),
  //       );
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Failed to add task')),
  //       );
  //     }
  //   }
  // }

  Future<void> _addTask() async {
    if (_taskController.text.isNotEmpty && _selectedUserId != null) {
      final task = Task(
        taskId: DateTime.now().toString(),
        userId: _selectedUserId!,
        title: _taskController.text,
        status: 'pending',
        createdAt: DateTime.now(),
      );
      final success = await ApiService.createTask(_selectedUserId!, task);
      if (success) {
        _taskController.clear();
        _loadUserIdAndData(); // Refresh tasks and notifications
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task added successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add task')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task and select a user')),
      );
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  // Future<void> _loadNotifications() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final storedNotifications = prefs.getStringList('notifications') ?? [];
  //   setState(() {
  //     notifications = storedNotifications
  //         .map((json) => AppNotification.fromJson(jsonDecode(json)))
  //         .toList();
  //   });
  // }

  Future<void> _loadNotifications() async {
    try {
      print('Loading notifications from SharedPreferences');
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

  @override
  void dispose() {
    _taskController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Management'),

        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () async{
              print('Bell icon tapped');
              // TODO: Navigate to NotificationScreen
              // await _loadNotifications();
              await _checkSharedPreferences();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationScreen()),
              );
            },
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),


        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tasks'),
            Tab(text: 'Notifications'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          // Tasks Tab
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _taskController,
                  decoration: const InputDecoration(
                    labelText: 'New Task',
                    border: OutlineInputBorder(),
                  ),
                ),


                const SizedBox(height: 16),
                DropdownButton<String>(
                  value: _selectedUserId,
                  hint: const Text('Select User'),
                  isExpanded: true,
                  items: _users.map((userId) {
                    return DropdownMenuItem<String>(
                      value: userId,
                      child: Text(userId),
                    );
                  }).toList(),
                  onChanged: (newUserId) {
                    setState(() {
                      _selectedUserId = newUserId;
                    });
                  },
                ),


                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _addTask,
                  child: const Text('Add Task'),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: _tasks.isEmpty
                      ? const Center(child: Text('No tasks'))
                      : ListView.builder(
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return ListTile(
                        title: Text(task.title),
                        subtitle: Text('Status: ${task.status}'),
                        trailing: Text(
                          task.createdAt.toIso8601String().substring(0, 16),
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/task_details',
                            arguments: task.taskId,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Notifications Tab
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _notifications.isEmpty
                ? const Center(child: Text('No notifications'))
                : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return ListTile(
                  title: Text(notification['title']),
                  subtitle: Text(notification['body']),
                  trailing: Text(
                    notification['timestamp'].substring(0, 16),
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/task_details',
                      arguments: notification['task_id'],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}