import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../models/ticket_model.dart';
import 'ticket_shape_clipper.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  Ticket card — matches the Figma node 2092:5684.
//
//  Layout (inside the notched ticket shape):
//  ┌──────────────────────────────────────┐
//  │  [80×80 image]   Event title …       │
//  ◖ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ◗
//  │  🕒 Sept 14, 2024  📍 Venue  [badge]│
//  └──────────────────────────────────────┘
//
//  Height ≈ 184 (Figma). Notch sits at ≈ 55 % of height.
// ═══════════════════════════════════════════════════════════════════════════════

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final bool isDark;
  final VoidCallback? onTap;

  /// Gold badge colour from Figma (#E0BA68).
  static const _badgeColor = Color(0xFFE0BA68);

  const TicketCard({
    super.key,
    required this.ticket,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.bg01 : Colors.white;
    final dashColor =
        isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.25);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: onTap,
        child: TicketShapeContainer(
          backgroundColor: cardBg,
          notchRadius: 14,
          notchFraction: 0.55,
          cornerRadius: 16,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          child: SizedBox(
            height: 184,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // ── Upper: image + title ───────────────────────────────
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event poster
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: 80,
                            height: 80,
                            child: ticket.eventImageUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: ticket.eventImageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      color: isDark
                                          ? AppColors.surface
                                          : Colors.grey[200],
                                    ),
                                    errorWidget: (_, __, ___) =>
                                        _ImagePlaceholder(isDark: isDark),
                                  )
                                : _ImagePlaceholder(isDark: isDark),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Event title
                        Expanded(
                          child: Text(
                            ticket.eventTitle,
                            style: TextStyle(
                              fontFamily: kFontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                              color: isDark
                                  ? AppColors.white
                                  : AppColors.textPrimaryLight,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Dashed separator (at the notch seam) ──────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: DashedLine(color: dashColor),
                  ),

                  // ── Lower: date, venue, badge ─────────────────────────
                  Row(
                    children: [
                      // Left column — date & venue
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date
                            Row(
                              children: [
                                Image.asset(
                                  'assets/icons/event card/date-time.png',
                                  width: 20,
                                  height: 20,
                                  color: isDark
                                      ? AppColors.grey200
                                      : AppColors.textSecondaryLight,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDate(ticket.eventStartDate),
                                  style: TextStyle(
                                    fontFamily: kFontFamily,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppColors.grey200
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Venue
                            Row(
                              children: [
                                Image.asset(
                                  'assets/icons/event card/location.png',
                                  width: 20,
                                  height: 20,
                                  color: isDark
                                      ? AppColors.grey200
                                      : AppColors.textSecondaryLight,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    ticket.venue.isNotEmpty
                                        ? ticket.venue
                                        : ticket.address,
                                    style: TextStyle(
                                      fontFamily: kFontFamily,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? AppColors.grey200
                                          : AppColors.textSecondaryLight,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _badgeColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          ticket.ticketTypeName.isNotEmpty
                              ? ticket.ticketTypeName
                              : 'Standard',
                          style: const TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.dark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final bool isDark;
  const _ImagePlaceholder({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppColors.surface : Colors.grey[200],
      child: Icon(
        Icons.event_rounded,
        size: 28,
        color: isDark ? AppColors.grey300 : Colors.grey[400],
      ),
    );
  }
}
