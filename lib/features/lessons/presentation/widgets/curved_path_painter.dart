import 'package:flutter/material.dart';

class CurvedPathPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  CurvedPathPainter({
    required this.points,
    required this.color,
    this.strokeWidth = 6.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      final dy = p2.dy - p1.dy;
      final cp1 = Offset(p1.dx, p1.dy + dy * 0.5);
      final cp2 = Offset(p2.dx, p2.dy - dy * 0.5);

      // Draw dotted cubic bezier curve by sampling t
      // Step value determines the density of dots
      const double step = 0.03;
      for (double t = 0.05; t <= 0.95; t += step) {
        final Offset pt = _calculateCubicBezier(p1, cp1, cp2, p2, t);
        canvas.drawCircle(pt, strokeWidth / 2, paint);
      }
    }
  }

  Offset _calculateCubicBezier(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final double u = 1 - t;
    final double tt = t * t;
    final double uu = u * u;
    final double uuu = uu * u;
    final double ttt = tt * t;

    double x = uuu * p0.dx;
    x += 3 * uu * t * p1.dx;
    x += 3 * u * tt * p2.dx;
    x += ttt * p3.dx;

    double y = uuu * p0.dy;
    y += 3 * uu * t * p1.dy;
    y += 3 * u * tt * p2.dy;
    y += ttt * p3.dy;

    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant CurvedPathPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
