import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'; // Added for WidgetsBindingObserver
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_backend/models/app_notification.dart';
import 'package:firebase_backend/models/task.dart';
import 'package:firebase_backend/screens/login_screen.dart';
import 'package:firebase_backend/services/api_service.dart';
import 'package:firebase_backend/services/storage_service.dart';

import '../models/notification.dart';
import '../services/firebase_service.dart';
import 'notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Changed SingleTickerProviderStateMixin to TickerProviderStateMixin to support multiple Tickers (AnimationController and TabController)
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;
  StreamSubscription<AppNotification>? _notificationSubscription;
  Timer? _debounceTimer; // Added for debouncing _loadNotifications

  static const List<Widget> _tabs = <Widget>[
    Center(child: Text('Tasks Tab')),
    Center(child: Text('Notifications Tab')),
  ];

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
    print('HomeScreen initState called');
    // Initialize TabController
    _tabController = TabController(length: 2, vsync: this);
    print('TabController initialized - Ticker 1 created');
    // Initialize animation for bell icon
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    print('AnimationController initialized - Ticker 2 created');
    _animation = Tween<double>(begin: 0, end: 0.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    // Load notifications and set up listeners
    _listenForNotifications();
    _loadUserIdAndData();
    _loadNotifications();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('App resumed, reloading notifications in HomeScreen');
      _loadNotifications();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _tabController?.index = index; // Sync TabBar with BottomNavigationBar
    });
  }

  // void _listenForNotifications() {
  //   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //     print('Foreground message received in HomeScreen: ${message.messageId}');
  //     _loadNotifications();
  //     // Trigger bell animation
  //     _animationController.forward().then(
  //           (_) => _animationController.reverse(),
  //     );
  //   });
  // }

  void _listenForNotifications() {
    // Replaced FirebaseMessaging.onMessage with stream subscription
    _notificationSubscription = FirebaseService.onNotification.listen((notification) {
      print('New notification received in HomeScreen: ${notification.title}');
      _loadNotifications();
      _animationController.forward().then((_) => _animationController.reverse());
    });
  }

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
            print('- ${notification.title}: ${notification.body} (Read: ${notification.isRead})');
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
              DateTime.parse(mergedNotifications[n['task_id']]!['timestamp']),
            )) {
          mergedNotifications[n['task_id']] = n;
        }
      }

      setState(() {
        _tasks = tasks;
        _notifications = mergedNotifications.values.toList()
          ..sort(
                (a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])),
          );
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
    FirebaseService.dispose(); // Added to close notification stream
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<void> _loadNotifications() async {
    // Added debouncing to prevent overlapping calls
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), () async {
      try {
        print('Loading notifications from SharedPreferences in HomeScreen');
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
          final unreadCount = notifications.where((n) => !n.isRead).length;
          print('Parsed notifications count: ${notifications.length}');
          print('Unread notifications count: $unreadCount');
        });
      } catch (e) {
        print('Error loading notifications: $e');
      }
    });
  }

  @override
  void dispose() {
    print('Disposing HomeScreen');
    _debounceTimer?.cancel(); // Added to cancel debounce timer
    _notificationSubscription?.cancel(); // Added to cancel stream subscription
    _animationController.dispose();
    print('AnimationController disposed');
    _tabController?.dispose();
    print('TabController disposed');
    WidgetsBinding.instance.removeObserver(this);
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((n) => !n.isRead).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Management'),
        actions: [
          Stack(
            children: [
              RotationTransition(
                turns: _animation,
                child: IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () async {
                    print('Bell icon tapped');
                    await _checkSharedPreferences();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotificationScreen(
                          onNotificationRead: _loadNotifications,
                        ),
                      ),
                    );
                  },
                  tooltip: 'Notifications',
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
        // bottom: TabBar(
        //   controller: _tabController,
        //   tabs: const [Tab(text: 'Tasks'), Tab(text: 'Notifications')],
        //   onTap: (index) {
        //     setState(() {
        //       _selectedIndex = index; // Sync BottomNavigationBar with TabBar
        //     });
        //   },
        // ),
      ),
      body: _tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tasks'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}