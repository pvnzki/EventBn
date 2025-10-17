import 'package:flutter/material.dart';

enum NotificationType {
  success,
  error,
  warning,
  info,
}

class CustomNotification {
  static void show(
    BuildContext context, {
    required String message,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 4),
    String? title,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    // Get theme colors
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Define colors based on type
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (type) {
      case NotificationType.success:
        backgroundColor = const Color(0xFF25D366); // WhatsApp green
        textColor = Colors.white;
        icon = Icons.check_circle;
        break;
      case NotificationType.error:
        backgroundColor = const Color(0xFFDC362E); // WhatsApp red
        textColor = Colors.white;
        icon = Icons.error;
        break;
      case NotificationType.warning:
        backgroundColor = const Color(0xFFFF9500); // Orange
        textColor = Colors.white;
        icon = Icons.warning;
        break;
      case NotificationType.info:
        backgroundColor =
            isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFFFFFF);
        textColor = isDark ? Colors.white : Colors.black;
        icon = Icons.info;
        break;
    }

    overlayEntry = OverlayEntry(
      builder: (context) => TopNotificationWidget(
        message: message,
        title: title,
        backgroundColor: backgroundColor,
        textColor: textColor,
        icon: icon,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-dismiss after duration
    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

class TopNotificationWidget extends StatefulWidget {
  final String message;
  final String? title;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;
  final VoidCallback onDismiss;

  const TopNotificationWidget({
    super.key,
    required this.message,
    this.title,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    required this.onDismiss,
  });

  @override
  State<TopNotificationWidget> createState() => _TopNotificationWidgetState();
}

class _TopNotificationWidgetState extends State<TopNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _animationController.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: GestureDetector(
            onTap: _dismiss,
            child: Container(
              margin: EdgeInsets.only(
                top: topPadding + 8,
                left: 16,
                right: 16,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    color: widget.textColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.title != null) ...[
                          Text(
                            widget.title!,
                            style: TextStyle(
                              color: widget.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          widget.message,
                          style: TextStyle(
                            color: widget.textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _dismiss,
                    child: Icon(
                      Icons.close,
                      color: widget.textColor.withOpacity(0.7),
                      size: 18,
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
