import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../../models/sphere_data.dart';

import 'widgets/animated_sphere.dart';
import 'widgets/jar_painter.dart';

typedef SphereBuilder = Widget Function(
  BuildContext context,
  SphereData sphere,
  int index,
  bool isNew,
);

class JarContainer extends StatefulWidget {
  final List<SphereData> spheresData;
  final double padding;
  final bool animateNewSpheres;
  final SphereBuilder? sphereBuilder;
  final Color? jarColor;
  final double? jarStrokeWidth;

  const JarContainer({
    Key? key,
    required this.spheresData,
    this.padding = 16,
    this.animateNewSpheres = false,
    this.sphereBuilder,
    this.jarColor,
    this.jarStrokeWidth,
  }) : super(key: key);

  @override
  _JarContainerState createState() => _JarContainerState();
  
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty('spheresData', spheresData));
    properties.add(DoubleProperty('padding', padding));
    properties.add(FlagProperty('animateNewSpheres', 
      value: animateNewSpheres,
      ifTrue: 'animations enabled',
      ifFalse: 'animations disabled',
    ));
  }
}

class _JarContainerState extends State<JarContainer> {
  final Map<int, Widget> _sphereCache = {};
  List<SphereData> _previousSpheresData = [];

  @override
  void initState() {
    super.initState();
    _updateSpheres();
  }

  @override
  void didUpdateWidget(JarContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateSpheres();
  }

  void _updateSpheres() {
    if (!mounted) return;
    
    // Create a new list to avoid reference issues
    final newSpheresData = List<SphereData>.from(widget.spheresData);
    
    // Check if there are actual changes
    if (listEquals(newSpheresData, _previousSpheresData)) return;
    
    // Clear cache for removed spheres
    final newIds = newSpheresData.map((s) => s.id).toSet();
    _sphereCache.removeWhere((key, _) => !newIds.contains(key));
    
    // Update the previous data
    _previousSpheresData = newSpheresData;
    
    // Always rebuild when spheres change, even if going to empty state
    if (mounted) {
      setState(() {});
    }
  }
  List<Widget> _buildSpheres(Size size) {
    if (_previousSpheresData.isEmpty) {
      return [];
    }
    
    return List.generate(
      _previousSpheresData.length,
      (index) => _buildSphere(_previousSpheresData[index], index, size),
    );
  }

  Widget _buildSphere(SphereData data, int index, Size size) {
    final cacheKey = data.id.hashCode;
    
    // Return cached widget if available
    if (_sphereCache[cacheKey] != null) {
      return _sphereCache[cacheKey]!;
    }

    final isNew = index == _previousSpheresData.length - 1 && widget.animateNewSpheres;
    
    Widget sphereWidget;
    
    if (widget.sphereBuilder != null) {
      sphereWidget = widget.sphereBuilder!(context, data, index, isNew);
    } else {
      sphereWidget = AnimatedSphere(
        data: data,
        shouldAnimate: isNew,
      );
    }
    
    // Position the sphere
    final position = _getSpherePosition(index, size);
    
    final positionedWidget = Positioned(
      left: position.dx,
      top: position.dy,
      child: sphereWidget,
    );
    
    _sphereCache[cacheKey] = positionedWidget;
    return positionedWidget;
  }
  
  Offset _getSpherePosition(int index, Size size) {
    final random = Random(index); // Use index as seed for consistent positions
    
    // Jar dimensions (approximate)
    final jarWidth = size.width * 0.8;
    final jarHeight = size.height * 1.2;
    final centerX = size.width / 2;
    final jarTop = size.height * 0.2;
    
    // Calculate position in polar coordinates for better distribution
    final radius = random.nextDouble() * (jarWidth / 2.5);
    final angle = random.nextDouble() * 2 * pi;
    
    // Convert to cartesian coordinates
    double x = centerX + radius * cos(angle) - 20; // Center the sphere
    double y = jarTop + jarHeight * 0.1 + random.nextDouble() * jarHeight * 0.8 - 20;
    
    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth - (widget.padding * 2),
          constraints.maxHeight - (widget.padding * 2),
        );

        return CustomPaint(
          size: size,
          painter: JarPainter(
            jarColor: widget.jarColor ?? Colors.blue.withValues(alpha: 51), // 0.2 * 255 ≈ 51
            strokeWidth: widget.jarStrokeWidth ?? 2.0,
          ),
          child: Stack(
            children: _buildSpheres(size),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _sphereCache.clear();
    super.dispose();
  }
}
