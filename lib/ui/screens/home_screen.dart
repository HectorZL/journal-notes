import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/sphere_data.dart';
import '../../state/providers/providers.dart';
import '../../models/note.dart';
import '../widgets/ball_animation.dart';
import '../widgets/jar_container/jar_container.dart';
import 'note_edit_screen.dart';


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
                  color: widget.color.withAlpha(77), // 0.3 * 255 ≈ 77
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

class _AnimatedAddButton extends StatefulWidget {
  final VoidCallback onTap;
  
  const _AnimatedAddButton({
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  _AnimatedAddButtonState createState() => _AnimatedAddButtonState();
}

class _AnimatedAddButtonState extends State<_AnimatedAddButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withAlpha(77), // 0.3 * 255 ≈ 77
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 40,
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
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  Note? _lastProcessedNote;
  bool _isInitialized = false;
  bool _isDeletingNotes = false;
  final _contentKey = GlobalKey();
  final _jarContainerKey = GlobalKey();

  bool _isFirstBuild = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize in the next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _handleNotesUpdate(List<Note> notes) {
    if (notes.isEmpty) {
      if (_lastProcessedNote != null) {
        setState(() {
          _lastProcessedNote = null;
        });
      }
      return;
    }

    final lastNote = notes.last;
    
    // Only trigger animation if this is a new note and not the first build
    if (_lastProcessedNote?.id != lastNote.id && !_isFirstBuild) {
      setState(() {
        _lastProcessedNote = lastNote;
      });
      
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
            ref.read(ballAnimationProvider.notifier).triggerAnimation(color, noteId: int.tryParse(lastNote.id) ?? 0);
          }
        });
      }
    }
    
    // Reset first build flag after first update
    if (_isFirstBuild) {
      _isFirstBuild = false;
    }
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
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Watch for notes and animation state
    final notes = ref.watch(notesProvider);
    final todayNotes = _getTodaysNotes(notes);
    final hasNotes = todayNotes.isNotEmpty;

    final animationState = ref.watch(ballAnimationProvider);
    
    // Handle notes update
    _handleNotesUpdate(notes);
    
    // Process data in the current frame
    final spheresData = _getSpheresData(todayNotes);
    
    final hasNewNote = _lastProcessedNote != null && 
                      hasNotes && 
                      todayNotes.last.id == _lastProcessedNote?.id;
                      
    // Pre-cache the jar container to prevent rebuild issues
    final jarContainer = RepaintBoundary(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.6,
        child: JarContainer(
          key: _jarContainerKey,
          spheresData: spheresData,
          animateNewSpheres: hasNewNote,
          jarColor: Theme.of(context).colorScheme.primary.withAlpha(77), // 0.3 * 255 ≈ 77
        ),
      ),
    );
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis emociones'),
        actions: [
          if (notes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _showClearConfirmation,
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
                key: _contentKey,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: hasNotes 
                          ? jarContainer
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Sticker/message
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(128), // 0.5 * 255 ≈ 128
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        '📝',
                                        style: TextStyle(fontSize: 60),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        '¡Agrega tu primera emoción del día!',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Toca el botón + para comenzar',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(179), // 0.7 * 255 ≈ 179
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 40),
                              ],
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
                        child: const SizedBox.shrink(),
                      ),
                  ],
                ),
              ),
              
              // Add some spacing at the bottom
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _handleClearNotes() async {
    if (_isDeletingNotes) return;
    
    setState(() {
      _isDeletingNotes = true;
    });
    
    try {
      await ref.read(notesProvider.notifier).clearNotes();
      
      if (mounted) {
        setState(() {
          _lastProcessedNote = null;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Todas las notas han sido eliminadas')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error clearing notes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar las notas')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingNotes = false;
        });
      }
    }
  }
  
  Future<void> _navigateToNoteEditScreen(int moodIndex, Color moodColor, {Note? noteToEdit}) async {
  try {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => NoteEditScreen(
          moodIndex: moodIndex,
          moodColor: moodColor,
          noteToEdit: noteToEdit,
        ),
      ),
    );

    if (result != null && mounted) {
      final isNew = result['isNew'] as bool?;
      if (isNew != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isNew ? 'Nota agregada' : 'Nota actualizada'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
  
  void _showClearConfirmation() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Eliminar todas las notas'),
        content: const Text('¿Estás seguro de que deseas eliminar todas las notas? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _handleClearNotes();
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}