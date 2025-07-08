import 'package:flutter/foundation.dart';
import 'database_helper.dart';

class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();
  static DatabaseHelper? _databaseHelper;

  // Private constructor
  LocalDatabase._internal();

  // Factory constructor to provide a singleton instance
  factory LocalDatabase() => _instance;

  // Initialize the database
  Future<void> init() async {
    try {
      _databaseHelper = DatabaseHelper.instance;
      // Initialize the database connection
      await _databaseHelper!.database;
      debugPrint('Database initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize database: $e');
      rethrow;
    }
  }

  // Get the database helper instance
  DatabaseHelper get dbHelper {
    if (_databaseHelper == null) {
      throw Exception('Database not initialized. Call init() first.');
    }
    return _databaseHelper!;
  }

  // User operations
  Future<int> createUser(String name, String email, String password) async {
    final user = {
      DatabaseHelper.columnName: name,
      DatabaseHelper.columnEmail: email,
      DatabaseHelper.columnPassword: password,
    };
    return await dbHelper.insertUser(user);
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    return await dbHelper.getUserByEmail(email);
  }

  Future<bool> validateUser(String email, String password) async {
    return await dbHelper.validateUser(email, password);
  }

  // Note operations
  Future<int> createNote({
    required int userId,
    required int moodIndex,
    String? content,
    String? tags,
    DateTime? date,
  }) async {
    final note = {
      DatabaseHelper.columnUserId: userId,
      DatabaseHelper.columnMoodIndex: moodIndex,
      DatabaseHelper.columnContent: content,
      DatabaseHelper.columnTags: tags,
      DatabaseHelper.columnDate: date?.toIso8601String(),
    };
    return await dbHelper.insertNote(note);
  }

  Future<List<Map<String, dynamic>>> getNotes(int userId, {DateTime? date}) async {
    return await dbHelper.getNotes(userId, date: date);
  }

  Future<int> updateNote({
    required int noteId,
    int? moodIndex,
    String? content,
    String? tags,
  }) async {
    final note = {
      DatabaseHelper.columnNoteId: noteId,
      if (moodIndex != null) DatabaseHelper.columnMoodIndex: moodIndex,
      if (content != null) DatabaseHelper.columnContent: content,
      if (tags != null) DatabaseHelper.columnTags: tags,
    };
    return await dbHelper.updateNote(note);
  }

  Future<int> deleteNote(int noteId) async {
    return await dbHelper.deleteNote(noteId);
  }

  // Statistics
  Future<Map<String, dynamic>> getStats(int userId, {DateTime? startDate, DateTime? endDate}) async {
    return await dbHelper.getStats(userId, startDate: startDate, endDate: endDate);
  }

  // Close the database connection
  Future<void> close() async {
    if (_databaseHelper != null) {
      await _databaseHelper!.close();
      _databaseHelper = null;
    }
  }

  // For testing/debugging purposes
  Future<void> deleteDatabase() async {
    if (_databaseHelper != null) {
      await _databaseHelper!.deleteDatabase();
      _databaseHelper = null;
    }
  }
}

// Global instance of the LocalDatabase
final localDB = LocalDatabase();
