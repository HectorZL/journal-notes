import 'package:flutter/material.dart';

class JarPainter extends CustomPainter {
  final Color jarColor;
  final double strokeWidth;

  JarPainter({
    this.jarColor = const Color(0xFFE3F2FD),
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = jarColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;

    final path = _createJarPath(size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant JarPainter oldDelegate) {
    return jarColor != oldDelegate.jarColor || 
           strokeWidth != oldDelegate.strokeWidth;
  }

  Path _createJarPath(Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;
    final centerX = width / 2;
    
    // Jar top (ellipse)
    path.moveTo(centerX - width * 0.3, height * 0.1);
    path.quadraticBezierTo(
      centerX,
      height * 0.05,
      centerX + width * 0.3,
      height * 0.1,
    );
    
    // Right side of jar
    path.lineTo(centerX + width * 0.3, height * 0.9);
    
    // Bottom curve of jar
    path.quadraticBezierTo(
      centerX + width * 0.2,
      height * 0.95,
      centerX,
      height * 0.95,
    );
    path.quadraticBezierTo(
      centerX - width * 0.2,
      height * 0.95,
      centerX - width * 0.3,
      height * 0.9,
    );
    
    // Left side of jar
    path.lineTo(centerX - width * 0.3, height * 0.1);
    
    return path;
  }
}
