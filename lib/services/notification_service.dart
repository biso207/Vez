import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import 'api_keys.dart';
import 'user_session.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  NotificationService._internal();

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  static const AndroidNotificationChannel _androidChannel =
  AndroidNotificationChannel(
    'vez_events',
    'Vez events',
    description: 'Inviti e aggiornamenti degli eventi Vez',
    importance: Importance.high,
  );

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized || kIsWeb) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(settings: initializationSettings);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
    >()
        ?.createNotificationChannel(_androidChannel);

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    _messaging.onTokenRefresh.listen(_saveTokenForCurrentUser);

    _isInitialized = true;
  }

  Future<void> syncTokenForCurrentUser() async {
    if (kIsWeb || !UserSession().isLoggedIn) return;

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    if (kDebugMode) {
      debugPrint('FCM token: $token');
    }

    await _saveTokenForCurrentUser(token);
  }

  Future<void> _saveTokenForCurrentUser(String token) async {
    final String userId = UserSession().userID;
    if (userId.isEmpty) return;

    final url = Uri.parse(
      '${ApiKeys.baseUrl}/rest/v1/users?user_id=eq.$userId',
    );

    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiKeys.remoteDbKey}',
          'apikey': ApiKeys.remoteDbKey,
          'Prefer': 'return=minimal',
        },
        body: jsonEncode({'fcm_token': token}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          'FCM token save failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('FCM token save error: $e');
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
      ),
      payload: message.data.isEmpty ? null : jsonEncode(message.data),
    );
  }
}
