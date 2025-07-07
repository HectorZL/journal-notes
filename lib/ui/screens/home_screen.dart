import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notas_animo/ui/screens/mood_prompt_screen.dart';
import '../../models/note.dart';
import '../../state/providers/providers.dart';
import 'note_edit_screen.dart';

// Constants for mood-related data
const _moodColors = [
  Colors.green,
  Colors.lightGreen,
  Colors.yellow,
  Colors.orange,
  Colors.red,
];

const _moodEmojis = ['😄', '🙂', '😐', '🙁', '😞'];

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isInitialized = false;
  bool _isDeletingNotes = false;
  Note? _lastProcessedNote;
  final _contentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Initialize in the next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    });
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
    final notes = ref.watch(notesProvider);
    final todayNotes = _getTodaysNotes(notes);
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
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _moodColors[note.moodIndex].withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _moodColors[note.moodIndex],
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _moodEmojis[note.moodIndex],
                      style: const TextStyle(fontSize: 40),
                    ),
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
              // Add button
              GestureDetector(
                onTap: () {
                  // Navigate to mood prompt screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MoodPromptScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withAlpha(77), 
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
              const SizedBox(height: 16),
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
          initialMoodIndex: moodIndex,
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