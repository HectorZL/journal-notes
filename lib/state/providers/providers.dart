import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/note.dart';

// Provider for managing notes state
final notesProvider = StateNotifierProvider<NotesNotifier, List<Note>>((ref) {
  return NotesNotifier();
});

class NotesNotifier extends StateNotifier<List<Note>> {
  NotesNotifier() : super([]);

  void addNote(Note note) {
    // Ensure the note has the current date
    final noteWithDate = Note(
      id: note.id,
      content: note.content,
      date: DateTime.now(),
      moodIndex: note.moodIndex,
      color: note.color,
    );
    state = [...state, noteWithDate];
  }
  
  void clearNotes() {
    state = [];
  }
}
