import 'package:flutter/material.dart';

class DiagonalStripes extends StatelessWidget {
  final Color color;
  final double opacity; // 0.0 - 1.0

  const DiagonalStripes({super.key, required this.color, this.opacity = 0.05});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      // Use modern Color API: .a is 0..1, withValues expects 0..1
      painter: _DiagonalStripePainter(
        color.withValues(alpha: (color.a * opacity).clamp(0.0, 1.0)),
      ),
      size: Size.infinite,
    );
  }
}

class _DiagonalStripePainter extends CustomPainter {
  final Color stripeColor;
  _DiagonalStripePainter(this.stripeColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = stripeColor
      ..strokeWidth = 20;

    for (double i = -size.height; i < size.width; i += 60) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
