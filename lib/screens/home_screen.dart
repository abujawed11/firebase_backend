import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_backend/models/app_notification.dart';
import 'package:firebase_backend/models/task.dart';
import 'package:firebase_backend/screens/login_screen.dart';
import 'package:firebase_backend/services/api_service.dart';
import 'package:firebase_backend/services/storage_service.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserIdAndData();
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