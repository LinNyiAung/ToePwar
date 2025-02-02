import 'package:flutter/material.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });

  // Convert from JSON
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
      type: NotificationTypeExtension.fromString(json['type']?.toString() ?? ''),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString().split('.').last,
      'isRead': isRead,
    };
  }
}

enum NotificationType {
  expenseAlert,
  goalProgress,
  systemUpdate,
  balanceAlert,
  goalReminder
}

extension NotificationTypeExtension on NotificationType {
  static NotificationType fromString(String type) {
    switch (type) {
      case 'expenseAlert':
        return NotificationType.expenseAlert;
      case 'goalProgress':
        return NotificationType.goalProgress;
      case 'systemUpdate':
        return NotificationType.systemUpdate;
      case 'balanceAlert':
        return NotificationType.balanceAlert;
      case 'goalReminder':
        return NotificationType.goalReminder;
      default:
        return NotificationType.systemUpdate;
    }
  }
}