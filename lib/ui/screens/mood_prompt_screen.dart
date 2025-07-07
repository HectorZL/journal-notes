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
    const Color(0xFF4CAF50), // Green
    const Color(0xFF8BC34A), // Light Green
    const Color(0xFFFFC107), // Amber
    const Color(0xFFFF9800), // Orange
    const Color(0xFFF44336), // Red
  ];

  final List<String> moodDescriptions = [
    '¡Excelente!',
    'Bien',
    'Neutral',
    'No muy bien',
    'Mal'
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
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => NoteEditScreen(
          moodIndex: index,
          moodColor: moodColors[index],
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutQuart;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
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
    final moods = ['😄', '🙂', '😐', '🙁', '😞'];
    final moodButtons = List.generate(
      moods.length,
      (index) => _MoodButton(
        emoji: moods[index],
        color: moodColors[index],
        label: moodDescriptions[index],
        onPressed: () => _onMoodSelected(index, context),
        size: buttonSize,
        fontSize: fontSize,
      ),
    );

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

  const _MoodButton({
    Key? key,
    required this.emoji,
    required this.color,
    required this.label,
    required this.onPressed,
    this.size = 70.0,
    this.fontSize = 16.0,
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
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.emoji,
                style: TextStyle(fontSize: widget.size * 0.4),
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
