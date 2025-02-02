import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/goal_controller.dart';
import '../controllers/notification_controller.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

class GoalReminderService {
  static final GoalReminderService _instance = GoalReminderService._();
  static GoalReminderService get instance => _instance;

  Timer? _reminderTimer;
  final String _lastCheckKey = 'last_goal_reminder_check';

  GoalReminderService._();

  Future<void> initialize(String token) async {
    // Cancel any existing timer
    _reminderTimer?.cancel();

    // Initialize controllers
    final goalController = GoalController(token: token);
    final notificationController = NotificationController(token: token);

    // Set up periodic reminder check
    _reminderTimer = Timer.periodic(Duration(hours: 24), (_) async {
      await _checkReminders(goalController, notificationController);
    });

    // Do initial check if needed
    await _checkReminders(goalController, notificationController);
  }

  Future<void> _checkReminders(
      GoalController goalController,
      NotificationController notificationController
      ) async {
    try {
      // Check if we should run the reminder check
      if (!await _shouldCheckReminders()) {
        return;
      }

      // Update last check time
      await _updateLastCheckTime();

      // Trigger reminder check on server
      await goalController.checkGoalReminders();

      // Fetch new notifications
      final notifications = await notificationController.getNotifications();

      // Show system notifications for new goal reminders
      for (final notification in notifications) {
        if (notification.type == NotificationType.goalReminder && !notification.isRead) {
          await NotificationService.instance.showGoalReminder(notification);
        }
      }
    } catch (e) {
      print('Error checking goal reminders: $e');
    }
  }

  Future<bool> _shouldCheckReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt(_lastCheckKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Check if at least 20 hours have passed since last check
    return now - lastCheck >= Duration(hours: 20).inMilliseconds;
  }

  Future<void> _updateLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastCheckKey, DateTime.now().millisecondsSinceEpoch);
  }

  void dispose() {
    _reminderTimer?.cancel();
    _reminderTimer = null;
  }
}