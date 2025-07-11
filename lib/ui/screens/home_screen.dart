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
                                color: _moodColors[note.moodIndex].withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _moodColors[note.moodIndex],
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _moodColors[note.moodIndex].withOpacity(0.3),
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
                                                    .withOpacity(0.7),
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
        title: const Text('Mis emociones'),
        actions: [
          // Show delete button only if we have notes
          Builder(
            builder: (context) {
              return notesAsync.when(
                data: (notes) => notes.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: _showClearConfirmation,
                        tooltip: 'Limpiar todo',
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
                                          color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(179), 
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
  
  // Get mood description based on index
  String _getMoodDescription(int moodIndex) {
    const moodDescriptions = [
      'Feliz',
      'Contento',
      'Neutral',
      'Triste',
      'Muy triste',
    ];
    return moodDescriptions[moodIndex];
  }
  
  // Note: Removed _navigateToNoteEditScreen as editing is now only available from calendar
  
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