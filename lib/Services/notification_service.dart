import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Singleton service for managing local notifications
/// Handles initialization, scheduling, and notification lifecycle
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Stream controller for notification events
  final _notificationStreamController = StreamController<String>.broadcast();

  Stream<String> get notificationStream =>
      _notificationStreamController.stream;

  /// Initialize notification service with platform-specific settings
  Future<void> initialize() async {
    try {
      // Initialize timezone
      tz_data.initializeTimeZones();

      // Android initialization settings
      const AndroidInitializationSettings androidInitializationSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS/macOS initialization settings
      final DarwinInitializationSettings darwinInitializationSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        // onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
      );

      // Combined initialization settings
      final InitializationSettings initializationSettings =
          InitializationSettings(
        android: androidInitializationSettings,
        iOS: darwinInitializationSettings,
        macOS: darwinInitializationSettings,
      );

      // Initialize the plugin
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
        onDidReceiveBackgroundNotificationResponse:
            _onDidReceiveBackgroundNotificationResponse,
      );

      // Request permissions for Android 13+
      await _requestNotificationPermissions();

      debugPrint('✅ NotificationService initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing NotificationService: $e');
      rethrow;
    }
  }

  /// Request notification permissions (Android 13+)
  Future<void> _requestNotificationPermissions() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final bool? granted =
            await androidImplementation.requestNotificationsPermission();
        debugPrint('Notification permission granted: $granted');
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }

  /// Create notification channel (Android)
  // Future<void> _createNotificationChannel() async {
  //   try {
  //     const AndroidNotificationChannel channel = AndroidNotificationChannel(
  //       'reminder_channel',
  //       'Reminder Notifications',
  //       description: 'Notifications for reminders',
  //       importance: Importance.high,
  //       enableVibration: true,
  //       playSound: true,
  //     );

  //     await _flutterLocalNotificationsPlugin
  //         .resolvePlatformSpecificImplementation<
  //             AndroidFlutterLocalNotificationsPlugin>()
  //         ?.createNotificationChannel(channel);
  //   } catch (e) {
  //     debugPrint('Error creating notification channel: $e');
  //   }
  // }

  /// Schedule a reminder notification
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    try {
      // Validate scheduled time is in the future
      if (scheduledTime.isBefore(DateTime.now())) {
        throw ArgumentError('Scheduled time must be in the future');
      }

      // Create notification details
      final AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'reminder_channel',
        'Reminder Notifications',
        channelDescription: 'Notifications for reminders',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList(const [0, 250, 250, 250]),
      );

      const DarwinNotificationDetails iosNotificationDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        badgeNumber: 1,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      // Convert to timezone-aware datetime
      final tz.TZDateTime tzDateTime = tz.TZDateTime.from(
        scheduledTime,
        tz.local,
      );

      // Schedule notification
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );

      debugPrint(
          '✅ Reminder scheduled: ID=$id, Time=${tzDateTime.toIso8601String()}');
    } catch (e) {
      debugPrint('❌ Error scheduling reminder: $e');
      rethrow;
    }
  }

  /// Cancel a scheduled notification
  Future<void> cancelReminder(int id) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
      debugPrint('✅ Reminder cancelled: ID=$id');
    } catch (e) {
      debugPrint('❌ Error cancelling reminder: $e');
      rethrow;
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllReminders() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('✅ All reminders cancelled');
    } catch (e) {
      debugPrint('❌ Error cancelling all reminders: $e');
      rethrow;
    }
  }

  /// Get list of pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
    } catch (e) {
      debugPrint('❌ Error getting pending notifications: $e');
      return [];
    }
  }

  // Notification response handlers
  static void _onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      debugPrint('Notification tapped: $payload');
      _instance._notificationStreamController.add(payload);
    }
  }

  static void _onDidReceiveBackgroundNotificationResponse(
      NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      debugPrint('Background notification tapped: $payload');
      _instance._notificationStreamController.add(payload);
    }
  }

  // Future<void> _onDidReceiveLocalNotification(
  //   int id,
  //   String? title,
  //   String? body,
  //   String? payload,
  // ) async {
  //   debugPrint('iOS foreground notification: $id, $title, $body');
  // }

  /// Clean up resources
  void dispose() {
    _notificationStreamController.close();
  }
}
