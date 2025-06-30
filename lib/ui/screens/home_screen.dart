import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/providers/providers.dart';
import '../widgets/jar_container.dart';
import 'mood_prompt_screen.dart';

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
        id: note.id,
      );
    }).toList();
    
    // Get today's notes
    final today = DateTime.now();
    final todayNotes = notes.where((note) {
      return note.date.year == today.year &&
             note.date.month == today.month &&
             note.date.day == today.day;
    }).toList();
    
    // Only show today's notes in the jar
    final todaySpheres = spheresData.where((sphere) {
      final note = notes.firstWhere((n) => n.id == sphere.id);
      return note.date.year == today.year &&
             note.date.month == today.month &&
             note.date.day == today.day;
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
                    key: ValueKey('jar-container-${todayNotes.length}'),
                    spheresData: todaySpheres,
                    animateNewSpheres: true,
                  ),
                ),
              ),
              if (todayNotes.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: Text(
                    'Presiona + para agregar tu nota de ánimo de hoy',
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
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const MoodPromptScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          );
          
          if (result == true && context.mounted) {
            // The animation is handled by the JarContainer with animateNewSpheres
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('¡Nota de ánimo agregada!'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        child: const Icon(Icons.add),
        heroTag: 'add_mood_button',
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
