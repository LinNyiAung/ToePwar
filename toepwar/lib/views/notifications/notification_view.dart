import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controllers/notification_controller.dart';
import '../../helpers/notification_service.dart';
import '../../models/notification_model.dart';


class NotificationListView extends StatefulWidget {
  final String token;

  const NotificationListView({Key? key, required this.token}) : super(key: key);

  @override
  _NotificationListViewState createState() => _NotificationListViewState();
}

class _NotificationListViewState extends State<NotificationListView> {
  late NotificationController _notificationController;
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _notificationController = NotificationController(token: widget.token);
    _initializeNotifications();
    _fetchNotifications();
  }

  Future<void> _initializeNotifications() async {
    await NotificationService.instance.initialize();
    await NotificationService.instance.requestPermissions();
  }

  Future<void> _fetchNotifications() async {
    try {
      final notifications = await _notificationController.getNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load notifications: $e')),
      );
    }
  }

  void _markNotificationAsRead(AppNotification notification) async {
    try {
      await _notificationController.markNotificationAsRead(notification.id);
      setState(() {
        final index = _notifications.indexOf(notification);
        _notifications[index] = AppNotification(
          id: notification.id,
          title: notification.title,
          message: notification.message,
          timestamp: notification.timestamp,
          type: notification.type,
          isRead: true,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark notification as read')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.clear_all),
            onPressed: _notifications.isNotEmpty
                ? () {
              // TODO: Implement clear all notifications functionality
            }
                : null,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return Dismissible(
            key: Key(notification.id),
            background: Container(
              color: Colors.green,
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.only(left: 16),
              child: Icon(Icons.check, color: Colors.white),
            ),
            secondaryBackground: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                // Mark as read
                _markNotificationAsRead(notification);
                return false;
              }
              if (direction == DismissDirection.endToStart) {
                try {
                  // Delete notification from backend
                  await _notificationController.deleteNotification(notification.id);
                  return true; // Allow dismissal
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete notification: $e')),
                  );
                  return false; // Prevent dismissal
                }
              }
              return false;
            },
            onDismissed: (direction) {
              if (direction == DismissDirection.endToStart) {
                setState(() {
                  _notifications.removeAt(index);
                });
              }
            },
            child: ListTile(
              leading: _getNotificationIcon(notification.type),
              title: Text(
                notification.title,
                style: TextStyle(
                  fontWeight: notification.isRead
                      ? FontWeight.normal
                      : FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.message),
                  SizedBox(height: 4),
                  Text(
                    _formatTimestamp(notification.timestamp),
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              trailing: notification.isRead
                  ? null
                  : Icon(Icons.circle, color: Colors.blue, size: 10),
            ),
          );
        },
      ),
    );
  }

  Widget _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.expenseAlert:
        return Icon(Icons.warning, color: Colors.red);
      case NotificationType.goalProgress:
        return Icon(Icons.flag, color: Colors.green);
      case NotificationType.budgetWarning:
        return Icon(Icons.attach_money, color: Colors.orange);
      case NotificationType.systemUpdate:
      default:
        return Icon(Icons.notifications, color: Colors.blue);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return DateFormat('MMM d, yyyy').format(timestamp);
    }
  }
}