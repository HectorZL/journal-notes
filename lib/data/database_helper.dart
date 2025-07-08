import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  // Singleton instance
  static final DatabaseHelper instance = DatabaseHelper._internal();
  
  // Database reference
  static Database? _database;

  // Table names
  static const String tableUsers = 'users';
  static const String tableNotes = 'notes';

  // User Table Columns
  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnEmail = 'email';
  static const String columnPassword = 'password';
  static const String columnCreatedAt = 'created_at';

  // Notes Table Columns
  static const String columnNoteId = 'note_id';
  static const String columnUserId = 'user_id';
  static const String columnMoodIndex = 'mood_index';
  static const String columnContent = 'content';
  static const String columnDate = 'date';
  static const String columnTags = 'tags';

  // Database version - increment this when changing the database schema
  static const int _databaseVersion = 2;
  
  // Database name
  static const String _databaseName = 'mood_notes.db';
  
  // Prevent direct instantiation
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    try {
      _database = await _initDatabase();
      return _database!;
    } catch (e) {
      debugPrint('Error initializing database: $e');
      rethrow;
    }
  }

  Future<Database> _initDatabase() async {
    try {
      // Get the databases path
      final databasesPath = await getDatabasesPath();
      debugPrint('Database path: $databasesPath');
      
      // Ensure the directory exists
      final dir = Directory(databasesPath);
      if (!await dir.exists()) {
        debugPrint('Creating database directory: $databasesPath');
        await dir.create(recursive: true);
      }
      
      final path = join(databasesPath, _databaseName);
      debugPrint('Full database path: $path');
      
      // Verify we can write to the directory
      try {
        final testFile = File('${dir.path}/test_write.tmp');
        await testFile.writeAsString('test');
        await testFile.delete();
        debugPrint('Successfully verified write permissions to directory');
      } catch (e) {
        debugPrint('Error writing to database directory: $e');
       
      }
      
      // Open the database
      debugPrint('Opening database at: $path');
      final db = await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
        onOpen: (db) {
          debugPrint('Database opened successfully at $path');
        },
      );
      
      debugPrint('Database opened successfully');
      return db;
    } catch (e, stackTrace) {
      debugPrint('Error initializing database: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  Future<void> _onConfigure(Database db) async {
    // Enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');
  }
  
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database schema upgrades here
    if (oldVersion < 2) {
      // Add color column to notes table
      await db.execute('ALTER TABLE $tableNotes ADD COLUMN color INTEGER DEFAULT 4278190080'); // Default to blue color
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create users table
    await db.execute('''
      CREATE TABLE $tableUsers (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnName TEXT NOT NULL,
        $columnEmail TEXT NOT NULL UNIQUE,
        $columnPassword TEXT NOT NULL,
        $columnCreatedAt TEXT NOT NULL
      )
    ''');

    // Create notes table
    await db.execute('''
      CREATE TABLE $tableNotes (
        $columnNoteId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnUserId INTEGER NOT NULL,
        $columnMoodIndex INTEGER NOT NULL,
        $columnContent TEXT,
        $columnDate TEXT NOT NULL,
        $columnTags TEXT,
        color INTEGER DEFAULT 4278190080,
        FOREIGN KEY ($columnUserId) REFERENCES $tableUsers ($columnId) ON DELETE CASCADE
      )
    ''');
  }

  // User CRUD Operations
  Future<int> insertUser(Map<String, dynamic> user) async {
    try {
      if (user[columnEmail] == null || user[columnPassword] == null) {
        throw ArgumentError('Email and password are required');
      }
      
      // Check if user already exists
      final existingUser = await getUserByEmail(user[columnEmail]);
      if (existingUser != null) {
        throw Exception('User with this email already exists');
      }
      
      final db = await database;
      // Hash password before storing
      user[columnPassword] = _hashPassword(user[columnPassword]);
      user[columnCreatedAt] = DateTime.now().toIso8601String();
      
      return await db.insert(
        tableUsers, 
        user,
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
    } catch (e) {
      debugPrint('Error inserting user: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      if (email.isEmpty) {
        throw ArgumentError('Email cannot be empty');
      }
      
      final db = await database;
      final result = await db.query(
        tableUsers,
        where: '$columnEmail = ?',
        whereArgs: [email],
      );
      
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      debugPrint('Error getting user by email: $e');
      rethrow;
    }
  }

  Future<bool> validateUser(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        debugPrint('Email or password is empty');
        return false;
      }
      
      final db = await database;
      
      // First check if user exists
      final user = await db.query(
        tableUsers,
        where: '$columnEmail = ?',
        whereArgs: [email],
      );
      
      if (user.isEmpty) {
        debugPrint('No user found with email: $email');
        return false;
      }
      
      // Then validate password
      final result = await db.query(
        tableUsers,
        columns: [columnId],
        where: '$columnEmail = ? AND $columnPassword = ?',
        whereArgs: [email, _hashPassword(password)],
      );
      
      if (result.isEmpty) {
        debugPrint('Invalid password for email: $email');
      }
      
      return result.isNotEmpty;
    } catch (e, stackTrace) {
      debugPrint('Error validating user: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  // Notes CRUD Operations
  Future<int> insertNote(Map<String, dynamic> note) async {
    try {
      if (note[columnUserId] == null || note[columnMoodIndex] == null) {
        throw ArgumentError('User ID and mood index are required');
      }
      
      final db = await database;
      note[columnDate] = note[columnDate] ?? DateTime.now().toIso8601String();
      
      return await db.insert(
        tableNotes, 
        note,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error inserting note: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getNotes(int userId, {DateTime? date}) async {
    try {
      final db = await database;
      
      if (date != null) {
        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        return await db.query(
          tableNotes,
          where: '$columnUserId = ? AND date($columnDate) = date(?)',
          whereArgs: [userId, dateStr],
        );
      }
      
      return await db.query(
        tableNotes,
        where: '$columnUserId = ?',
        whereArgs: [userId],
        orderBy: '$columnDate DESC',
      );
    } catch (e) {
      debugPrint('Error getting notes: $e');
      rethrow;
    }
  }

  Future<int> updateNote(Map<String, dynamic> note) async {
    try {
      if (note[columnNoteId] == null) {
        throw ArgumentError('Note ID is required for update');
      }
      
      final db = await database;
      note[columnDate] = note[columnDate] ?? DateTime.now().toIso8601String();
      
      return await db.update(
        tableNotes,
        note,
        where: '$columnNoteId = ?',
        whereArgs: [note[columnNoteId]],
      );
    } catch (e) {
      debugPrint('Error updating note: $e');
      rethrow;
    }
  }

  Future<int> deleteNote(int id) async {
    try {
      if (id <= 0) {
        throw ArgumentError('Invalid note ID');
      }
      
      final db = await database;
      return await db.delete(
        tableNotes,
        where: '$columnNoteId = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error deleting note: $e');
      rethrow;
    }
  }

  // Statistics
  Future<Map<String, dynamic>> getStats(int userId, {DateTime? startDate, DateTime? endDate}) async {
    Database db = await database;
    
    String whereClause = '$columnUserId = ?';
    List<dynamic> whereArgs = [userId];
    
    if (startDate != null && endDate != null) {
      whereClause += ' AND $columnDate BETWEEN ? AND ?';
      whereArgs.addAll([startDate.toIso8601String(), endDate.toIso8601String()]);
    }
    
    // Get mood distribution
    final moodCounts = await db.rawQuery('''
      SELECT $columnMoodIndex, COUNT(*) as count 
      FROM $tableNotes 
      WHERE $whereClause
      GROUP BY $columnMoodIndex
    ''', whereArgs);

    // Get notes per day
    final notesPerDay = await db.rawQuery('''
      SELECT date($columnDate) as day, COUNT(*) as count
      FROM $tableNotes
      WHERE $whereClause
      GROUP BY day
      ORDER BY day DESC
    ''', whereArgs);

    return {
      'moodDistribution': moodCounts,
      'notesPerDay': notesPerDay,
    };
  }

  // Helper method to hash passwords with salt
  String _hashPassword(String password) {
    try {
      // In a production app, you should use a unique salt per user
      const salt = 'your_salt_here'; // Consider using a secure random salt
      final key = utf8.encode(password + salt);
      final bytes = sha256.convert(key);
      return bytes.toString();
    } catch (e) {
      debugPrint('Error hashing password: $e');
      rethrow;
    }
  }

  // Close the database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
  
  // Delete the database file and recreate it
  Future<void> deleteDatabase() async {
    try {
      await close();
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _databaseName);
      
      // Check if the database file exists
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        debugPrint('Database file deleted: $path');
      } else {
        debugPrint('Database file does not exist: $path');
      }
      
      // Reinitialize the database
      _database = await _initDatabase();
      debugPrint('Database reinitialized after deletion');
    } catch (e, stackTrace) {
      debugPrint('Error deleting and recreating database: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
