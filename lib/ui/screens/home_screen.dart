import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/providers/providers.dart';
import '../../models/note.dart';
import '../widgets/ball_animation.dart';
import '../widgets/jar_container/jar_container_export.dart';

import 'package:shared_preferences/shared_preferences.dart';

// Provider for the ball animation state
final ballAnimationProvider = StateNotifierProvider<BallAnimationNotifier, BallAnimationState>(
  (ref) => BallAnimationNotifier(),
);

class BallAnimationState {
  final bool isAnimating;
  final Color? ballColor;
  final int? lastAnimatedNoteId;

  BallAnimationState({
    this.isAnimating = false, 
    this.ballColor,
    this.lastAnimatedNoteId,
  });

  BallAnimationState copyWith({
    bool? isAnimating,
    Color? ballColor,
    int? lastAnimatedNoteId,
  }) {
    return BallAnimationState(
      isAnimating: isAnimating ?? this.isAnimating,
      ballColor: ballColor ?? this.ballColor,
      lastAnimatedNoteId: lastAnimatedNoteId ?? this.lastAnimatedNoteId,
    );
  }
  
  // Convert state to map for persistence
  Map<String, dynamic> toJson() {
    return {
      'isAnimating': isAnimating,
      'colorValue': ballColor?.value,
      'lastAnimatedNoteId': lastAnimatedNoteId,
    };
  }
  
  // Create state from map
  factory BallAnimationState.fromJson(Map<String, dynamic> json) {
    return BallAnimationState(
      isAnimating: json['isAnimating'] ?? false,
      ballColor: json['colorValue'] != null 
          ? Color(json['colorValue']) 
          : null,
      lastAnimatedNoteId: json['lastAnimatedNoteId'],
    );
  }
}

class BallAnimationNotifier extends StateNotifier<BallAnimationState> {
  static const String _prefsKey = 'ball_animation_state';
  
  BallAnimationNotifier() : super(BallAnimationState()) {
    _loadState();
  }

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);
      if (jsonString != null) {
        final json = Map<String, dynamic>.from(
          Map.castFrom<dynamic, dynamic, String, dynamic>(
            jsonDecode(jsonString)
          )
        );
        state = BallAnimationState.fromJson(json);
      }
    } catch (e) {
      debugPrint('Error loading ball animation state: $e');
    }
  }
  
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey, 
        jsonEncode(state.toJson())
      );
    } catch (e) {
      debugPrint('Error saving ball animation state: $e');
    }
  }

  void triggerAnimation(Color color, {int? noteId}) async {
    state = state.copyWith(
      isAnimating: true, 
      ballColor: color,
      lastAnimatedNoteId: noteId,
    );
    await _saveState();
    
    // Reset animation after it completes
    Future.delayed(const Duration(milliseconds: 1500), () {
      resetAnimation();
    });
  }
  
  void resetAnimation() async {
    state = state.copyWith(isAnimating: false);
    await _saveState();
  }
}

// Constants for mood-related data
const _moodColors = [
  Colors.green,
  Colors.lightGreen,
  Colors.yellow,
  Colors.orange,
  Colors.red,
];

const _moodEmojis = ['😄', '🙂', '😐', '🙁', '😞'];

class _MoodCircleAnimation extends StatefulWidget {
  final Color color;
  final VoidCallback onComplete;

  const _MoodCircleAnimation({
    required this.color,
    required this.onComplete,
    Key? key,
  }) : super(key: key);

  @override
  _MoodCircleAnimationState createState() => _MoodCircleAnimationState();
}

class _MoodCircleAnimationState extends State<_MoodCircleAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
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
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.color,
                    width: 2.0,
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

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Set up a listener for note additions after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupNoteListener();
    });
  }
  
  Note? _lastProcessedNote;
  
  void _setupNoteListener() {
    // Listen for changes in the notes list
    ref.listen<List<Note>>(
      notesProvider,
      (previous, next) {
        if (next.isNotEmpty) {
          final lastNote = next.last;
          
          // Only trigger animation if this is a new note
          if (_lastProcessedNote?.id != lastNote.id) {
            _lastProcessedNote = lastNote;
            
            final now = DateTime.now();
            if (lastNote.date.year == now.year &&
                lastNote.date.month == now.month &&
                lastNote.date.day == now.day) {
              
              // Get the mood color
              final color = const [
                Colors.green,
                Colors.lightGreen,
                Colors.yellow,
                Colors.orange,
                Colors.red,
              ][lastNote.moodIndex];
              
              // Trigger the animation
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  ref.read(ballAnimationProvider.notifier).triggerAnimation(color);
                }
              });
            }
          }
        }
      },
    );
  }

  // Memoize the sphere data to prevent unnecessary rebuilds
  List<SphereData> _getSpheresData(List<Note> notes) {
    return notes.map((note) {
      return SphereData(
        emoji: _moodEmojis[note.moodIndex],
        color: _moodColors[note.moodIndex],
        size: 40.0,
        id: note.id,
      );
    }).toList();
  }
  
  // Filter today's notes
  List<Note> _getTodaysNotes(List<Note> allNotes) {
    final today = DateTime.now();
    return allNotes.where((note) {
      return note.date.year == today.year &&
             note.date.month == today.month &&
             note.date.day == today.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Watch for notes and animation state
    final notes = ref.watch(notesProvider);
    final animationState = ref.watch(ballAnimationProvider);
    
    // Convert notes to sphere data
    final spheresData = _getSpheresData(notes);
    
    // Get today's notes and spheres
    final todayNotes = _getTodaysNotes(notes);
    final todaySpheres = spheresData.where((sphere) {
      return todayNotes.any((note) => note.id == sphere.id);
    }).toList();
    
    // Track if we have a new note to animate
    final hasNewNote = _lastProcessedNote != null && 
                      todayNotes.isNotEmpty && 
                      todayNotes.last.id == _lastProcessedNote?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis emociones'),
        actions: [
          if (notes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showClearConfirmation(context, ref),
              tooltip: 'Limpiar todo',
            ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // The jar with all spheres
                    RepaintBoundary(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: JarContainer(
                          key: ValueKey('jar-container-${todayNotes.length}'),
                          spheresData: todaySpheres,
                          animateNewSpheres: hasNewNote,
                          jarColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                    ),
                    
                    // Animated ball that flies into the jar
                    if (animationState.isAnimating && animationState.ballColor != null)
                      BallToJarAnimation(
                        ballColor: animationState.ballColor!,
                        onComplete: () {
                          // Reset the animation state using the notifier
                          ref.read(ballAnimationProvider.notifier).resetAnimation();
                        },
                        child: const SizedBox.shrink(), // Empty child since we're using a Stack
                      ),
                  ],
                ),
              ),
              
              // Calendar will always be visible, no empty state message needed
            ],
          ),
        ),
      ),
    );
  }

  // Show confirmation dialog before clearing notes
  void _showClearConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar todas las notas?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(notesProvider.notifier).clearNotes();
              Navigator.pop(context);
              
              // Show confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Todas las notas han sido eliminadas')),
              );
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
