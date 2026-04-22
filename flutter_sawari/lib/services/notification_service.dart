import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

/// Handles notifications by polling the backend and showing local notifications.
/// No Firebase Cloud Messaging required.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService();

  Timer? _pollTimer;
  int _lastKnownUnread = 0;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Initialize local notifications for showing alerts
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);

    // Create notification channel for Android
    const channel = AndroidNotificationChannel(
      'sawari_channel',
      'Sawari Notifications',
      description: 'Notifications from Sawari app',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Start polling the backend for new notifications every [interval] seconds
  void startPolling({int intervalSeconds = 30}) {
    stopPolling();
    // Do an immediate check
    _checkForNewNotifications();
    // Then poll at interval
    _pollTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) => _checkForNewNotifications(),
    );
    debugPrint('Notification polling started (every ${intervalSeconds}s)');
  }

  /// Stop polling
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Check backend for new unread notifications and show local notification
  Future<void> _checkForNewNotifications() async {
    try {
      final response = await _apiService.getNotifications(page: 1, limit: 5);
      if (!response.success || response.data == null) return;

      final data = response.data!['data'];
      final int currentUnread = data['unread'] ?? 0;
      final notifications = data['notifications'] as List? ?? [];

      // If unread count increased, show the newest unread notification
      if (currentUnread > _lastKnownUnread && _lastKnownUnread >= 0) {
        // Find the most recent unread notification
        final newest = notifications.firstWhere(
          (n) => n['isread'] != true,
          orElse: () => null,
        );

        if (newest != null) {
          await _showLocalNotification(
            title: newest['title'] ?? 'Sawari',
            body: newest['message'] ?? 'You have a new notification',
            id: newest['notificationid'] ?? DateTime.now().millisecondsSinceEpoch,
          );
        }
      }

      _lastKnownUnread = currentUnread;
    } catch (e) {
      debugPrint('Notification poll error: $e');
    }
  }

  /// Show a local system notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required int id,
  }) async {
    await _localNotifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'sawari_channel',
          'Sawari Notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  /// Reset unread counter (call after user views notifications)
  void resetUnreadCount() {
    _lastKnownUnread = 0;
  }
}
