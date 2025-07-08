import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database_helper.dart';
import '../../models/note.dart';

// Provider for managing notes state
final notesProvider = StateNotifierProvider<NotesNotifier, AsyncValue<List<Note>>>((ref) {
  return NotesNotifier();
});

class NotesNotifier extends StateNotifier<AsyncValue<List<Note>>> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  int? _currentUserId;
  
  NotesNotifier() : super(const AsyncValue.loading());

  // Set the current user and load their notes
  Future<void> setCurrentUser(int? userId) async {
    _currentUserId = userId;
    if (userId != null) {
      await loadNotes(userId: userId);
    } else {
      state = const AsyncValue.data([]);
    }
  }

  // Load notes for the specified user
  Future<void> loadNotes({required int? userId}) async {
    if (userId == null || userId <= 0) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      state = const AsyncValue.loading();
      final notes = await _dbHelper.getNotes(userId);
      state = AsyncValue.data(notes.map((map) => Note.fromMap(map)).toList());
    } catch (e, stackTrace) {
      debugPrint('Error loading notes: $e');
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  // Add a new note
  Future<Note> addNote(Note note) async {
    if (note.userId <= 0) {
      throw Exception('Cannot add note: Invalid user ID');
    }

    if (note.content.trim().isEmpty) {
      throw Exception('Cannot add note: Content cannot be empty');
    }

    try {
      // Ensure we have the latest notes
      if (state is! AsyncData) {
        await loadNotes(userId: note.userId);
      }

      // Convert note to map for database
      final noteMap = note.toMap()..remove('note_id');
      
      // Insert into database
      final id = await _dbHelper.insertNote(noteMap);
      
      // Update local state with the new note including the database ID
      final newNote = note.copyWith(id: id);
      
      state = state.whenData((notes) => [newNote, ...notes]);
      
      return newNote;
    } catch (e, stackTrace) {
      debugPrint('Error adding note: $e');
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  // Update an existing note
  Future<void> updateNote(Note note) async {
    if (note.id == null) {
      throw Exception('Cannot update note: Missing note ID');
    }
    
    if (note.userId <= 0) {
      throw Exception('Cannot update note: Invalid user ID');
    }

    try {
      // Ensure we have the latest notes
      if (state is! AsyncData) {
        await loadNotes(userId: note.userId);
      }

      // Update in database
      final noteMap = note.toMap();
      final updated = await _dbHelper.updateNote(noteMap);
      
      if (updated == 0) {
        throw Exception('Note not found or not updated');
      }
      
      // Update local state
      state = state.whenData((notes) {
        final index = notes.indexWhere((n) => n.id == note.id);
        if (index == -1) {
          // If note not found in local state, add it
          return [note, ...notes];
        } else {
          final updatedNotes = List<Note>.from(notes);
          updatedNotes[index] = note;
          return updatedNotes;
        }
      });
    } catch (e, stackTrace) {
      debugPrint('Error updating note: $e');
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  // Delete a note
  Future<bool> deleteNote(Note note) async {
    if (note.id == null) {
      throw Exception('Cannot delete note: Missing note ID');
    }
    
    if (note.userId <= 0) {
      throw Exception('Cannot delete note: Invalid user ID');
    }

    try {
      // Keep a copy of current state in case we need to revert
      final previousState = state;
      
      // Optimistically update UI
      state = state.whenData((notes) => notes.where((n) => n.id != note.id).toList());
      
      // Delete from database
      final deleted = await _dbHelper.deleteNote(note.id!);
      
      if (deleted == 0) {
        // If delete failed, revert state
        state = previousState;
        throw Exception('Note not found or already deleted');
      }
      
      return true;
    } catch (e, stackTrace) {
      debugPrint('Error deleting note: $e');
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  // Clear all notes (for testing/logout)
  Future<void> clearNotes() async {
    state = const AsyncValue.data([]);
  }
}
