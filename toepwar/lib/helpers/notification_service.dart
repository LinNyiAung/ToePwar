import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  NotificationService._();

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize native android notification settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialize native iOS notification settings
    const iOSSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Initialize settings for both platforms
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  Future<void> _onNotificationTapped(NotificationResponse response) async {
    // Handle notification tap
    // You can navigate to the notifications screen here
  }

  Future<void> requestPermissions() async {
    // Request permissions for iOS
    await _localNotifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> showExpenseAlert(AppNotification notification) async {
    if (!_isInitialized) await initialize();

    // Create Android-specific notification details
    const androidDetails = AndroidNotificationDetails(
      'expense_alerts', // channel id
      'Expense Alerts', // channel name
      channelDescription: 'Notifications for unusual expense patterns',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
    );

    // Create iOS-specific notification details
    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Combine platform-specific details
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    // Show the notification
    await _localNotifications.show(
      notification.hashCode, // unique id for the notification
      notification.title,
      notification.message,
      notificationDetails,
    );
  }


  Future<void> showBalanceAlert(AppNotification notification) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'balance_alerts', // channel id
      'Balance Alerts', // channel name
      channelDescription: 'Notifications for low balance alerts',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
    );

    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.message,
      notificationDetails,
    );
  }

  Future<void> showGoalProgressNotification(AppNotification notification) async {
    if (!_isInitialized) await initialize();

    // Create Android-specific notification details
    const androidDetails = AndroidNotificationDetails(
      'goal_progress', // channel id
      'Goal Progress', // channel name
      channelDescription: 'Notifications for savings goal progress',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
    );

    // Create iOS-specific notification details
    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Combine platform-specific details
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    // Show the notification
    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.message,
      notificationDetails,
    );
  }


  Future<void> showGoalReminder(AppNotification notification) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'goal_reminders', // channel id
      'Goal Reminders', // channel name
      channelDescription: 'Regular reminders about your savings goals',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
    );

    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.message,
      notificationDetails,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }
}