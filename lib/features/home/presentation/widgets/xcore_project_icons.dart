import 'dart:math' as math;
import 'package:flutter/material.dart';

enum XCoreTechLogo {
  flutter,
  python,
  nodejs,
  web,
  androidJava,
  androidKotlin,
  rust,
}

class XCoreTechIcon extends StatelessWidget {
  const XCoreTechIcon({
    super.key,
    required this.logo,
    required this.color,
    this.size = 25,
  });

  final XCoreTechLogo logo;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _XCoreTechLogoPainter(logo: logo, color: color),
    );
  }
}

class _XCoreTechLogoPainter extends CustomPainter {
  const _XCoreTechLogoPainter({required this.logo, required this.color});

  final XCoreTechLogo logo;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 32;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    final c = Offset(size.width / 2, size.height / 2);

    switch (logo) {
      case XCoreTechLogo.flutter:
        final path = Path()
          ..moveTo(6 * s, 19 * s)
          ..lineTo(19 * s, 6 * s)
          ..lineTo(27 * s, 6 * s)
          ..lineTo(13 * s, 20 * s)
          ..lineTo(20 * s, 20 * s)
          ..lineTo(25 * s, 25 * s)
          ..lineTo(17 * s, 25 * s)
          ..lineTo(13 * s, 21 * s)
          ..lineTo(9 * s, 25 * s)
          ..lineTo(5 * s, 21 * s)
          ..close();
        canvas.drawPath(path, p);
        break;

      case XCoreTechLogo.python:
        final top = Path()
          ..moveTo(16 * s, 4 * s)
          ..cubicTo(9 * s, 4 * s, 7 * s, 8 * s, 7 * s, 13 * s)
          ..lineTo(7 * s, 16 * s)
          ..lineTo(14 * s, 16 * s)
          ..lineTo(14 * s, 9 * s)
          ..cubicTo(14 * s, 7 * s, 16 * s, 6 * s, 18 * s, 6 * s)
          ..lineTo(24 * s, 6 * s)
          ..lineTo(24 * s, 4 * s)
          ..close();
        final bottom = Path()
          ..moveTo(16 * s, 28 * s)
          ..cubicTo(23 * s, 28 * s, 25 * s, 24 * s, 25 * s, 19 * s)
          ..lineTo(25 * s, 16 * s)
          ..lineTo(18 * s, 16 * s)
          ..lineTo(18 * s, 23 * s)
          ..cubicTo(18 * s, 25 * s, 16 * s, 26 * s, 14 * s, 26 * s)
          ..lineTo(8 * s, 26 * s)
          ..lineTo(8 * s, 28 * s)
          ..close();
        final topPaint = Paint()..color = const Color(0xFF3776AB);
        final bottomPaint = Paint()..color = const Color(0xFFFFD43B);
        canvas.drawPath(top, topPaint);
        canvas.drawPath(bottom, bottomPaint);
        canvas.drawCircle(18 * s > 0 ? Offset(18 * s, 8 * s) : c, 1.1 * s, Paint()..color = Colors.white);
        canvas.drawCircle(14 * s > 0 ? Offset(14 * s, 24 * s) : c, 1.1 * s, Paint()..color = Colors.white);
        break;

      case XCoreTechLogo.nodejs:
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final a = -3.1415926535 / 2 + i * 3.1415926535 / 3;
          final pt = Offset(c.dx + 13 * s * math.cos(a), c.dy + 13 * s * math.sin(a));
          if (i == 0) {
            path.moveTo(pt.dx, pt.dy);
          } else {
            path.lineTo(pt.dx, pt.dy);
          }
        }
        path.close();
        canvas.drawPath(path, Paint()..color = const Color(0xFF68A063));
        final n = TextPainter(
          text: const TextSpan(text: 'node', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w900)),
          textDirection: TextDirection.ltr,
        )..layout();
        n.paint(canvas, Offset(c.dx - n.width / 2, c.dy - n.height / 2));
        break;

      case XCoreTechLogo.web:
        canvas.drawCircle(c, 12 * s, stroke);
        canvas.drawOval(Rect.fromCenter(center: c, width: 11 * s, height: 24 * s), stroke);
        canvas.drawLine(Offset(4 * s, c.dy), Offset(28 * s, c.dy), stroke);
        break;

      case XCoreTechLogo.androidJava:
        canvas.drawArc(Rect.fromLTWH(7 * s, 14 * s, 18 * s, 12 * s), 3.1415926535, 3.1415926535, true, p);
        canvas.drawRect(Rect.fromLTWH(7 * s, 19 * s, 18 * s, 7 * s), p);
        canvas.drawLine(Offset(11 * s, 12 * s), Offset(8 * s, 8 * s), stroke);
        canvas.drawLine(Offset(21 * s, 12 * s), Offset(24 * s, 8 * s), stroke);
        canvas.drawCircle(Offset(12 * s, 18 * s), 1.2 * s, Paint()..color = Colors.white);
        canvas.drawCircle(Offset(20 * s, 18 * s), 1.2 * s, Paint()..color = Colors.white);
        break;

      case XCoreTechLogo.androidKotlin:
        final path = Path()
          ..moveTo(6 * s, 5 * s)
          ..lineTo(26 * s, 5 * s)
          ..lineTo(14 * s, 17 * s)
          ..lineTo(26 * s, 29 * s)
          ..lineTo(17 * s, 29 * s)
          ..lineTo(11 * s, 23 * s)
          ..lineTo(6 * s, 28 * s)
          ..close();
        final shader = const LinearGradient(
          colors: [Color(0xFF7F52FF), Color(0xFFFF3D81), Color(0xFF00C8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
        p.shader = shader;
        canvas.drawPath(path, p);
        p.shader = null;
        break;

      case XCoreTechLogo.rust:
        canvas.drawCircle(c, 11 * s, stroke);
        for (int i = 0; i < 8; i++) {
          final a = i * 3.1415926535 / 4;
          canvas.drawLine(
            Offset(c.dx + 11 * s * math.cos(a), c.dy + 11 * s * math.sin(a)),
            Offset(c.dx + 14 * s * _cos(a), c.dy + 14 * s * _sin(a)),
            stroke,
          );
        }
        canvas.drawCircle(c, 4 * s, stroke);
        canvas.drawLine(Offset(10 * s, c.dy), Offset(22 * s, c.dy), stroke);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _XCoreTechLogoPainter oldDelegate) =>
      oldDelegate.logo != logo || oldDelegate.color != color;
}
