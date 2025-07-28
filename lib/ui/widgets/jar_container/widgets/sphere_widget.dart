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
              data.color.withAlpha(230), // 0.9 * 255 ≈ 230
              HSLColor.fromColor(data.color).withLightness(0.6).toColor(),
            ],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: data.color.withAlpha(230), // 0.9 * 255 ≈ 230
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: data.color.withAlpha(77), // 0.3 * 255 ≈ 77
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.black.withAlpha(26), // 0.1 * 255 ≈ 26
              blurRadius: 10,
              spreadRadius: -2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withAlpha(204), // 0.8 * 255 ≈ 204
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Text(
              data.emoji,
              style: TextStyle(
                fontSize: data.size * 0.6,
                height: 1.0,
                shadows: [
                  Shadow(
                    color: Colors.black.withAlpha(51), // 0.2 * 255 ≈ 51
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
