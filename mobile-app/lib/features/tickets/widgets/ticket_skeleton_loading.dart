import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/design_tokens.dart';

/// Skeleton / shimmer loading for the ticket list screen.
///
/// Mirrors the layout of [TicketCard]:
///   • A month-header line
///   • 3 ticket-shaped cards (image + text lines + dashed separator + bottom row)
///
/// Fully theme-aware (light / dark).
class TicketListSkeletonLoading extends StatelessWidget {
  const TicketListSkeletonLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[300]!;
    final highlightColor =
        isDark ? const Color(0xFF2C2C2C) : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Month header placeholder
              _pill(width: 130, height: 16),
              const SizedBox(height: 16),
              _buildTicketCard(),
              const SizedBox(height: 16),
              _buildTicketCard(),
              const SizedBox(height: 24),
              // Second month header
              _pill(width: 110, height: 16),
              const SizedBox(height: 16),
              _buildTicketCard(),
            ],
          ),
        ),
      ),
    );
  }

  /// A single ticket-card skeleton matching the 184 px notched layout.
  Widget _buildTicketCard() {
    return Container(
      height: 184,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // ── Upper: image + text lines ───────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image placeholder (80×80)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title line 1
                      _pill(width: double.infinity, height: 14),
                      const SizedBox(height: 8),
                      // Title line 2
                      _pill(width: 140, height: 14),
                      const SizedBox(height: 10),
                      // Ticket type
                      _pill(width: 80, height: 12),
                      const SizedBox(height: 6),
                      // Price
                      _pill(width: 100, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Dashed line area ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Container(
              height: 1,
              color: Colors.white,
            ),
          ),

          // ── Lower: date, venue, badge ────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _circle(20),
                        const SizedBox(width: 8),
                        _pill(width: 120, height: 12),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _circle(20),
                        const SizedBox(width: 8),
                        _pill(width: 100, height: 12),
                      ],
                    ),
                  ],
                ),
              ),
              // Badge
              Container(
                width: 60,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _pill({required double height, required double width}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  static Widget _circle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Skeleton / shimmer loading for the ticket detail screen.
///
/// Mirrors the [TicketDetailScreen] layout:
///   • Large poster area at top
///   • Badge + title text
///   • Venue / name / date / time / seat rows
///   • QR code placeholder
///   • Download button placeholder
///
/// Fully theme-aware (light / dark).
class TicketDetailSkeletonLoading extends StatelessWidget {
  const TicketDetailSkeletonLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[300]!;
    final highlightColor =
        isDark ? const Color(0xFF2C2C2C) : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Poster area ─────────────────────────────────────────
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),

              // ── Badge + title ─────────────────────────────────────
              _pill(width: 70, height: 22),
              const SizedBox(height: 12),
              _pill(width: double.infinity, height: 18),
              const SizedBox(height: 6),
              _pill(width: 200, height: 18),
              const SizedBox(height: 20),

              // ── Dashed line ────────────────────────────────────────
              Container(height: 1, color: Colors.white),
              const SizedBox(height: 20),

              // ── Venue row ─────────────────────────────────────────
              _pill(width: 50, height: 12),
              const SizedBox(height: 8),
              _pill(width: 180, height: 14),
              const SizedBox(height: 16),

              // ── Name / Date row ───────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _pill(width: 40, height: 12),
                        const SizedBox(height: 8),
                        _pill(width: 120, height: 14),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _pill(width: 40, height: 12),
                        const SizedBox(height: 8),
                        _pill(width: 120, height: 14),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Time / Seat row ───────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _pill(width: 40, height: 12),
                        const SizedBox(height: 8),
                        _pill(width: 90, height: 14),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _pill(width: 40, height: 12),
                        const SizedBox(height: 8),
                        _pill(width: 90, height: 14),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Dashed line ────────────────────────────────────────
              Container(height: 1, color: Colors.white),
              const SizedBox(height: 20),

              // ── QR code ───────────────────────────────────────────
              Center(
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Download button ───────────────────────────────────
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _pill({required double height, required double width}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
