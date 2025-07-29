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
  
  // Track the last deleted notes for undo functionality
  List<Note>? _lastDeletedNotes;
  bool _lastActionWasClear = false;
  
  NotesNotifier() : super(const AsyncValue.loading()) {
    // Initialize with empty data to avoid null state
    state = const AsyncValue.data([]);
  }

  // Helper getter to safely get the current user ID with validation
  int? get _validatedUserId {
    if (_currentUserId == null || _currentUserId! <= 0) {
      debugPrint('Warning: Invalid or missing user ID: $_currentUserId');
      return null;
    }
    return _currentUserId;
  }

  // Set the current user and load their notes
  Future<void> setCurrentUser(int? userId) async {
    try {
      debugPrint('Setting current user ID: $userId (previous: $_currentUserId)');
      
      // Only update if the user ID has actually changed
      if (userId == _currentUserId) {
        debugPrint('User ID unchanged, skipping notes reload');
        return;
      }
      
      _currentUserId = userId;
      
      if (userId == null || userId <= 0) {
        debugPrint('Invalid or no user ID provided, clearing notes');
        state = const AsyncValue.data([]);
        return;
      }
      
      await loadNotes(userId: userId);
    } on Exception catch (e, stackTrace) {
      debugPrint('Error in setCurrentUser: $e\n$stackTrace');
      state = AsyncValue.error('Error setting current user', stackTrace);
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('Unexpected error in setCurrentUser: $e\n$stackTrace');
      state = AsyncValue.error('Unexpected error setting current user', stackTrace);
      rethrow;
    }
  }

  // Load notes for the current user
  Future<void> loadNotes({required int? userId}) async {
    try {
      if (userId == null || userId <= 0) {
        debugPrint('Invalid user ID provided to loadNotes: $userId');
        state = const AsyncValue.data([]);
        return;
      }
      
      // Update the current user ID if it's different
      if (_currentUserId != userId) {
        _currentUserId = userId;
      }
      
      debugPrint('Loading notes for user ID: $userId');
      state = const AsyncValue.loading();
      
      final notes = await _dbHelper.getNotes(userId);
      debugPrint('Successfully loaded ${notes.length} notes for user ID: $userId');
      state = AsyncValue.data(notes.map((map) => Note.fromMap(map)).toList());
    } catch (e, stackTrace) {
      debugPrint('Error loading notes: $e\n$stackTrace');
      state = AsyncValue.error('Error loading notes: $e', stackTrace);
      rethrow;
    }
  }

  // Forzar la actualización de las notas desde la base de datos
  Future<void> refreshNotes() async {
    try {
      debugPrint('Refrescando notas desde la base de datos...');
      final userId = _validatedUserId;
      if (userId == null) {
        debugPrint('No se puede actualizar: ID de usuario no disponible');
        return;
      }
      final notes = await _dbHelper.getNotes(userId);
      state = AsyncValue.data(notes.map((map) => Note.fromMap(map)).toList());
      debugPrint('Notas actualizadas. Total: ${notes.length}');
    } catch (e, stackTrace) {
      debugPrint('Error al refrescar las notas: $e');
      state = AsyncValue.error('Error al cargar las notas: $e', stackTrace);
      rethrow;
    }
  }

  // Add a new note with validation
  Future<Note> addNote(Note note) async {
    try {
      // Validate user
      final userId = _validatedUserId;
      
      // Validate note
      if (note.content.trim().isEmpty) {
        throw Exception('El contenido de la nota no puede estar vacío');
      }

      // Ensure we have the latest notes
      if (state is! AsyncData) {
        await loadNotes(userId: userId);
      }

      // Convert note to map for database
      final noteMap = note.copyWith(userId: userId).toMap()..remove('note_id');
      
      // Insert into database
      final id = await _dbHelper.insertNote(noteMap);
      
      // Update local state with the new note including the database ID
      final newNote = note.copyWith(id: id, userId: userId);
      
      state = state.whenData((notes) => [newNote, ...notes]);
      
      return newNote;
    } on Exception catch (e, stackTrace) {
      debugPrint('Error adding note: $e\n$stackTrace');
      state = AsyncValue.error('Error al agregar la nota: $e', stackTrace);
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('Unexpected error adding note: $e\n$stackTrace');
      state = AsyncValue.error('Unexpected error al agregar la nota', stackTrace);
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
      debugPrint('Error updating note: $e\n$stackTrace');
      state = AsyncValue.error('Error al actualizar la nota: $e', stackTrace);
      rethrow;
    }
  }

  // Delete a note by ID
  Future<void> deleteNote(int noteId) async {
    try {
      if (noteId == null) {
        throw Exception('No se puede eliminar la nota: ID no válido');
      }
      
      debugPrint('Attempting to delete note with ID: $noteId');
      
      if (_currentUserId == null || _currentUserId! <= 0) {
        throw Exception('No se pudo identificar al usuario. Por favor, inicia sesión nuevamente.');
      }
      
      // Get current notes before setting loading state
      final currentNotes = state.value ?? [];
      
      // Save notes for undo functionality before any changes
      _lastDeletedNotes = currentNotes.where((note) => note.id == noteId).toList();
      _lastActionWasClear = false;
      
      // Set loading state after we've saved the current state
      state = const AsyncValue.loading();
      
      // Delete from database
      final result = await _dbHelper.deleteNoteWithUserId(noteId, userId: _currentUserId!);
      
      if (result > 0) {
        // Update the state by removing the deleted note
        final updatedNotes = currentNotes.where((note) => note.id != noteId).toList();
        state = AsyncValue.data(updatedNotes);
        debugPrint('Successfully deleted note with ID: $noteId');
      } else {
        // If no rows were affected, the note might not exist or belong to the user
        state = AsyncValue.data(currentNotes);
        throw Exception('No se pudo eliminar la nota. La nota no existe o no tienes permiso.');
      }
    } catch (e) {
      debugPrint('Error in deleteNote: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  // Delete a note with validation
  Future<bool> deleteNoteOld(Note note) async {
    try {
      debugPrint('=== STARTING NOTE DELETION ===');
      debugPrint('Note to delete: ${note.id}');
      
      // Validate user ID before proceeding
      final userId = _validatedUserId;
      if (userId == null) {
        throw Exception('No se pudo validar el usuario actual');
      }
      
      debugPrint('Current user ID: $userId');
      
      // Save current state for potential rollback
      final previousState = state;
      
      // Optimistically update UI
      state = state.whenData((notes) {
        return notes.where((n) => n.id != note.id).toList();
      });
      
      // Delete from database with user validation
      final deleted = await _dbHelper.deleteNoteWithUserId(note.id!, userId: userId);
      
      if (deleted <= 0) {
        debugPrint('Error: Note not found or could not be deleted');
        // Revert to previous state if deletion failed
        state = previousState;
        throw Exception('No se pudo encontrar la nota o ya fue eliminada');
      }
      
      debugPrint('Note successfully deleted');
      debugPrint('=== NOTE DELETION COMPLETE ===');
      return true;
    } catch (e, stackTrace) {
      debugPrint('Error deleting note: $e\n$stackTrace');
      state = AsyncValue.error('Error al eliminar la nota: $e', stackTrace);
      rethrow;
    }
  }

  // Clear all notes with validation
  Future<void> clearNotes() async {
    try {
      // Validate user
      final userId = _validatedUserId;
      if (userId == null) {
        throw Exception('No se pudo validar el usuario actual');
      }
      
      // Store all current notes for possible undo
      if (state is AsyncData<List<Note>>) {
        _lastDeletedNotes = List<Note>.from((state as AsyncData<List<Note>>).value);
        _lastActionWasClear = true;
      }
      
      // Optimistically update UI
      state = const AsyncValue.data([]);
      
      // Delete all notes from database for this user
      await _dbHelper.deleteAllNotesForUser(userId);
    } catch (e, stackTrace) {
      // If there's an error, clear the undo state
      _lastDeletedNotes = null;
      debugPrint('Error clearing notes: $e');
      state = AsyncValue.error('Error al eliminar las notas: $e', stackTrace);
      rethrow;
    }
  }
  
  // Undo the last delete operation
  Future<bool> undoLastDelete() async {
    if (_lastDeletedNotes == null || _lastDeletedNotes!.isEmpty) {
      return false; // Nothing to undo
    }
    
    try {
      if (_lastActionWasClear) {
        // If the last action was clear, we need to restore all deleted notes
        for (final note in _lastDeletedNotes!) {
          await addNote(note);
        }
      } else {
        // If the last action was a single delete, restore just that note
        final note = _lastDeletedNotes!.first;
        await addNote(note);
      }
      
      // Clear the undo state after successful undo
      _lastDeletedNotes = null;
      return true;
    } catch (e) {
      debugPrint('Error undoing delete: $e');
      rethrow;
    }
  }
  
  // Check if there's an action that can be undone
  bool get canUndo => _lastDeletedNotes != null && _lastDeletedNotes!.isNotEmpty;
}
