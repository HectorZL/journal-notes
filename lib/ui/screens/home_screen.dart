import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notas_animo/state/providers/providers.dart';
import '../../models/note.dart';
import '../../providers/auth_provider.dart';

// Constants for mood-related data
const _moodColors = [
  Color(0xFF4CAF50), // Green - Happy
  Color(0xFF8BC34A), // Light Green - Content
  Color(0xFFFFC107), // Amber - Neutral
  Color(0xFFFF9800), // Orange - Sad
  Color(0xFFF44336), // Red - Very Sad
];

const _moodEmojis = ['😊', '🙂', '😐', '😔', '😢'];

// Animation effects for each mood
const List<Map<String, dynamic>> _moodAnimations = [
  {'scale': 1.2, 'rotate': 0.1, 'bounce': 1.5}, // Happy
  {'scale': 1.1, 'rotate': 0.05, 'bounce': 1.2}, // Content
  {'scale': 1.0, 'rotate': 0.0, 'bounce': 1.0}, // Neutral
  {'scale': 0.9, 'rotate': -0.05, 'bounce': 0.9}, // Sad
  {'scale': 0.8, 'rotate': -0.1, 'bounce': 0.8}, // Very Sad
];

// Additional effects when tapped
const _tapEffects = ['😄', '🙃', '🤔', '💧', '😭'];

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  bool _isInitialized = false;
  bool _isDeletingNotes = false;
  Note? _lastProcessedNote;
  final _contentKey = GlobalKey();
  late AnimationController _floatController;
  Map<String, AnimationController> _scaleControllers = {};

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    
    // Initialize in the next frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        // Get the current user ID
        final userId = ref.read(authProvider).userId;
        
        // If user is logged in, load their notes
        if (userId != null) {
          try {
            final userIdInt = int.tryParse(userId);
            if (userIdInt != null) {
              await ref.read(notesProvider.notifier).loadNotes(userId: userIdInt);
            }
          } catch (e) {
            debugPrint('Error loading notes: $e');
            // Still set initialized to true to show the UI even if there's an error
          }
        }
        
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    });
  }
  
  @override
  void dispose() {
    _floatController.dispose();
    for (var controller in _scaleControllers.values) {
      controller.dispose();
    }
    super.dispose();
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
    
    // Get today's notes
    final notesAsync = ref.watch(notesProvider);
    final todayNotes = notesAsync.when(
      data: (notes) => _getTodaysNotes(notes),
      loading: () => [],
      error: (error, stack) {
        debugPrint('Error loading notes: $error');
        return [];
      },
    );
    final hasNotes = todayNotes.isNotEmpty;
                      
    // Mood icons display
    final moodIcons = Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (hasNotes)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 20,
              runSpacing: 20,
              children: todayNotes.map((note) {
                final emojiKey = '${note.id}_${note.moodIndex}';
                
                // Initialize controllers if they don't exist
                _scaleControllers[emojiKey] ??= AnimationController(
                  vsync: this,
                  duration: const Duration(milliseconds: 500),
                );
                
                final controller = _scaleControllers[emojiKey]!;
                
                final bounceAnimation = Tween<double>(
                  begin: 1.0,
                  end: _moodAnimations[note.moodIndex]['bounce'],
                ).animate(CurvedAnimation(
                  parent: controller,
                  curve: Curves.elasticOut,
                ));
                
                final floatAnimation = Tween<double>(
                  begin: -10.0,
                  end: 10.0,
                ).animate(CurvedAnimation(
                  parent: _floatController,
                  curve: Curves.easeInOut,
                ));
                
                return GestureDetector(
                  onTap: () {
                    // Show note content in a dialog without animation
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Tu nota (${_getMoodDescription(note.moodIndex)})'),
                        content: SingleChildScrollView(
                          child: Text(note.content.isNotEmpty ? note.content : 'Sin contenido'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cerrar'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: AnimatedBuilder(
                    animation: Listenable.merge([bounceAnimation, floatAnimation]),
                    builder: (context, _) {
                      return Transform.translate(
                        offset: Offset(0, floatAnimation.value * 0.5),
                        child: Transform.rotate(
                          angle: _moodAnimations[note.moodIndex]['rotate'] * 
                                 (floatAnimation.value / 10),
                          child: Transform.scale(
                            scale: controller.isAnimating
                                ? bounceAnimation.value
                                : 1.0 + (floatAnimation.value / 50).abs(),
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: _moodColors[note.moodIndex].withValues(alpha: 51),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _moodColors[note.moodIndex],
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _moodColors[note.moodIndex].withValues(alpha: 128),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Main emoji
                                  Text(
                                    _moodEmojis[note.moodIndex],
                                    style: const TextStyle(fontSize: 40),
                                  ),
                                  
                                  // Tap effect
                                  if (controller.isAnimating)
                                    Positioned(
                                      top: -10,
                                      child: FadeTransition(
                                        opacity: Tween<double>(
                                          begin: 1.0,
                                          end: 0.0,
                                        ).animate(CurvedAnimation(
                                          parent: controller,
                                          curve: Curves.easeOut,
                                        )),
                                        child: Text(
                                          _tapEffects[note.moodIndex],
                                          style: TextStyle(
                                            fontSize: 30,
                                            color: _moodColors[note.moodIndex],
                                            shadows: [
                                              Shadow(
                                                blurRadius: 5.0,
                                                color: _moodColors[note.moodIndex]
                                                    .withValues(alpha: 128),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
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
              }).toList(),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('MIS EMOCIONES', style: TextStyle(letterSpacing: 1.0, fontWeight: FontWeight.bold)),
        actions: [
          // Show delete button only if we have notes
          Builder(
            builder: (context) {
              return notesAsync.when(
                data: (notes) => notes.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: _showClearConfirmation,
                        tooltip: 'LIMPIAR TODO',
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),
        ],
      ),
      // Remove any floating action button that might be causing the duplicate
      
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
                          ? moodIcons
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Sticker/message
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(128), 
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: const [
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
                                        '¡AGREGA TU PRIMERA EMOCIÓN DEL DÍA!',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.0,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'TOCA EL BOTÓN + PARA COMENZAR',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(200),
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ), // Added missing closing parenthesis for Container
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Removed add button as per requirements
              const SizedBox(height: 24),
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
            const SnackBar(content: Text('TODAS LAS NOTAS HAN SIDO ELIMINADAS', style: TextStyle(letterSpacing: 0.5))),
          );
        }
      }
    } catch (e) {
      debugPrint('Error clearing notes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ERROR AL ELIMINAR LAS NOTAS', style: TextStyle(letterSpacing: 0.5))),
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
  
  // Get mood description based on index
  String _getMoodDescription(int moodIndex) {
    const moodDescriptions = [
      'FELIZ',
      'CONTENTO',
      'NEUTRAL',
      'TRISTE',
      'MUY TRISTE',
    ];
    return moodDescriptions[moodIndex];
  }
  
  // Note: Removed _navigateToNoteEditScreen as editing is now only available from calendar
  
  void _showClearConfirmation() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('ELIMINAR TODAS LAS NOTAS', style: TextStyle(letterSpacing: 0.5, fontWeight: FontWeight.bold)),
        content: const Text('¿ESTÁS SEGURO DE QUE DESEAS ELIMINAR TODAS LAS NOTAS? ESTA ACCIÓN NO SE PUEDE DESHACER.', 
          style: TextStyle(letterSpacing: 0.3),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCELAR', style: TextStyle(letterSpacing: 0.5)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _handleClearNotes();
            },
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.red, letterSpacing: 0.5, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}