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
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    if (!mounted) return;
    
    try {
      // Get the current auth state
      final authState = ref.read(authProvider);
      
      // If user is logged in, load their notes
      if (authState.isAuthenticated && authState.userIdAsInt != null) {
        await ref.read(notesProvider.notifier).loadNotes(userId: authState.userIdAsInt);
      } else {
        debugPrint('User is not authenticated or has invalid user ID');
      }
    } catch (e, stackTrace) {
      debugPrint('Error initializing HomeScreen: $e\n$stackTrace');
      // Still set initialized to true to show the UI even if there's an error
    }
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
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
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('MIS EMOCIONES', style: TextStyle(letterSpacing: 1.0, fontWeight: FontWeight.bold)),
        actions: [
          // Show delete button only if we have notes
          Builder(
            builder: (context) {
              return Consumer(
                builder: (context, ref, child) {
                  final notesAsync = ref.watch(notesProvider);
                  return notesAsync.when(
                    data: (notes) => notes.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: _handleClearAllNotes,
                            tooltip: 'LIMPIAR TODO',
                          )
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final notesAsync = ref.watch(notesProvider);
          
          return notesAsync.when(
            data: (allNotes) {
              final todayNotes = _getTodaysNotes(allNotes);
              final hasNotes = todayNotes.isNotEmpty;
              
              return Center(
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
                                  ? _buildMoodIcons(todayNotes)
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
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) {
              debugPrint('Error loading notes: $error\n$stack');
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading notes: ${error.toString()}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _initialize(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  Widget _buildMoodIcons(List<Note> todayNotes) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
                        TextButton(
                          onPressed: () => _handleDeleteNote(note),
                          child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
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
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Nota tipo post-it
                                Transform.rotate(
                                  angle: -0.05, // Pequeña inclinación para efecto de nota pegada
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.yellow[100],
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: const Offset(2, 2),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: Colors.yellow[300]!,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _moodEmojis[note.moodIndex],
                                        style: const TextStyle(fontSize: 40),
                                      ),
                                    ),
                                  ),
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
                                      child: Transform.rotate(
                                        angle: 0.1,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.yellow[50],
                                            border: Border.all(
                                              color: Colors.yellow[300]!,
                                              width: 1.0,
                                            ),
                                          ),
                                          child: Text(
                                            _tapEffects[note.moodIndex],
                                            style: TextStyle(
                                              fontSize: 20,
                                              color: _moodColors[note.moodIndex],
                                            ),
                                          ),
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
          ),
        ],
      ),
    );
  }
  
  // Method to handle note deletion with authentication check
  Future<void> _handleDeleteNote(Note note) async {
    final userId = ref.read(authProvider).userId;
    final userIdInt = int.tryParse(userId ?? '');
    
    if (userIdInt == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor inicia sesión para eliminar notas'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (note.id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No se puede eliminar la nota. ID no válido.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Eliminar nota'),
          content: const Text('¿Estás seguro de que deseas eliminar esta nota?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await ref.read(notesProvider.notifier).deleteNote(note.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nota eliminada')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error deleting note: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar la nota: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Method to handle clear all notes with authentication check
  Future<void> _handleClearAllNotes() async {
    final userId = ref.read(authProvider).userId;
    final userIdInt = int.tryParse(userId ?? '');
    
    if (userIdInt == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor inicia sesión para eliminar notas'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Eliminar todas las notas'),
          content: const Text('¿Estás seguro de que deseas eliminar todas las notas? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar todo', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await ref.read(notesProvider.notifier).clearNotes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Todas las notas han sido eliminadas')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar las notas: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Error clearing notes: $e');
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
}