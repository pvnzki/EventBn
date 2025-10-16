import 'package:flutter/material.dart';
import 'dart:math' as math;

// Casino-style wheel painter with premium aesthetics
class CasinoWheelPainter extends CustomPainter {
  final List<String> rewards;
  final List<Color> colors;
  final bool isDark;

  CasinoWheelPainter(this.rewards, this.colors, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sectionAngle = 2 * math.pi / rewards.length;

    for (int i = 0; i < rewards.length; i++) {
      final startAngle = i * sectionAngle - math.pi / 2;
      final endAngle = startAngle + sectionAngle;

      // Create gradient for each section
      final gradient = SweepGradient(
        startAngle: startAngle,
        endAngle: endAngle,
        colors: [
          colors[i].withOpacity(0.9),
          colors[i],
          colors[i].withOpacity(0.8),
        ],
      );

      // Draw section with gradient
      final paint = Paint()
        ..shader = gradient
            .createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.fill;

      final path = Path();
      path.moveTo(center.dx, center.dy);
      path.arcTo(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sectionAngle,
        false,
      );
      path.close();

      canvas.drawPath(path, paint);

      // Add subtle inner shadow for depth
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawPath(path, shadowPaint);

      // Add golden border between sections
      final borderPaint = Paint()
        ..color = const Color(0xFFFFD700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      final borderPath = Path();
      borderPath.moveTo(center.dx, center.dy);
      borderPath.lineTo(
        center.dx + radius * math.cos(startAngle),
        center.dy + radius * math.sin(startAngle),
      );
      canvas.drawPath(borderPath, borderPaint);

      // Draw reward text with casino styling
      final textAngle = startAngle + sectionAngle / 2;
      final textRadius = radius * 0.7;
      final textCenter = Offset(
        center.dx + textRadius * math.cos(textAngle),
        center.dy + textRadius * math.sin(textAngle),
      );

      canvas.save();
      canvas.translate(textCenter.dx, textCenter.dy);
      canvas.rotate(textAngle + math.pi / 2);

      final textPainter = TextPainter(
        text: TextSpan(
          text: rewards[i],
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.8),
                blurRadius: 3,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );

      canvas.restore();
    }

    // Add outer rim highlight for 3D effect
    final rimPaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius - 2, rimPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Casino-style pointer painter with premium look
class CasinoPointerPainter extends CustomPainter {
  final bool isDark;

  CasinoPointerPainter(this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFF8C00)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(const Rect.fromLTWH(0, 0, 30, 40))
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    // Create diamond-shaped pointer
    final path = Path();
    path.moveTo(15, 0); // Top point
    path.lineTo(25, 15); // Right point
    path.lineTo(15, 40); // Bottom point
    path.lineTo(5, 15); // Left point
    path.close();

    // Draw shadow
    canvas.save();
    canvas.translate(2, 2);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // Draw main pointer
    canvas.drawPath(path, paint);

    // Add highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, highlightPaint);

    // Add inner diamond detail
    final innerPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final innerPath = Path();
    innerPath.moveTo(15, 8);
    innerPath.lineTo(20, 15);
    innerPath.lineTo(15, 25);
    innerPath.lineTo(10, 15);
    innerPath.close();

    canvas.drawPath(innerPath, innerPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
