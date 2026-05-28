import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'auth/auth_gate.dart';

List<CameraDescription> cameras = [];

const String _supabaseUrl     = 'https://cqeubytgsrxdkfejxvan.supabase.co';
const String _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNxZXVieXRnc3J4ZGtmZWp4dmFuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMwNzMwMTMsImV4cCI6MjA4ODY0OTAxM30.iTL7KvhVxLEJFZFO50OvkgNWAyKfhM8Q51wkbZZTuPk';

// ── Local notifications plugin ───────────────────────────────────────────────
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel fcmChannel = AndroidNotificationChannel(
  'omnidrive_channel',
  'OmniDrive Notifications',
  description: 'OmniDrive Marketplace Notifications',
  importance: Importance.high,
);

// Background FCM handler (top-level, required by Firebase)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background: ${message.notification?.title}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Show a splash screen IMMEDIATELY so the user doesn't see a black screen
  runApp(const OmniDriveSplashScreen());

  // 0. Request basic permissions that the user expects on startup
  try {
    await [
      Permission.notification,
    ].request();
  } catch (e) {
    debugPrint('Permission request error: $e');
  }

  // 1. Initialize Firebase with Timeout
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 10));
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Create the high-importance notification channel for Android
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(fcmChannel);

    // Initialize local notifications
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await flutterLocalNotificationsPlugin
        .initialize(settings: const InitializationSettings(android: android, iOS: ios));

    // Handle FCM messages when app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        flutterLocalNotificationsPlugin.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              fcmChannel.id,
              fcmChannel.name,
              channelDescription: fcmChannel.description,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });
  } catch (e) {
    debugPrint('Firebase init error or timeout: $e');
  }

  // 2. Initialize Supabase with Timeout
  try {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    ).timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('Supabase init error or timeout: $e');
  }

  // 3. Initialize device cameras with Timeout
  try {
    cameras = await availableCameras().timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('General camera init error or timeout: $e');
  }

  // Launch the real app now that dependencies are ready
  runApp(const OmniDriveApp());
}

class OmniDriveSplashScreen extends StatelessWidget {
  const OmniDriveSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF0A0A0F),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF4FC3F7)),
              SizedBox(height: 24),
              Text(
                'Starting Engine...',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class OmniDriveApp extends StatelessWidget {
  const OmniDriveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'OmniDrive AI',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF0E0E18),
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}
