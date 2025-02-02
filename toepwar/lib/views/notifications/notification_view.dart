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
  List<AppNotification> _filteredNotifications = [];
  bool _isLoading = true;
  NotificationType? _selectedType;
  bool _showUnreadOnly = false;

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

  void _applyFilters() {
    setState(() {
      _filteredNotifications = _notifications.where((notification) {
        bool typeMatch = _selectedType == null || notification.type == _selectedType;
        bool readStatusMatch = !_showUnreadOnly || !notification.isRead;
        return typeMatch && readStatusMatch;
      }).toList();
    });
  }

  Future<void> _fetchNotifications() async {
    try {
      final notifications = await _notificationController.getNotifications();
      setState(() {
        _notifications = notifications;
        _filteredNotifications = notifications;
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

  Future<void> _markAllAsRead() async {
    try {
      for (var notification in _filteredNotifications.where((n) => !n.isRead)) {
        await _notificationController.markNotificationAsRead(notification.id);
      }
      await _fetchNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark notifications as read: $e')),
      );
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: Text('Filter Notifications'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notification Type:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: Text('All'),
                        selected: _selectedType == null,
                        onSelected: (bool selected) {
                          setState(() => _selectedType = null);
                        },
                      ),
                      ...NotificationType.values.map((type) {
                        return FilterChip(
                          label: Text(_getNotificationTypeLabel(type)),
                          selected: _selectedType == type,
                          onSelected: (bool selected) {
                            setState(() => _selectedType = selected ? type : null);
                          },
                        );
                      }),
                    ],
                  ),
                  SizedBox(height: 16),
                  SwitchListTile(
                    title: Text('Show Unread Only'),
                    value: _showUnreadOnly,
                    onChanged: (bool value) {
                      setState(() => _showUnreadOnly = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _applyFilters();
                  },
                  child: Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getNotificationTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.expenseAlert:
        return 'Expense Alerts';
      case NotificationType.goalProgress:
        return 'Goal Progress';
      case NotificationType.systemUpdate:
        return 'System Updates';
      case NotificationType.balanceAlert:
        return 'Balance Alert';
      case NotificationType.goalReminder:
        return 'Goal Reminders';
    }
  }

  Widget _buildNotificationCard(AppNotification notification) {
    return Card(
      color: Theme.of(context).cardColor,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: notification.isRead ? 1 : 3,
      child: Dismissible(
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
            await _notificationController.markNotificationAsRead(notification.id);
            await _fetchNotifications();
            return false;
          }
          return true;
        },
        onDismissed: (direction) async {
          if (direction == DismissDirection.endToStart) {
            await _notificationController.deleteNotification(notification.id);
            await _fetchNotifications();
          }
        },
        child: ListTile(
          contentPadding: EdgeInsets.all(16),
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getNotificationColor(notification.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _getNotificationIcon(notification.type),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8),
              Text(
                notification.message,
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                _formatTimestamp(notification.timestamp),
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          trailing: notification.isRead
              ? null
              : Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.expenseAlert:
        return Colors.red;
      case NotificationType.goalProgress:
        return Colors.green;
      case NotificationType.systemUpdate:
        return Colors.purple;
      case NotificationType.balanceAlert:
        return Colors.blue;
      case NotificationType.goalReminder:
        return Colors.orange;
    }
  }

  Widget _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.expenseAlert:
        return Icon(Icons.warning, color: Colors.red);
      case NotificationType.goalProgress:
        return Icon(Icons.flag, color: Colors.green);
      case NotificationType.systemUpdate:
        return Icon(Icons.notifications, color: Colors.purple);
      case NotificationType.balanceAlert:
        return Icon(Icons.account_balance_wallet, color: Colors.blue);
      case NotificationType.goalReminder:
        return Icon(Icons.timer, color: Colors.orange);// Add new case
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          if (_filteredNotifications.any((n) => !n.isRead))
            IconButton(
              icon: Icon(Icons.mark_email_read),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter notifications',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _filteredNotifications.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No notifications',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (_selectedType != null || _showUnreadOnly)
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedType = null;
                    _showUnreadOnly = false;
                    _applyFilters();
                  });
                },
                child: Text('Clear filters'),
              ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: _filteredNotifications.length,
        itemBuilder: (context, index) {
          return _buildNotificationCard(_filteredNotifications[index]);
        },
      ),
    );
  }
}