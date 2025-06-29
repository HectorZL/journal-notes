import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

@immutable
class SphereData {
  final String emoji;
  final Color color;
  final double size;
  
  const SphereData({required this.emoji, required this.color, this.size = 40.0});
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SphereData &&
          runtimeType == other.runtimeType &&
          emoji == other.emoji &&
          color == other.color &&
          size == other.size;

  @override
  int get hashCode => Object.hash(emoji, color, size);
}

class JarContainer extends StatefulWidget {
  final List<SphereData> spheresData;
  final double padding;
  final bool animateNewSpheres;

  const JarContainer({
    Key? key,
    required this.spheresData,
    this.padding = 16,
    this.animateNewSpheres = false,
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

class _JarContainerState extends State<JarContainer> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  final Map<int, Widget> _sphereCache = {};
  List<SphereData> _previousSpheresData = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 1.0, // Start at the end to avoid initial animation
    );
    _updateSpheres();
  }

  @override
  void didUpdateWidget(JarContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.spheresData != _previousSpheresData) {
      _updateSpheres();
    }
  }

  void _updateSpheres() {
    if (widget.spheresData == _previousSpheresData) return;
    
    final newSpheresData = List<SphereData>.from(widget.spheresData);
    
    // Only update if there's an actual change
    if (newSpheresData != _previousSpheresData) {
      _previousSpheresData = newSpheresData;
      
      // Only rebuild if the widget is currently mounted
      if (mounted) {
        setState(() {
          // Clear cache when data changes significantly
          if (newSpheresData.length != _sphereCache.length) {
            _sphereCache.clear();
          }
        });
      }
    }
  }

  List<Widget> _buildSpheres() {
    return List.generate(
      _previousSpheresData.length,
      (index) => _buildAnimatedSphere(_previousSpheresData[index], index),
    );
  }

  Widget _buildAnimatedSphere(SphereData data, int index) {
    // Return cached widget if available
    if (_sphereCache[index] != null) {
      return _sphereCache[index]!;
    }

    // For new spheres that need animation
    if (widget.animateNewSpheres && index == widget.spheresData.length - 1) {
      // Schedule animation for the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _animationController.forward().then((_) {
            if (mounted) {
              _animationController.reset();
            }
          });
        }
      });
      
      final widget = AnimatedBuilder(
        animation: _animationController,
        builder: (context, _) {
          return Transform.translate(
            offset: Offset(0, (1 - _animationController.value) * 100),
            child: Opacity(
              opacity: _animationController.value,
              child: _buildSphere(data),
            ),
          );
        },
      );
      
      _sphereCache[index] = widget;
      return widget;
    } else {
      // For static spheres, just build once and cache
      final widget = _buildSphere(data);
      _sphereCache[index] = widget;
      return widget;
    }
  }

  Widget _buildSphere(SphereData data) {
    return RepaintBoundary(
      child: Container(
        key: ValueKey('${data.emoji}-${data.color.value}'),
        width: data.size,
        height: data.size,
        decoration: BoxDecoration(
          color: data.color.withAlpha(128),
          shape: BoxShape.circle,
          border: Border.all(color: data.color, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
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

  @override
  void dispose() {
    _animationController.dispose();
    _sphereCache.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final spheres = _buildSpheres();
          return Stack(
            children: [
              // Jar outline
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _JarPainter(
                  spheres: spheres,
                  padding: widget.padding,
                ),
              ),
              // Spheres container
              Positioned.fill(
                child: Container(
                  padding: EdgeInsets.all(widget.padding),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: spheres,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _JarPainter extends CustomPainter {
  final List<Widget> spheres;
  final double padding;
  
  _JarPainter({
    required this.spheres,
    required this.padding,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = _createJarPath(size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _JarPainter old) => 
      old.spheres != spheres || old.padding != padding;
}

Path _createJarPath(Size size) {
  final path = Path();
  final width = size.width;
  final height = size.height;
  
  // Jar body (ellipse)
  path.addOval(Rect.fromLTWH(0, height * 0.2, width, height * 1.2));
  
  // Jar neck (rectangle)
  path.addRect(Rect.fromLTWH(width * 0.3, 0, width * 0.4, height * 0.2));
  
  // Close the path to avoid lint issues
  path.close();
  
  return path;
}
