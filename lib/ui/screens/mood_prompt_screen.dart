import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'note_edit_screen.dart';

class MoodPromptScreen extends ConsumerStatefulWidget {
  const MoodPromptScreen({Key? key}) : super(key: key);

  @override
  _MoodPromptScreenState createState() => _MoodPromptScreenState();
}

class _MoodPromptScreenState extends ConsumerState<MoodPromptScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final List<Color> moodColors = [
    const Color(0xFF4CAF50), // Green - Happy
    const Color(0xFF8BC34A), // Light Green - Good
    const Color(0xFFFFC107), // Amber - Neutral
    const Color(0xFFFF9800), // Orange - Not Good
    const Color(0xFFF44336), // Red - Bad
  ];

  final List<String> moodDescriptions = [
    '¡Feliz!',
    'Contento',
    'Neutral',
    'Triste',
    'Muy triste'
  ];

  final List<String> moodIcons = [
    '😊', // Happy
    '🙂', // Good
    '😐', // Neutral
    '😔', // Sad
    '😢',  // Very Sad
  ];
  
  // Animation effects for each mood
  final List<Map<String, dynamic>> moodAnimations = [
    {'scale': 1.2, 'rotate': 0.1, 'bounce': 1.5}, // Happy
    {'scale': 1.1, 'rotate': 0.05, 'bounce': 1.2}, // Good
    {'scale': 1.0, 'rotate': 0.0, 'bounce': 1.0}, // Neutral
    {'scale': 0.9, 'rotate': -0.05, 'bounce': 0.9}, // Sad
    {'scale': 0.8, 'rotate': -0.1, 'bounce': 0.8}, // Very Sad
  ];
  
  // Additional effects when tapped
  final List<String> tapEffects = [
    '😄', // Happy face becomes bigger smile
    '🙃', // Slight upside down
    '🤔', // Thinking
    '💧', // Tear drop
    '😭', // Crying
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onMoodSelected(int index, BuildContext context) {
    // Use pushReplacement to replace MoodPromptScreen with NoteEditScreen
    // When NoteEditScreen is popped, it will return to HomeScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditScreen(
          initialMoodIndex: index,
          moodColor: moodColors[index],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final buttonSize = isSmallScreen ? 60.0 : 70.0;
    final fontSize = isSmallScreen ? 14.0 : 16.0;
    final List<Widget> moodButtons = List.generate(
      moodIcons.length,
      (index) => _MoodButton(
        emoji: moodIcons[index],
        color: moodColors[index],
        label: moodDescriptions[index],
        onPressed: () => _onMoodSelected(index, context),
        size: buttonSize,
        fontSize: fontSize,
        animation: moodAnimations[index],
        tapEffect: tapEffects[index],
      ),
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('¿Cómo te sientes hoy?'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: SafeArea(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 100,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Selecciona tu estado de ánimo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: moodButtons,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MoodButton extends StatefulWidget {
  final String emoji;
  final Color color;
  final String label;
  final VoidCallback onPressed;
  final double size;
  final double fontSize;
  final Map<String, dynamic> animation;
  final String tapEffect;

  const _MoodButton({
    Key? key,
    required this.emoji,
    required this.color,
    required this.label,
    required this.onPressed,
    required this.size,
    required this.fontSize,
    required this.animation,
    required this.tapEffect,
  }) : super(key: key);

  @override
  _MoodButtonState createState() => _MoodButtonState();
}

class _MoodButtonState extends State<_MoodButton> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 26), // 0.1 * 255 ≈ 26
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.color.withValues(alpha: 77), // 0.3 * 255 ≈ 77
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 26), // 0.1 * 255 ≈ 26
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.emoji,
                style: TextStyle(fontSize: widget.size * 0.5),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: widget.size + 20,
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: widget.fontSize * 0.8,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
