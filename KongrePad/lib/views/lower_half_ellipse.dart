import 'package:flutter/material.dart';

class LowerHalfEllipse extends StatelessWidget {
  final double width;
  final double height;

  const LowerHalfEllipse(this.width, this.height, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: CustomPaint(
          painter: LowerHalfEllipsePainter(),
          size: Size(width, height),
        ),
      ),
    );
  }
}

class LowerHalfEllipsePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(
        -0.5 * size.width, -1 * size.height, size.width * 2, size.height * 2);

    canvas.drawArc(rect, 0, 180 * (3.14159265359 / 180), true, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
