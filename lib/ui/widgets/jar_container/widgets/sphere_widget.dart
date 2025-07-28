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
    return Transform.rotate(
      angle: -0.05, // Pequeña inclinación para efecto de nota pegada
      child: Container(
        key: ValueKey('${data.emoji}-${data.color.toARGB32()}'),
        width: data.size * 1.2,
        height: data.size * 1.2,
        padding: const EdgeInsets.all(4),
        child: Center(
          child: Text(
            data.emoji,
            style: TextStyle(
              fontSize: data.size * 0.5,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
