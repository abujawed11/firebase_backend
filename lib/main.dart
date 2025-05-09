import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_backend/screens/home_screen.dart';
import 'package:firebase_backend/screens/login_screen.dart';
import 'package:firebase_backend/screens/signup_screen.dart';
import 'package:firebase_backend/screens/task_details_screen.dart';
import 'package:firebase_backend/services/firebase_service.dart';
import 'package:firebase_backend/services/storage_service.dart';
import 'firebase_options.dart';

// Define navigatorKey at the top level
final navigatorKey = GlobalKey<NavigatorState>();

// Background message handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Firebase.initializeApp();

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize services
  //await StorageService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Task Management App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FutureBuilder<String?>(
        future: _getUserId(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData && snapshot.data != null) {
            // User is logged in, initialize FirebaseService with user ID
            final firebaseService = FirebaseService();
            firebaseService.initialize(userId: snapshot.data!);
            return const HomeScreen();
          }
          // No user ID, show signup screen
          return const SignupScreen();
        },
      ),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/task_details': (context) => TaskDetailsScreen(
          taskId: ModalRoute.of(context)?.settings.arguments as String? ?? '',
        ),
      },
      debugShowCheckedModeBanner: false,
    );
  }

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }
}