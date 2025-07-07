import 'package:flutter/material.dart';
import '../../../../models/sphere_data.dart';
import 'sphere_widget.dart';

class AnimatedSphere extends StatefulWidget {
  final SphereData data;
  final bool shouldAnimate;
  final VoidCallback? onAnimationComplete;

  const AnimatedSphere({
    Key? key,
    required this.data,
    this.shouldAnimate = false,
    this.onAnimationComplete,
  }) : super(key: key);

  @override
  _AnimatedSphereState createState() => _AnimatedSphereState();
}

class _AnimatedSphereState extends State<AnimatedSphere>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    if (widget.shouldAnimate) {
      _controller.forward().then((_) {
        widget.onAnimationComplete?.call();
      });
    } else {
      _controller.value = 1.0; // Set to final state
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, (1 - _animation.value) * 50),
          child: Transform.scale(
            scale: 0.5 + _animation.value * 0.5,
            child: Opacity(
              opacity: _animation.value,
              child: SphereWidget(data: widget.data),
            ),
          ),
        );
      },
    );
  }
}
