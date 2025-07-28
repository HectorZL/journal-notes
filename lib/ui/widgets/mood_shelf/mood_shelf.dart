import 'package:flutter/material.dart';
import '../../../../models/sphere_data.dart';

class MoodShelf extends StatelessWidget {
  final List<SphereData> spheresData;
  final bool animateNewSpheres;
  final double spacing;
  final double runSpacing;
  final double maxSpheresPerRow;

  const MoodShelf({
    Key? key,
    required this.spheresData,
    this.animateNewSpheres = false,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.maxSpheresPerRow = 6,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Shelf board
        Container(
          height: 16,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        // Shelf content area
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(128), // 0.5 * 255 ≈ 128
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          child: _buildSpheresGrid(),
        ),
        // Shelf support
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildShelfSupport(),
            _buildShelfSupport(),
          ],
        ),
      ],
    );
  }

  Widget _buildSpheresGrid() {
    if (spheresData.isEmpty) {
      return Center(
        child: Text(
          'No hay emociones hoy',
          style: TextStyle(
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final sphereSize = (availableWidth - ((maxSpheresPerRow - 1) * spacing)) / maxSpheresPerRow;
        
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          alignment: WrapAlignment.center,
          children: spheresData.map((sphere) {
            return _buildSphere(sphere, sphereSize);
          }).toList(),
        );
      },
    );
  }

  Widget _buildSphere(SphereData sphere, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            sphere.color.withAlpha(230), // 0.9 * 255 ≈ 230
            HSLColor.fromColor(sphere.color).withLightness(0.6).toColor(),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: sphere.color.withAlpha(230), // 0.9 * 255 ≈ 230
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: sphere.color.withAlpha(128), // 0.5 * 255 ≈ 128
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          sphere.emoji,
          style: TextStyle(fontSize: size * 0.5),
        ),
      ),
    );
  }

  Widget _buildShelfSupport() {
    return Container(
      width: 40,
      height: 12,
      decoration: BoxDecoration(
        color: Colors.brown[300],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
      ),
    );
  }
}
