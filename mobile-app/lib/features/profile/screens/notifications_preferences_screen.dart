import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFICATIONS PREFERENCES — Figma node 2131:22343
//
// Simple settings list:
//   • Notification Sound  (Default)
//   • LED Indicator        (White)
//   • Auto-update Software (with description text)
// ─────────────────────────────────────────────────────────────────────────────

class NotificationsPreferencesScreen extends StatefulWidget {
  const NotificationsPreferencesScreen({super.key});

  @override
  State<NotificationsPreferencesScreen> createState() =>
      _NotificationsPreferencesScreenState();
}

class _NotificationsPreferencesScreenState
    extends State<NotificationsPreferencesScreen> {
  String _notificationSound = 'Default';
  String _ledIndicator = 'White';
  bool _autoUpdate = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.background : AppColors.bgLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.white : AppColors.dark,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Notifications Preferences',
          style: TextStyle(
            fontFamily: kFontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.white : AppColors.dark,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surface : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Notification Sound
              _PreferenceTile(
                title: 'Notification Sound',
                value: _notificationSound,
                isDark: isDark,
                onTap: () => _pickNotificationSound(context, isDark),
              ),
              _divider(isDark),
              // LED Indicator
              _PreferenceTile(
                title: 'LED Indicator',
                value: _ledIndicator,
                isDark: isDark,
                onTap: () => _pickLedColor(context, isDark),
              ),
              _divider(isDark),
              // Auto-update Software
              _AutoUpdateTile(
                value: _autoUpdate,
                isDark: isDark,
                onChanged: (v) => setState(() => _autoUpdate = v),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: isDark ? AppColors.divider : const Color(0xFFE8E9EA),
    );
  }

  // ── Pickers ──────────────────────────────────────────────────────────────
  void _pickNotificationSound(BuildContext context, bool isDark) {
    _showPickerSheet(
      context: context,
      isDark: isDark,
      title: 'Notification Sound',
      options: ['Default', 'Chime', 'Ding', 'Pop', 'None'],
      selected: _notificationSound,
      onSelected: (v) => setState(() => _notificationSound = v),
    );
  }

  void _pickLedColor(BuildContext context, bool isDark) {
    _showPickerSheet(
      context: context,
      isDark: isDark,
      title: 'LED Indicator',
      options: ['White', 'Green', 'Blue', 'Red', 'None'],
      selected: _ledIndicator,
      onSelected: (v) => setState(() => _ledIndicator = v),
    );
  }

  void _showPickerSheet({
    required BuildContext context,
    required bool isDark,
    required String title,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.white : AppColors.dark,
                ),
              ),
              const SizedBox(height: 8),
              ...options.map((o) => ListTile(
                    title: Text(
                      o,
                      style: TextStyle(
                        fontFamily: kFontFamily,
                        fontSize: 15,
                        fontWeight:
                            o == selected ? FontWeight.w600 : FontWeight.w400,
                        color: isDark ? AppColors.white : AppColors.dark,
                      ),
                    ),
                    trailing: o == selected
                        ? const Icon(Icons.check_rounded,
                            color: AppColors.primary, size: 20)
                        : null,
                    onTap: () {
                      onSelected(o);
                      Navigator.pop(context);
                    },
                  )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

// ── Preference tile ────────────────────────────────────────────────────────
class _PreferenceTile extends StatelessWidget {
  final String title;
  final String value;
  final bool isDark;
  final VoidCallback onTap;

  const _PreferenceTile({
    required this.title,
    required this.value,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontFamily: kFontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.white : AppColors.dark,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: kFontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: isDark ? AppColors.grey : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: isDark ? AppColors.grey : AppColors.textSecondaryLight,
          ),
        ],
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      visualDensity: VisualDensity.compact,
    );
  }
}

// ── Auto-update tile ───────────────────────────────────────────────────────
class _AutoUpdateTile extends StatelessWidget {
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _AutoUpdateTile({
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(
        'Auto-update Software',
        style: TextStyle(
          fontFamily: kFontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.white : AppColors.dark,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          'Automatically download and install software updates.',
          style: TextStyle(
            fontFamily: kFontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: isDark ? AppColors.grey : AppColors.textSecondaryLight,
          ),
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      dense: true,
    );
  }
}
