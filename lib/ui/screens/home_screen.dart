import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../models/note.dart';
import '../widgets/jar_container.dart';
import 'mood_prompt_screen.dart';

// Provider for managing notes state
final notesProvider = StateNotifierProvider<NotesNotifier, List<Note>>((ref) {
  return NotesNotifier();
});

class NotesNotifier extends StateNotifier<List<Note>> {
  NotesNotifier() : super([]);

  void addNote(Note note) {
    state = [...state, note];
  }
  
  void clearNotes() {
    state = [];
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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);
    
    // Convert notes to sphere data
    final spheresData = notes.map((note) {
      return SphereData(
        emoji: _moodEmojis[note.moodIndex],
        color: _moodColors[note.moodIndex],
        size: 40.0,
      );
    }).toList();

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
                child: RepaintBoundary(
                  child: JarContainer(
                    key: ValueKey('jar-container-${notes.length}'),
                    spheresData: spheresData,
                    animateNewSpheres: true,
                  ),
                ),
              ),
              if (notes.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: Text(
                    'Presiona + para agregar tu primer nota de ánimo',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const MoodPromptScreen()),
          );
          
          if (result == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('¡Nota agregada!')),
            );
          }
        },
        child: const Icon(Icons.add),
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
