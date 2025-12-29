// import 'dart:io';
// // import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:intl/intl.dart';
// import 'package:path/path.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest.dart' as tz;
// // import 'package:timezone/timezone.dart' as tz;

// /// =================================================================================
// /// APP CONFIGURATION
// /// =================================================================================

// class AppConfig {
//   static const String appName = 'Reminder App';
//   static const String dbName = 'reminder_app.db';
//   static const int dbVersion = 1;

//   // Shared Preference Keys
//   static const String keyFirstLaunch = 'is_first_launch';
//   static const String keyLastOpened = 'last_opened';
// }

// /// =================================================================================
// /// PLATFORM CHANNEL (Future Native Integrations)
// /// =================================================================================

// class PlatformBridge {
//   static const MethodChannel channel = MethodChannel('reminder_app/platform');
// }

// /// =================================================================================
// /// TOAST & UI HELPERS
// /// =================================================================================

// class UIHelper {
//   static void showToast(String message) {
//     Fluttertoast.showToast(msg: message, toastLength: Toast.LENGTH_SHORT);
//   }

//   static void hideKeyboard(BuildContext context) {
//     FocusScope.of(context).unfocus();
//   }
// }

// /// =================================================================================
// /// SCREEN & RESPONSIVE UTILITIES
// /// =================================================================================

// class ScreenUtil {
//   static const double _referenceWidth = 375;

//   static double _scale(BuildContext context) {
//     return MediaQuery.of(context).size.width / _referenceWidth;
//   }

//   static double font(BuildContext context, double size) {
//     final scaled = size * _scale(context);
//     return scaled.clamp(size, size * 1.3);
//   }

//   static double icon(BuildContext context, double size) {
//     final scaled = size * _scale(context);
//     return scaled.clamp(size, size * 1.25);
//   }

//   static double padding(BuildContext context, double size) {
//     final scaled = size * _scale(context);
//     return scaled.clamp(size, size * 1.2);
//   }
// }

// /// =================================================================================
// /// COLOR PALETTE
// /// =================================================================================

// class AppColors {
//   static const Color primary = Color(0xFF663F1E);
//   static const Color secondary = Color(0xFFF2B039);
//   static const Color background = Colors.white;
//   static const Color muted = Color(0xFF9E9E9E);
//   static const Color danger = Colors.redAccent;
// }

// /// =================================================================================
// /// SHARED PREFERENCES HELPER
// /// =================================================================================

// class PreferenceHelper {
//   static Future<void> setString(String key, String value) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(key, value);
//   }

//   static Future<String> getString(String key, {String def = ''}) async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString(key) ?? def;
//   }

//   static Future<void> setBool(String key, bool value) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(key, value);
//   }

//   static Future<bool> getBool(String key, {bool def = false}) async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getBool(key) ?? def;
//   }

//   static Future<void> clearAll() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.clear();
//   }
// }

// /// =================================================================================
// /// LOCAL DATABASE (REMINDERS)
// /// =================================================================================

// class LocalDatabase {
//   static Future<Database> open() async {
//     final dbPath = join(await getDatabasesPath(), AppConfig.dbName);

//     return openDatabase(
//       dbPath,
//       version: AppConfig.dbVersion,
//       onCreate: (db, version) async {
//         await db.execute('''
//           CREATE TABLE reminders (
//             id INTEGER PRIMARY KEY AUTOINCREMENT,
//             title TEXT NOT NULL,
//             description TEXT,
//             scheduled_at TEXT NOT NULL
//           )
//         ''');
//       },
//     );
//   }

//   static Future<void> insertReminder({
//     required String title,
//     String? description,
//     required DateTime scheduledAt,
//   }) async {
//     final db = await open();
//     await db.insert('reminders', {
//       'title': title,
//       'description': description ?? '',
//       'scheduled_at': scheduledAt.toIso8601String(),
//     }, conflictAlgorithm: ConflictAlgorithm.replace);
//   }

//   static Future<List<Map<String, dynamic>>> getReminders() async {
//     final db = await open();
//     return db.query('reminders', orderBy: 'scheduled_at ASC');
//   }

//   static Future<void> deleteReminder(int id) async {
//     final db = await open();
//     await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
//   }

//   static Future<void> deleteDB() async {
//     final path = join(await getDatabasesPath(), AppConfig.dbName);
//     await deleteDatabase(path);
//   }
// }

// /// =================================================================================
// /// NOTIFICATION HANDLER
// /// =================================================================================

// class NotificationService {
//   static final FlutterLocalNotificationsPlugin _plugin =
//       FlutterLocalNotificationsPlugin();

//   static Future<void> requestNotificationPermission() async {
//     if (!Platform.isAndroid) return;

//     final androidPlugin = _plugin
//         .resolvePlatformSpecificImplementation<
//           AndroidFlutterLocalNotificationsPlugin
//         >();

//     await androidPlugin?.requestNotificationsPermission();
//   }

//   static Future<void> _createNotificationChannel() async {
//     const AndroidNotificationChannel channel = AndroidNotificationChannel(
//       'reminder_channel',
//       'Reminders',
//       description: 'Reminder notifications',
//       importance: Importance.max,
//       playSound: true,
//       enableVibration: true,
//       showBadge: true,
//     );

//     final androidPlugin = _plugin
//         .resolvePlatformSpecificImplementation<
//           AndroidFlutterLocalNotificationsPlugin
//         >();

//     await androidPlugin?.createNotificationChannel(channel);
//   }

//   static Future<void> initialize() async {
//     tz.initializeTimeZones();
//     tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

//     const androidSettings = AndroidInitializationSettings(
//       '@mipmap/ic_launcher',
//     );

//     const settings = InitializationSettings(android: androidSettings);
//     await _plugin.initialize(settings);

//     await _createNotificationChannel(); // 🔴 REQUIRED
//   }

//   static const MethodChannel _alarmChannel = MethodChannel(
//     'reminder_app/exact_alarm',
//   );

//   static Future<bool> canScheduleExactAlarms() async {
//     if (!Platform.isAndroid) return true;

//     try {
//       final bool allowed = await _alarmChannel.invokeMethod(
//         'canScheduleExactAlarms',
//       );
//       return allowed;
//     } catch (_) {
//       return false;
//     }
//   }

//   static Future<void> requestExactAlarmPermission() async {
//     if (!Platform.isAndroid) return;

//     try {
//       await _alarmChannel.invokeMethod('requestExactAlarmPermission');
//     } catch (_) {}
//   }

//   // static Future<void> schedule({
//   //   required int id,
//   //   required String title,
//   //   required String body,
//   //   required DateTime scheduledAt,
//   // }) async {
//   //   debugPrint('🟡 schedule() called');

//   //   final canSchedule = await canScheduleExactAlarms();
//   //   debugPrint('🟡 canScheduleExactAlarms = $canSchedule');

//   //   if (!canSchedule) {
//   //     UIHelper.showToast(
//   //       'Enable Alarms & Reminders, restart app, then try again',
//   //     );
//   //     await requestExactAlarmPermission();
//   //     return;
//   //   }

//   //   debugPrint('🟡 Scheduling for: $scheduledAt');

//   //   const androidDetails = AndroidNotificationDetails(
//   //     'reminder_channel',
//   //     'Reminders',
//   //     channelDescription: 'Reminder notifications',
//   //     importance: Importance.max,
//   //     priority: Priority.high,
//   //   );

//   //   await _plugin.zonedSchedule(
//   //     id,
//   //     title,
//   //     body,
//   //     tz.TZDateTime.from(scheduledAt, tz.local),
//   //     const NotificationDetails(android: androidDetails),
//   //     androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//   //   );

//   //   debugPrint('🟢 zonedSchedule() COMPLETED');
//   // }

//   static Future<void> schedule({
//     required int id,
//     required String title,
//     required String body,
//     required DateTime scheduledAt,
//   }) async {
//     debugPrint('🔔 Scheduling notification for $scheduledAt');

//     // SAFETY: do not schedule past time
//     if (scheduledAt.isBefore(DateTime.now())) {
//       UIHelper.showToast('Selected time already passed');
//       return;
//     }

//     const androidDetails = AndroidNotificationDetails(
//       'reminder_channel',
//       'Reminders',
//       channelDescription: 'Reminder notifications',
//       importance: Importance.max,
//       priority: Priority.high,
//     );

//     // 🔴 IMPORTANT: USE schedule(), NOT zonedSchedule(), NOT exact alarms
//     await _plugin.schedule(
//       id,
//       title,
//       body,
//       scheduledAt,
//       const NotificationDetails(android: androidDetails),
//       androidAllowWhileIdle: true,
//     );

//     debugPrint('✅ Notification scheduled successfully');
//   }

//   static Future<void> cancel(int id) async {
//     await _plugin.cancel(id);
//   }
// }

// extension on FlutterLocalNotificationsPlugin {
//   Future<void> schedule(
//     int id,
//     String title,
//     String body,
//     DateTime scheduledAt,
//     NotificationDetails notificationDetails, {
//     required bool androidAllowWhileIdle,
//   }) async {}
// }

// /// =================================================================================
// /// DATE & TIME FORMATTERS
// /// =================================================================================

// class DateUtil {
//   static String format(DateTime dateTime) {
//     return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
//   }
// }

// /// =================================================================================
// /// SAFE EXECUTOR (ERROR GUARD)
// /// =================================================================================

// class SafeExecutor {
//   static Future<void> run(
//     Future<void> Function() task, {
//     String? errorMessage,
//   }) async {
//     try {
//       await task();
//     } catch (e) {
//       debugPrint('ERROR: $e');
//       if (errorMessage != null) {
//         UIHelper.showToast(errorMessage);
//       }
//     }
//   }
// }




import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Global utility functions used throughout the app
/// Provides formatting, validation, and helper methods
class CustomGlobal {
  // ============ Date & Time Formatting ============

  /// Format DateTime to readable string
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime);
  }

  /// Format DateTime to date only
  static String formatDate(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy').format(dateTime);
  }

  /// Format DateTime to time only
  static String formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  /// Get relative time (e.g., "2 hours from now")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.isNegative) {
      return 'Overdue';
    }

    if (difference.inMinutes < 1) {
      return 'In a moment';
    } else if (difference.inMinutes < 60) {
      return 'In ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else if (difference.inHours < 24) {
      return 'In ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inDays < 7) {
      return 'In ${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
    } else {
      return 'In ${(difference.inDays / 7).ceil()} week${(difference.inDays / 7).ceil() > 1 ? 's' : ''}';
    }
  }

  // ============ Validation ============

  /// Validate if string is empty
  static bool isEmpty(String? value) {
    return value == null || value.trim().isEmpty;
  }

  /// Validate if DateTime is in future
  static bool isFutureDateTime(DateTime dateTime) {
    return dateTime.isAfter(DateTime.now());
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return regex.hasMatch(email);
  }

  /// Validate if string has minimum length
  static bool hasMinLength(String? value, int minLength) {
    return value != null && value.length >= minLength;
  }

  // ============ Color & UI Helpers ============

  /// Get category color
  static Color getCategoryColor(String category) {
    final colors = {
      'Work': const Color(0xFF6366F1),
      'Personal': const Color(0xFFF59E0B),
      'Health': const Color(0xFF10B981),
      'Shopping': const Color(0xFFEF4444),
      'Other': const Color(0xFF8B5CF6),
    };
    return colors[category] ?? const Color(0xFF6366F1);
  }

  /// Get category icon
  static IconData getCategoryIcon(String category) {
    final icons = {
      'Work': Icons.work_outline,
      'Personal': Icons.person_outline,
      'Health': Icons.favorite_outline,
      'Shopping': Icons.shopping_cart_outlined,
      'Other': Icons.note_outlined,
    };
    return icons[category] ?? Icons.note_outlined;
  }

  // ============ String Helpers ============

  /// Capitalize first letter
  static String capitalize(String text) {
    if (isEmpty(text)) return '';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Truncate string to length
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // ============ Number Formatting ============

  /// Format number with commas
  static String formatNumber(num number) {
    return NumberFormat('#,##0').format(number);
  }

  // ============ Error Handling ============

  /// Show snackbar
  static void showSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  /// Show error dialog
  static void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show confirmation dialog
  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ============ Device & Screen Helpers ============

  /// Get screen width
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Check if device is in portrait mode
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 600) {
      return const EdgeInsets.all(16);
    } else if (width < 1000) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(32);
    }
  }

  // ============ Debugging ============

  /// Print debug message with tag
  static void printDebug(String tag, String message) {
    print('[$tag] $message');
  }
}
