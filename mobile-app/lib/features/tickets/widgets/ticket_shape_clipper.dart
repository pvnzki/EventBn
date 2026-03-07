import 'dart:math' as math;
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  Ticket-shaped clipper with semi-circular notches on both sides.
//
//  Creates the classic punched-ticket look seen in Figma:
//    ┌──────────────────────────┐
//    │                          │
//    │        content           │
//   ◖                          ◗   ← notch at [notchFraction] of height
//    │        content           │
//    │                          │
//    └──────────────────────────┘
//
//  [notchRadius] — radius of the semi-circles on left/right edges.
//  [notchFraction] — vertical fraction (0..1) where the notch sits.
//  [cornerRadius] — outer corner radius of the ticket rectangle.
// ═══════════════════════════════════════════════════════════════════════════════

class TicketShapeClipper extends CustomClipper<Path> {
  final double notchRadius;
  final double notchFraction;
  final double cornerRadius;

  const TicketShapeClipper({
    this.notchRadius = 14,
    this.notchFraction = 0.5,
    this.cornerRadius = 16,
  });

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final r = cornerRadius;
    final nr = notchRadius;
    final notchY = h * notchFraction;

    final path = Path();

    // Start at top-left corner (after the corner arc)
    path.moveTo(r, 0);

    // Top edge → top-right corner
    path.lineTo(w - r, 0);
    path.arcTo(
      Rect.fromLTWH(w - 2 * r, 0, 2 * r, 2 * r),
      -math.pi / 2,
      math.pi / 2,
      false,
    );

    // Right edge down to notch
    path.lineTo(w, notchY - nr);

    // Right notch (semi-circle inward)
    path.arcTo(
      Rect.fromLTWH(w - nr, notchY - nr, 2 * nr, 2 * nr),
      -math.pi / 2,
      -math.pi,
      false,
    );

    // Right edge continues to bottom-right corner
    path.lineTo(w, h - r);
    path.arcTo(
      Rect.fromLTWH(w - 2 * r, h - 2 * r, 2 * r, 2 * r),
      0,
      math.pi / 2,
      false,
    );

    // Bottom edge → bottom-left corner
    path.lineTo(r, h);
    path.arcTo(
      Rect.fromLTWH(0, h - 2 * r, 2 * r, 2 * r),
      math.pi / 2,
      math.pi / 2,
      false,
    );

    // Left edge up to notch
    path.lineTo(0, notchY + nr);

    // Left notch (semi-circle inward)
    path.arcTo(
      Rect.fromLTWH(-nr, notchY - nr, 2 * nr, 2 * nr),
      math.pi / 2,
      -math.pi,
      false,
    );

    // Left edge continues to top-left corner
    path.lineTo(0, r);
    path.arcTo(
      Rect.fromLTWH(0, 0, 2 * r, 2 * r),
      math.pi,
      math.pi / 2,
      false,
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(TicketShapeClipper oldClipper) {
    return oldClipper.notchRadius != notchRadius ||
        oldClipper.notchFraction != notchFraction ||
        oldClipper.cornerRadius != cornerRadius;
  }
}

// ─── Dashed line painter ─────────────────────────────────────────────────────
/// Paints a horizontal dashed line — used at the notch seam.
class DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashGap;
  final double strokeWidth;

  const DashedLinePainter({
    required this.color,
    this.dashWidth = 6,
    this.dashGap = 4,
    this.strokeWidth = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    double x = 0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + dashWidth, y), paint);
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

// ─── Convenience widget ──────────────────────────────────────────────────────
/// A dashed line widget, often placed at the notch seam in a ticket card.
class DashedLine extends StatelessWidget {
  final Color color;
  final double height;
  final double dashWidth;
  final double dashGap;

  const DashedLine({
    super.key,
    required this.color,
    this.height = 1,
    this.dashWidth = 6,
    this.dashGap = 4,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(double.infinity, height),
      painter: DashedLinePainter(
        color: color,
        dashWidth: dashWidth,
        dashGap: dashGap,
      ),
    );
  }
}

// ─── Ticket-shaped container ─────────────────────────────────────────────────
/// Wraps [child] in a ticket-shaped clip with optional shadow and background.
class TicketShapeContainer extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final double notchRadius;
  final double notchFraction;
  final double cornerRadius;
  final List<BoxShadow>? boxShadow;

  const TicketShapeContainer({
    super.key,
    required this.child,
    required this.backgroundColor,
    this.notchRadius = 14,
    this.notchFraction = 0.5,
    this.cornerRadius = 16,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TicketShadowPainter(
        clipper: TicketShapeClipper(
          notchRadius: notchRadius,
          notchFraction: notchFraction,
          cornerRadius: cornerRadius,
        ),
        color: backgroundColor,
        shadows: boxShadow ?? [],
      ),
      child: ClipPath(
        clipper: TicketShapeClipper(
          notchRadius: notchRadius,
          notchFraction: notchFraction,
          cornerRadius: cornerRadius,
        ),
        child: ColoredBox(
          color: backgroundColor,
          child: child,
        ),
      ),
    );
  }
}

/// Paints a filled ticket shape + optional box shadows behind the clip,
/// so the shadow silhouette includes the notch cutouts.
class _TicketShadowPainter extends CustomPainter {
  final TicketShapeClipper clipper;
  final Color color;
  final List<BoxShadow> shadows;

  _TicketShadowPainter({
    required this.clipper,
    required this.color,
    required this.shadows,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (shadows.isEmpty) return;
    final path = clipper.getClip(size);
    for (final shadow in shadows) {
      final paint = Paint()
        ..color = shadow.color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurRadius / 2);
      canvas.save();
      canvas.translate(shadow.offset.dx, shadow.offset.dy);
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_TicketShadowPainter old) => false;
}
