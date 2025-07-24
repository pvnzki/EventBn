import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'title': 'Event Reminder',
      'message': 'Don\'t forget! International Band Music Concert starts in 2 hours.',
      'time': '2 hours ago',
      'isRead': false,
      'type': 'reminder',
      'icon': Icons.schedule,
      'color': Color(0xFF6C5CE7),
    },
    {
      'id': '2',
      'title': 'New Event Alert',
      'message': 'Jazz Night Live has been added to your wishlist area. Check it out!',
      'time': '5 hours ago',
      'isRead': false,
      'type': 'new_event',
      'icon': Icons.favorite,
      'color': Color(0xFFFF6B35),
    },
    {
      'id': '3',
      'title': 'Booking Confirmed',
      'message': 'Your booking for Summer Music Festival has been confirmed. Ticket #SM2024001',
      'time': '1 day ago',
      'isRead': true,
      'type': 'booking',
      'icon': Icons.check_circle,
      'color': Color(0xFF00D4AA),
    },
    {
      'id': '4',
      'title': 'Payment Successful',
      'message': 'Payment of \$45.00 for Summer Music Festival has been processed successfully.',
      'time': '1 day ago',
      'isRead': true,
      'type': 'payment',
      'icon': Icons.payment,
      'color': Color(0xFF00D4AA),
    },
    {
      'id': '5',
      'title': 'Event Cancelled',
      'message': 'Unfortunately, Comedy Night Live on Dec 15 has been cancelled. Full refund processed.',
      'time': '2 days ago',
      'isRead': true,
      'type': 'cancellation',
      'icon': Icons.cancel,
      'color': Color(0xFFFF006E),
    },
    {
      'id': '6',
      'title': 'Special Offer',
      'message': 'Get 20% off on all weekend events! Use code WEEKEND20. Valid until Dec 31.',
      'time': '3 days ago',
      'isRead': true,
      'type': 'offer',
      'icon': Icons.local_offer,
      'color': Color(0xFFFF6B35),
    },
    {
      'id': '7',
      'title': 'Event Update',
      'message': 'Food Festival 2024 venue has been changed to Central Park. Please check your ticket.',
      'time': '4 days ago',
      'isRead': true,
      'type': 'update',
      'icon': Icons.info,
      'color': Color(0xFF6C5CE7),
    },
    {
      'id': '8',
      'title': 'New Events Near You',
      'message': '5 new events have been added in your area. Discover them now!',
      'time': '1 week ago',
      'isRead': true,
      'type': 'discovery',
      'icon': Icons.explore,
      'color': Color(0xFF00D4AA),
    },
  ];

  void _markAsRead(String notificationId) {
    setState(() {
      final index = _notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        _notifications[index]['isRead'] = true;
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['isRead'] = true;
      }
    });
  }

  void _deleteNotification(String notificationId) {
    setState(() {
      _notifications.removeWhere((n) => n['id'] == notificationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n['isRead']).length;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (unreadCount > 0)
              Text(
                '$unreadCount new notifications',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: Color(0xFF6C5CE7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return _buildNotificationItem(notification);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'You\'re all caught up! Check back later for updates.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    return Dismissible(
      key: Key(notification['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 24,
        ),
      ),
      onDismissed: (direction) {
        _deleteNotification(notification['id']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${notification['title']} deleted'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _markAsRead(notification['id']),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification['isRead'] ? Colors.white : const Color(0xFF6C5CE7).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification['isRead'] ? Colors.grey.shade200 : const Color(0xFF6C5CE7).withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: notification['color'].withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  notification['icon'],
                  color: notification['color'],
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notification['isRead'] ? FontWeight.w600 : FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        if (!notification['isRead'])
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF6C5CE7),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      notification['message'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      notification['time'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // More options
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'mark_read':
                      _markAsRead(notification['id']);
                      break;
                    case 'delete':
                      _deleteNotification(notification['id']);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (!notification['isRead'])
                    const PopupMenuItem<String>(
                      value: 'mark_read',
                      child: Row(
                        children: [
                          Icon(Icons.mark_email_read, size: 16),
                          SizedBox(width: 8),
                          Text('Mark as read'),
                        ],
                      ),
                    ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
