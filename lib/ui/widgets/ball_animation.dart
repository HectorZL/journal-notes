import 'package:flutter/material.dart';

class BallToJarAnimation extends StatefulWidget {
  final Color ballColor;
  final VoidCallback onComplete;
  final Widget child;

  const BallToJarAnimation({
    Key? key,
    required this.ballColor,
    required this.onComplete,
    required this.child,
  }) : super(key: key);

  @override
  _BallToJarAnimationState createState() => _BallToJarAnimationState();
}

class _BallToJarAnimationState extends State<BallToJarAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _ballSizeAnimation;
  late Animation<Offset> _ballPositionAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    debugPrint('BallToJarAnimation - Initializing with color: ${widget.ballColor}');
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addStatusListener((status) {
        debugPrint('Animation status changed: $status');
        if (status == AnimationStatus.completed) {
          debugPrint('Ball animation completed');
          // Small delay before calling onComplete to ensure the animation is fully visible
          Future.delayed(const Duration(milliseconds: 300), widget.onComplete);
        }
      });

    // Animation for ball size (grow and then slight bounce)
    _ballSizeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 30.0, end: 40.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 40.0, end: 35.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 35.0, end: 40.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 40.0, end: 30.0), weight: 30),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Bounce effect (for when the ball hits the bottom)
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.8), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.1), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 30),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Animation for ball position (from top of screen to jar)
    _ballPositionAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5), // Start from just above the visible area
      end: const Offset(0, 0.1),   // End slightly above the center
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutQuad,
      ),
    );

    // Fade in at start, then fade out at the end
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Start the animation after a small delay to ensure the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // The main content
            Positioned.fill(child: widget.child),
            
            // The animated ball - only show if animation is running
            if (_controller.status == AnimationStatus.forward || 
                 _controller.status == AnimationStatus.completed)
              IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _opacityAnimation.value,
                  duration: Duration.zero,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: FractionalTranslation(
                      translation: _ballPositionAnimation.value,
                      child: Transform.scale(
                        scale: _bounceAnimation.value,
                        child: Container(
                          width: _ballSizeAnimation.value,
                          height: _ballSizeAnimation.value,
                          decoration: BoxDecoration(
                            color: widget.ballColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: widget.ballColor.withValues(alpha: 179), // 0.7 * 255 ≈ 179
                                blurRadius: 15,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
