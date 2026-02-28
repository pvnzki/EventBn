import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../common_widgets/app_bottom_sheet.dart';
import '../../../core/theme/design_tokens.dart';
import '../models/ticket_model.dart';
import '../services/ticket_service.dart';
import '../widgets/ticket_shape_clipper.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  Ticket detail screen — Figma nodes 2131:23701, 2131:23733, 2131:23816.
//
//  Shows the full e-ticket in the notched ticket shape with:
//    1. Event poster (top, rounded 8px)
//    2. Ticket type badge (gold) + event title
//    3. Venue, Name/Date, Time/Seat rows
//    4. ── notch + dashed line ──
//    5. QR code section
//    6. "Download ticket" button (green CTA)
//
//  Share & download bottom-sheet / dialog are also implemented here.
// ═══════════════════════════════════════════════════════════════════════════════

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;
  final Ticket? initialTicket;

  const TicketDetailScreen({
    super.key,
    required this.ticketId,
    this.initialTicket,
  });

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final TicketService _ticketService = TicketService();
  Ticket? _ticket;
  Map<String, dynamic>? _rawData;
  bool _isLoading = true;
  String? _error;

  static const _badgeColor = Color(0xFFE0BA68);

  @override
  void initState() {
    super.initState();
    if (widget.initialTicket != null) {
      _ticket = widget.initialTicket;
      _isLoading = false;
    }
    _fetchTicket();
  }

  Future<void> _fetchTicket() async {
    // If we already have the ticket from the list screen, skip the fetch —
    // the data is identical, and the detail endpoint may reject the id format.
    if (_ticket != null) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      var result = await _ticketService.getTicketDetails(widget.ticketId);

      // Fallback: try by payment ID if the first call failed and we know it
      if (result['success'] != true) {
        final paymentId = _ticket?.paymentId ?? widget.ticketId;
        result =
            await _ticketService.getTicketDetailsByPaymentId(paymentId);
      }

      if (result['success'] == true) {
        setState(() {
          _ticket = result['ticket'];
          _rawData = result['rawData'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to load ticket';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ─────────────────────────────────────────────────
            _AppBar(onShare: _showShareSheet),
            // ── Body ────────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _ErrorBody(
                          error: _error!, onRetry: _fetchTicket)
                      : _ticket == null
                          ? _ErrorBody(
                              error: 'Ticket not found',
                              onRetry: _fetchTicket)
                          : _TicketBody(
                              ticket: _ticket!,
                              rawData: _rawData,
                              isDark: isDark,
                              onDownload: _showDownloadDialog,
                            ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Share bottom sheet (Figma 2131:23733) ──────────────────────────────────
  void _showShareSheet() {
    if (_ticket == null) return;

    AppBottomSheet.show(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Share ticket',
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.white : AppColors.textPrimaryLight,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Icon(
                    Icons.close,
                    size: 22,
                    color: isDark ? AppColors.grey200 : Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Share your tickets through various platforms\nfor easy access',
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isDark ? AppColors.grey300 : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),
            // Share icons row
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _ShareOption(
                  icon: Icons.podcasts,
                  label: 'AirDrop',
                  isDark: isDark,
                  onTap: () => _doShare(ctx),
                ),
                const SizedBox(width: 16),
                _ShareOption(
                  icon: Icons.chat_bubble,
                  label: 'Message',
                  isDark: isDark,
                  onTap: () => _doShare(ctx),
                ),
                const SizedBox(width: 16),
                _ShareOption(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  isDark: isDark,
                  onTap: () => _doShare(ctx),
                ),
                const SizedBox(width: 16),
                _ShareOption(
                  icon: Icons.phone_android,
                  label: 'WhatsApp',
                  isDark: isDark,
                  onTap: () => _doShare(ctx),
                ),
                const SizedBox(width: 16),
                _ShareOption(
                  icon: Icons.mail,
                  label: 'Gmail',
                  isDark: isDark,
                  onTap: () => _doShare(ctx),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Continue button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => _doShare(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.dark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _doShare(BuildContext ctx) {
    Navigator.pop(ctx);
    final t = _ticket!;
    Share.share(
      'Check out my ticket for ${t.eventTitle}!\n'
      '📍 ${t.venue}\n'
      '📅 ${DateFormat('MMMM d, yyyy').format(t.eventStartDate)}\n'
      'Ticket: ${t.ticketTypeName}',
    );
  }

  // ── Download dialog (Figma 2131:23816) ─────────────────────────────────────
  void _showDownloadDialog() {
    if (_ticket == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return _DownloadDialog(isDark: isDark, onDone: () {
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Ticket downloaded successfully'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          );
        });
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Private widgets
// ═════════════════════════════════════════════════════════════════════════════

// ── App bar ─────────────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  final VoidCallback onShare;
  const _AppBar({required this.onShare});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Back button
          Material(
            color: isDark ? AppColors.bg01 : Colors.grey[200]!,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                width: 36,
                height: 36,
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 16,
                  color: isDark ? AppColors.white : AppColors.textPrimaryLight,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Details ticket',
            style: TextStyle(
              fontFamily: kFontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.white : AppColors.textPrimaryLight,
            ),
          ),
          const Spacer(),
          // Share button
          Material(
            color: isDark ? AppColors.bg01 : Colors.grey[200]!,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: onShare,
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                width: 36,
                height: 36,
                child: Icon(
                  Icons.share_outlined,
                  size: 18,
                  color: isDark ? AppColors.white : AppColors.textPrimaryLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ticket body (the main scrollable content) ───────────────────────────────
class _TicketBody extends StatelessWidget {
  final Ticket ticket;
  final Map<String, dynamic>? rawData;
  final bool isDark;
  final VoidCallback onDownload;

  const _TicketBody({
    required this.ticket,
    required this.rawData,
    required this.isDark,
    required this.onDownload,
  });

  static const _badgeColor = Color(0xFFE0BA68);

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.bg01 : Colors.white;
    final dashColor = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.grey.withOpacity(0.25);
    final labelColor = isDark ? AppColors.grey300 : AppColors.textTertiaryLight;
    final valueColor =
        isDark ? AppColors.white : AppColors.textPrimaryLight;
    final subValueColor = isDark ? AppColors.grey200 : AppColors.textSecondaryLight;

    final userName = rawData?['user']?['name'] ?? 'N/A';
    final seatLabel = rawData?['seat_label'] ?? 'GA';

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: 24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        children: [
          // ── Ticket shape card ─────────────────────────────────────────
          TicketShapeContainer(
            backgroundColor: cardBg,
            notchRadius: 14,
            notchFraction: 0.65,
            cornerRadius: 16,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Event poster ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ticket.eventImageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: ticket.eventImageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: isDark
                                    ? AppColors.surface
                                    : Colors.grey[200],
                                child: Center(
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: isDark
                                    ? AppColors.surface
                                    : Colors.grey[200],
                                child: const Icon(Icons.event_rounded,
                                    size: 40, color: AppColors.grey300),
                              ),
                            )
                          : Container(
                              color: isDark
                                  ? AppColors.surface
                                  : Colors.grey[200],
                              child: const Icon(Icons.event_rounded,
                                  size: 40, color: AppColors.grey300),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Badge ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
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
                ),

                const SizedBox(height: 10),

                // ── Title ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    ticket.eventTitle,
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                      color: valueColor,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Dashed line ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DashedLine(color: dashColor),
                ),

                const SizedBox(height: 16),

                // ── Venue ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vanue',
                        style: TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: labelColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Image.asset(
                            'assets/icons/event card/location.png',
                            width: 20,
                            height: 20,
                            color: subValueColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ticket.venue.isNotEmpty
                                  ? ticket.venue
                                  : ticket.address,
                              style: TextStyle(
                                fontFamily: kFontFamily,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: valueColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Name / Date row ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _InfoColumn(
                          label: 'Name',
                          value: userName,
                          labelColor: labelColor,
                          valueColor: valueColor,
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            _InfoColumn(
                              label: 'Date',
                              labelColor: labelColor,
                              valueColor: subValueColor,
                              child: Row(
                                children: [
                                  Image.asset(
                                    'assets/icons/event card/date-time.png',
                                    width: 16,
                                    height: 16,
                                    color: subValueColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    DateFormat('MMMM d, yyyy')
                                        .format(ticket.eventStartDate),
                                    style: TextStyle(
                                      fontFamily: kFontFamily,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: valueColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Time / Seat row ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _InfoColumn(
                          label: 'Time',
                          value: DateFormat('hh:mm a')
                              .format(ticket.eventStartDate),
                          labelColor: labelColor,
                          valueColor: valueColor,
                        ),
                      ),
                      Expanded(
                        child: _InfoColumn(
                          label: 'Seat',
                          value: seatLabel,
                          labelColor: labelColor,
                          valueColor: valueColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Notch area dashed line ─────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: DashedLine(color: dashColor),
                ),

                const SizedBox(height: 20),

                // ── QR Code ────────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Scan barcode',
                        style: TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: subValueColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: QrImageView(
                          data: ticket.qrCode.isNotEmpty
                              ? ticket.qrCode
                              : 'TICKET:${ticket.id}:${ticket.eventId}:${ticket.userId}',
                          version: QrVersions.auto,
                          size: 160,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Colors.black,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Download button ───────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onDownload,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.dark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Download ticket',
                style: TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Label + value column ────────────────────────────────────────────────────
class _InfoColumn extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? child;
  final Color labelColor;
  final Color valueColor;

  const _InfoColumn({
    required this.label,
    this.value,
    this.child,
    required this.labelColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: kFontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 6),
        child ??
            Text(
              value ?? '',
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      ],
    );
  }
}

// ── Error body ──────────────────────────────────────────────────────────────
class _ErrorBody extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorBody({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 56,
                color: isDark ? AppColors.grey300 : Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 14,
                color: isDark ? AppColors.grey200 : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.dark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Retry',
                  style: TextStyle(fontFamily: kFontFamily)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Share option icon ───────────────────────────────────────────────────────
class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(icon,
                size: 22, color: isDark ? AppColors.white : Colors.grey[700]),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: kFontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.grey200 : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Download dialog (Figma 2131:23816) ──────────────────────────────────────
class _DownloadDialog extends StatefulWidget {
  final bool isDark;
  final VoidCallback onDone;
  const _DownloadDialog({required this.isDark, required this.onDone});

  @override
  State<_DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<_DownloadDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dialogBg = widget.isDark ? AppColors.surface : Colors.white;
    final textPrimary = widget.isDark ? AppColors.white : AppColors.textPrimaryLight;
    final textSecondary =
        widget.isDark ? AppColors.grey300 : AppColors.textSecondaryLight;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: dialogBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Download ticket',
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _ctrl.stop();
                      Navigator.pop(context);
                    },
                    child: Icon(Icons.close, size: 20, color: textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Your download is in progress. Please wait while we prepare your ticket for download',
                style: TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              // Progress bar
              AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _ctrl.value,
                      minHeight: 6,
                      backgroundColor: widget.isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              // Cancel
              GestureDetector(
                onTap: () {
                  _ctrl.stop();
                  Navigator.pop(context);
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
