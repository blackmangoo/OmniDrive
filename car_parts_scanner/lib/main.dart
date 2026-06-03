import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'auth/auth_gate.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_typography.dart';
import 'core/theme/app_gradients.dart';
import 'core/theme/app_shadows.dart';

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.primary,
                  boxShadow: AppShadows.cyanGlow,
                ),
                child: const Icon(
                  Icons.directions_car_rounded,
                  color: Colors.black,
                  size: 48,
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(
                    begin: const Offset(0.92, 0.92),
                    end: const Offset(1.08, 1.08),
                    duration: 1200.ms,
                    curve: Curves.easeInOutCubic,
                  ),
              const SizedBox(height: 32),
              Text(
                'Starting Engine...',
                style: AppTypography.title.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.5,
                ),
              )
                  .animate()
                  .fadeIn(duration: 800.ms, curve: Curves.easeOutCubic)
                  .shimmer(
                    duration: 2000.ms,
                    color: AppColors.cyan.withValues(alpha: 0.25),
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
      theme: AppTheme.darkTheme,
      home: const AuthGate(),
    );
  }
}
