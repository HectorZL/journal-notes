import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/note.dart';

// Provider for managing notes state
final notesProvider = StateNotifierProvider<NotesNotifier, List<Note>>((ref) {
  return NotesNotifier();
});

class NotesNotifier extends StateNotifier<List<Note>> {
  static const String _notesKey = 'mood_notes';
  
  NotesNotifier() : super([]) {
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getStringList(_notesKey) ?? [];
      
      final notes = notesJson
          .map((json) => Note.fromJson(jsonDecode(json) as Map<String, dynamic>))
          .toList();
      
      state = notes;
    } catch (e) {
      debugPrint('Error loading notes: $e');
    }
  }
  
  Future<void> _saveNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = state.map((note) => jsonEncode(note.toJson())).toList();
      await prefs.setStringList(_notesKey, notesJson);
    } catch (e) {
      debugPrint('Error saving notes: $e');
    }
  }

  Future<void> addNote(Note note) async {
    // Ensure the note has the current date
    final noteWithDate = Note(
      id: note.id,
      content: note.content,
      date: DateTime.now(),
      moodIndex: note.moodIndex,
      color: note.color,
    );
    
    state = [...state, noteWithDate];
    await _saveNotes();
  }
  
  Future<void> clearNotes() async {
    state = [];
    await _saveNotes();
  }
  
  Future<void> removeNote(Note noteToRemove) async {
    state = [
      for (final note in state)
        if (note.id != noteToRemove.id) note,
    ];
    await _saveNotes();
  }
}
