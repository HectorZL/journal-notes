import 'dart:math';
import 'package:flutter/material.dart';

class JarContainer extends StatelessWidget {
  final List<Widget> spheres;
  final double padding;

  const JarContainer({
    Key? key,
    required this.spheres,
    this.padding = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: LayoutBuilder(builder: (context, bc) {
        final width = bc.maxWidth;
        final height = bc.maxHeight;
        return Stack(
          children: [
            CustomPaint(
              size: Size(width, height),
              painter: _JarPainter(),
            ),
            ClipPath(
              clipper: _JarClipper(),
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: spheres,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _JarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final path = _createJarPath(size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _JarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _createJarPath(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}

Path _createJarPath(Size size) {
  final w = size.width;
  final h = size.height;
  final neckHeight = h * 0.15;
  final bodyTop = neckHeight;
  final bodyBottom = h * 0.95;
  final left = w * 0.15;
  final right = w * 0.85;

  return Path()
    ..moveTo(left, bodyTop)
    ..lineTo(right, bodyTop)
    ..lineTo(right * 0.95, bodyBottom)
    ..lineTo(left * 1.05, bodyBottom)
    ..close();
}
