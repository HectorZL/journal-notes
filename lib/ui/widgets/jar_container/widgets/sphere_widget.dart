import 'package:flutter/material.dart';
import '../../../../models/sphere_data.dart';

class SphereWidget extends StatelessWidget {
  final SphereData data;
  
  const SphereWidget({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        key: ValueKey('${data.emoji}-${data.color.toARGB32()}'),
        width: data.size,
        height: data.size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              data.color.withAlpha(255), // Full opacity for the main color
              HSLColor.fromColor(data.color).withLightness(0.7).toColor(),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            data.emoji,
            style: TextStyle(
              fontSize: data.size * 0.6,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
