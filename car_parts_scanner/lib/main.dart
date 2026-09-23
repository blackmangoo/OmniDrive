import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth/auth_gate.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_typography.dart';
import 'core/theme/app_spacing.dart';
import 'package:car_parts_scanner/core/theme/app_colors.dart';
import 'core/config/app_config.dart';

List<CameraDescription> cameras = [];

String _supabaseUrl     = AppConfig.supabaseUrl;
String _supabaseAnonKey = AppConfig.supabaseAnonKey;

// ── Local notifications plugin ───────────────────────────────────────────────
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

AndroidNotificationChannel fcmChannel = AndroidNotificationChannel(
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

  // Inter ships in assets/google_fonts/. Resolving it over the network would
  // make the typeface depend on connectivity at launch and cause a visible
  // fallback-and-swap on first run.
  GoogleFonts.config.allowRuntimeFetching = false;

  // Show a splash screen IMMEDIATELY so the user doesn't see a black screen
  runApp(OmniDriveSplashScreen());

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
    await Firebase.initializeApp().timeout(Duration(seconds: 10));
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Create the high-importance notification channel for Android
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(fcmChannel);

    // Initialize local notifications
    final android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final ios = DarwinInitializationSettings();
    await flutterLocalNotificationsPlugin
        .initialize(settings: InitializationSettings(android: android, iOS: ios));

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
    ).timeout(Duration(seconds: 10));
  } catch (e) {
    debugPrint('Supabase init error or timeout: $e');
  }

  // 3. Initialize device cameras with Timeout
  try {
    cameras = await availableCameras().timeout(Duration(seconds: 5));
  } catch (e) {
    debugPrint('General camera init error or timeout: $e');
  }

  // Launch the real app now that dependencies are ready
  runApp(OmniDriveApp());
}

class OmniDriveSplashScreen extends StatelessWidget {
  const OmniDriveSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The real launcher icon, so the splash matches the mark the
              // user tapped. A generic Material car glyph in a gradient
              // circle is a placeholder, not a logo.
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.rXl),
                child: Image.asset(
                  'assets/icon/app_icon.png',
                  width: 88,
                  height: 88,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, _, _) => Container(
                    width: 88,
                    height: 88,
                    color: AppColors.surface,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('OmniDrive', style: AppTypography.h1),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textMuted,
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
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: AuthGate(),
    );
  }
}
