// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:reminder_app/Services/db_service.dart' hide debugPrint;
import 'package:reminder_app/Services/notification_service.dart';
import 'package:reminder_app/models/Reminder.dart';
import 'package:uuid/uuid.dart';

/// Provider for managing reminders state using Provider pattern
/// Responsible for CRUD operations and notification lifecycle
class ReminderProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final NotificationService _notificationService = NotificationService.instance;

  List<Reminder> _reminders = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Reminder> get reminders => _reminders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ReminderProvider() {
    _initialize();
  }

  /// Initialize provider by loading reminders from database
  Future<void> _initialize() async {
    await loadReminders();
  }

  /// Load all reminders from database
  Future<void> loadReminders() async {
    try {
      _setLoading(true);
      _errorMessage = null;

      final reminders = await _dbService.getAllReminders();
      _reminders = reminders;

      // Re-schedule pending reminders on app start
      await _rescheduleReminders();

      debugPrint('✅ Loaded ${_reminders.length} reminders');
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load reminders: $e';
      debugPrint('❌ Error loading reminders: $e');
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Add a new reminder
  Future<bool> addReminder({
    required String title,
    required String description,
    required DateTime reminderTime,
    required String category,
  }) async {
    try {
      _errorMessage = null;

      // Validate inputs
      if (title.trim().isEmpty) {
        throw ArgumentError('Title cannot be empty');
      }
      if (reminderTime.isBefore(DateTime.now())) {
        throw ArgumentError('Reminder time must be in the future');
      }

      // Create reminder
      final reminder = Reminder(
        id: const Uuid().v4(),
        title: title.trim(),
        description: description.trim(),
        reminderTime: reminderTime,
        category: category,
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      // Save to database
      await _dbService.insertReminder(reminder);

      // Schedule notification
      await _notificationService.scheduleReminder(
        id: reminder.hashCode,
        title: reminder.title,
        body: reminder.description,
        scheduledTime: reminder.reminderTime,
        payload: reminder.id,
      );

      // Update local state
      _reminders.add(reminder);
      notifyListeners();

      debugPrint('✅ Reminder added: ${reminder.title}');
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add reminder: $e';
      debugPrint('❌ Error adding reminder: $e');
      notifyListeners();
      return false;
    }
  }

  /// Update an existing reminder
  Future<bool> updateReminder({
    required String id,
    required String title,
    required String description,
    required DateTime reminderTime,
    required String category,
  }) async {
    try {
      _errorMessage = null;

      // Validate inputs
      if (title.trim().isEmpty) {
        throw ArgumentError('Title cannot be empty');
      }

      // Find reminder
      final index = _reminders.indexWhere((r) => r.id == id);
      if (index == -1) {
        throw ArgumentError('Reminder not found');
      }

      // Cancel old notification
      await _notificationService.cancelReminder(_reminders[index].hashCode);

      // Create updated reminder
      final updatedReminder = _reminders[index].copyWith(
        title: title.trim(),
        description: description.trim(),
        reminderTime: reminderTime,
        category: category,
      );

      // Update database
      await _dbService.updateReminder(updatedReminder);

      // Schedule new notification if not completed
      if (!updatedReminder.isCompleted) {
        await _notificationService.scheduleReminder(
          id: updatedReminder.hashCode,
          title: updatedReminder.title,
          body: updatedReminder.description,
          scheduledTime: updatedReminder.reminderTime,
          payload: updatedReminder.id,
        );
      }

      // Update local state
      _reminders[index] = updatedReminder;
      notifyListeners();

      debugPrint('✅ Reminder updated: ${updatedReminder.title}');
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update reminder: $e';
      debugPrint('❌ Error updating reminder: $e');
      notifyListeners();
      return false;
    }
  }

  /// Mark reminder as completed
  Future<bool> completeReminder(String id) async {
    try {
      _errorMessage = null;

      final index = _reminders.indexWhere((r) => r.id == id);
      if (index == -1) {
        throw ArgumentError('Reminder not found');
      }

      // Cancel notification
      await _notificationService.cancelReminder(_reminders[index].hashCode);

      // Update reminder
      final updatedReminder = _reminders[index].copyWith(isCompleted: true);
      await _dbService.updateReminder(updatedReminder);

      _reminders[index] = updatedReminder;
      notifyListeners();

      debugPrint('✅ Reminder completed: ${updatedReminder.title}');
      return true;
    } catch (e) {
      _errorMessage = 'Failed to complete reminder: $e';
      debugPrint('❌ Error completing reminder: $e');
      notifyListeners();
      return false;
    }
  }

  /// Delete a reminder
  Future<bool> deleteReminder(String id) async {
    try {
      _errorMessage = null;

      final index = _reminders.indexWhere((r) => r.id == id);
      if (index == -1) {
        throw ArgumentError('Reminder not found');
      }

      // Cancel notification
      await _notificationService.cancelReminder(_reminders[index].hashCode);

      // Delete from database
      await _dbService.deleteReminder(id);

      // Update local state
      _reminders.removeAt(index);
      notifyListeners();

      debugPrint('✅ Reminder deleted: $id');
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete reminder: $e';
      debugPrint('❌ Error deleting reminder: $e');
      notifyListeners();
      return false;
    }
  }

  /// Re-schedule all pending reminders (called on app start)
  Future<void> _rescheduleReminders() async {
    try {
      for (final reminder in _reminders) {
        if (!reminder.isCompleted &&
            reminder.reminderTime.isAfter(DateTime.now())) {
          await _notificationService.scheduleReminder(
            id: reminder.hashCode,
            title: reminder.title,
            body: reminder.description,
            scheduledTime: reminder.reminderTime,
            payload: reminder.id,
          );
        }
      }
      debugPrint('✅ All pending reminders re-scheduled');
    } catch (e) {
      debugPrint('❌ Error re-scheduling reminders: $e');
    }
  }

  /// Get reminders by category
  List<Reminder> getRemindersByCategory(String category) {
    return _reminders.where((r) => r.category == category).toList();
  }

  /// Get pending reminders (not completed, time not passed)
  List<Reminder> getPendingReminders() {
    return _reminders
        .where((r) =>
            !r.isCompleted && r.reminderTime.isAfter(DateTime.now()))
        .toList();
  }

  /// Get completed reminders
  List<Reminder> getCompletedReminders() {
    return _reminders.where((r) => r.isCompleted).toList();
  }

  /// Private helper to set loading state
  void _setLoading(bool value) {
    _isLoading = value;
  }

  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }
}
