import 'dart:async';
import 'package:flutter/material.dart';

class MoodWeatherIcon extends StatelessWidget {
  final int moodIndex;
  final double size;
  final bool isAnimated;

  const MoodWeatherIcon({
    Key? key,
    required this.moodIndex,
    this.size = 40.0,
    this.isAnimated = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Map mood index to weather icons
    final weatherIcons = [
      _buildSunnyIcon(),
      _buildPartlySunnyIcon(),
      _buildCloudyIcon(),
      _buildRainyIcon(),
      _buildStormyIcon(),
    ];

    // Return the appropriate icon based on moodIndex
    Widget icon = weatherIcons[moodIndex.clamp(0, weatherIcons.length - 1)];

    // Apply animation if enabled
    if (isAnimated) {
      return _AnimatedWeatherIcon(icon: icon);
    }

    return icon;
  }

  Widget _buildSunnyIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.wb_sunny,
          size: size,
          color: Colors.orange,
        ),
        ...List.generate(
          8,
          (index) => Transform.rotate(
            angle: index * (3.14 / 4), // 45 degrees in radians
            child: Container(
              width: size * 0.3,
              height: size * 0.1,
              margin: EdgeInsets.only(bottom: size * 0.45),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange, Colors.orange.withOpacity(0)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: BorderRadius.circular(size * 0.05),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPartlySunnyIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          right: 0,
          top: 0,
          child: Icon(
            Icons.wb_sunny,
            size: size * 0.6,
            color: Colors.orange[300],
          ),
        ),
        Positioned(
          left: 0,
          bottom: 0,
          child: Icon(
            Icons.cloud,
            size: size * 0.8,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildCloudyIcon() {
    return Icon(
      Icons.cloud,
      size: size,
      color: Colors.grey[500],
    );
  }

  Widget _buildRainyIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.cloud,
          size: size,
          color: Colors.grey[700],
        ),
        Positioned(
          bottom: -size * 0.2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (index) => _RainDrop(
                size: size * 0.3,
                color: Colors.blue[300]!,
                delay: index * 0.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStormyIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.cloud,
          size: size,
          color: Colors.grey[800],
        ),
        Positioned(
          bottom: -size * 0.1,
          child: _PulsingBolt(
            size: size * 0.6,
            color: Colors.yellow[700]!,
          ),
        ),
      ],
    );
  }
}

class _PulsingBolt extends StatefulWidget {
  final double size;
  final Color color;

  const _PulsingBolt({
    Key? key,
    required this.size,
    required this.color,
  }) : super(key: key);

  @override
  _PulsingBoltState createState() => _PulsingBoltState();
}

class _PulsingBoltState extends State<_PulsingBolt> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Icon(
            Icons.bolt,
            size: widget.size,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _RainDrop extends StatefulWidget {
  final double size;
  final Color color;
  final double delay;

  const _RainDrop({
    Key? key,
    required this.size,
    required this.color,
    required this.delay,
  }) : super(key: key);

  @override
  _RainDropState createState() => _RainDropState();
}

class _RainDropState extends State<_RainDrop> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _animation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: const Offset(0, 0.5),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Delay the start of animation
    Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation,
      child: Container(
        width: widget.size * 0.2,
        height: widget.size * 0.5,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(widget.size * 0.1),
        ),
      ),
    );
  }
}

class _AnimatedWeatherIcon extends StatefulWidget {
  final Widget icon;

  const _AnimatedWeatherIcon({required this.icon});

  @override
  _AnimatedWeatherIconState createState() => _AnimatedWeatherIconState();
}

class _AnimatedWeatherIconState extends State<_AnimatedWeatherIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    
    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    
    _startAnimation();
  }

  void _startAnimation() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: widget.icon,
    );
  }
}
