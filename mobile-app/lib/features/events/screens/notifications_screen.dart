import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/design_tokens.dart';
import '../../notifications/models/notification_model.dart';
import '../../notifications/providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<NotificationProvider>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.background : AppColors.bgLight;
    final textColor = isDark ? AppColors.white : AppColors.dark;

    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Image.asset(
                'assets/icons/arrow icon.png',
                width: 24,
                height: 24,
                color: textColor,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.chevron_left,
                  color: textColor,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Notifications',
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            centerTitle: false,
            actions: [
              if (provider.unreadCount > 0)
                TextButton(
                  onPressed: () => provider.markAllAsRead(),
                  child: Text(
                    'Mark all read',
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          body: _buildBody(provider, isDark),
        );
      },
    );
  }

  Widget _buildBody(NotificationProvider provider, bool isDark) {
    if (provider.isLoading && provider.notifications.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: isDark ? AppColors.white : AppColors.dark,
          strokeWidth: 2,
        ),
      );
    }

    if (provider.error != null && provider.notifications.isEmpty) {
      return _buildErrorState(provider, isDark);
    }

    if (provider.notifications.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => provider.fetchNotifications(),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.zero,
        itemCount: provider.notifications.length + (provider.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => Divider(
          height: 1,
          thickness: 0.5,
          color: isDark
              ? AppColors.divider
              : AppColors.textTertiaryLight.withValues(alpha: 0.3),
          indent: 84,
        ),
        itemBuilder: (context, index) {
          if (index == provider.notifications.length) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(
                  color: isDark ? AppColors.white : AppColors.dark,
                  strokeWidth: 2,
                ),
              ),
            );
          }
          return _buildNotificationItem(
            provider.notifications[index],
            provider,
            isDark,
          );
        },
      ),
    );
  }

  Widget _buildErrorState(NotificationProvider provider, bool isDark) {
    final textColor = isDark ? AppColors.white : AppColors.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline,
              size: 56, color: AppColors.error.withValues(alpha: 0.7)),
          const SizedBox(height: 16),
          Text(
            provider.error ?? 'Something went wrong',
            style: TextStyle(
              fontFamily: kFontFamily,
              fontSize: 15,
              color: textColor.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => provider.fetchNotifications(),
            child: Text(
              'Retry',
              style: TextStyle(
                fontFamily: kFontFamily,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final textColor = isDark ? AppColors.white : AppColors.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 72,
            color: textColor.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: TextStyle(
              fontFamily: kFontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              fontFamily: kFontFamily,
              fontSize: 14,
              color: textColor.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    NotificationModel notification,
    NotificationProvider provider,
    bool isDark,
  ) {
    final unreadBg = isDark
        ? AppColors.surface
        : AppColors.primary.withValues(alpha: 0.04);
    final readBg = isDark ? AppColors.background : AppColors.bgLight;
    final titleColor = isDark ? AppColors.white : AppColors.dark;
    final bodyColor = isDark ? AppColors.grey : AppColors.textSecondaryLight;
    final timeColor = isDark ? AppColors.grey300 : AppColors.textTertiaryLight;

    return ClipRect(
      child: Dismissible(
        key: Key(notification.notificationId.toString()),
        direction: DismissDirection.endToStart,
        dismissThresholds: const {DismissDirection.endToStart: 0.3},
        movementDuration: const Duration(milliseconds: 200),
        confirmDismiss: (direction) async {
          // Haptic on threshold reach
          HapticFeedback.mediumImpact();
          return true;
        },
        onDismissed: (_) {
          HapticFeedback.heavyImpact();
          provider.deleteNotification(notification.notificationId);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Notification deleted',
                style: const TextStyle(fontFamily: kFontFamily),
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        background: Container(
          color: AppColors.error,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_outline_rounded,
                  color: Colors.white, size: 24),
              SizedBox(height: 4),
              Text(
                'Delete',
                style: TextStyle(
                  fontFamily: kFontFamily,
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        child: Material(
          color: notification.isRead ? readBg : unreadBg,
          child: InkWell(
            onTap: () {
              if (!notification.isRead) {
                HapticFeedback.lightImpact();
                provider.markAsRead(notification.notificationId);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar / Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.bg01
                          : AppColors.textTertiaryLight.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        notification.typeIcon,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontFamily: kFontFamily,
                                  fontSize: 15,
                                  fontWeight: notification.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                  color: titleColor,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              notification.timeAgo,
                              style: TextStyle(
                                fontFamily: kFontFamily,
                                fontSize: 12,
                                color: timeColor,
                              ),
                            ),
                            if (!notification.isRead) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 9,
                                height: 9,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.body,
                          style: TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 13,
                            color: bodyColor,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
