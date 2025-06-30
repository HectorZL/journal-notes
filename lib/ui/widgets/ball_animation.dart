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
      duration: const Duration(milliseconds: 2000),
    );
    
    _controller.addStatusListener((status) {
      debugPrint('Animation status changed: $status');
      if (status == AnimationStatus.completed) {
        debugPrint('Ball animation completed');
        widget.onComplete();
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
      begin: const Offset(0, -1.5), // Start from above the screen
      end: const Offset(0, 0.2),    // End at the top of the jar
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    // Fade in at start, then fade out at the end
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 80),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 10),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // The main content (jar)
        widget.child,
        
        // The animated ball
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final ballSize = _ballSizeAnimation.value;
            final ballPosition = _ballPositionAnimation.value;
            final bounce = _bounceAnimation.value;
            final opacity = _opacityAnimation.value;
            
            // Calculate position based on screen size
            final positionX = screenSize.width * 0.5 + (ballPosition.dx * 50);
            final positionY = screenSize.height * 0.4 * (1 + ballPosition.dy);
            
            debugPrint('Ball position - X: $positionX, Y: $positionY, Size: $ballSize, Opacity: $opacity');
            
            return Positioned(
              left: positionX - (ballSize * 0.5 * bounce),
              top: positionY - (ballSize * 0.5 * bounce),
              child: Transform.scale(
                scale: bounce,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: ballSize,
                    height: ballSize,
                    decoration: BoxDecoration(
                      color: widget.ballColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.ballColor.withOpacity(0.9),
                          blurRadius: 20,
                          spreadRadius: 5,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      gradient: RadialGradient(
                        center: const Alignment(-0.2, -0.2),
                        radius: 0.8,
                        colors: [
                          widget.ballColor,
                          Color.lerp(widget.ballColor, Colors.black, 0.2)!,
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
