import 'dart:math';

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
  static const String tableFaceAuth = 'face_auth';

  // User Table Columns
  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnEmail = 'email';
  static const String columnPassword = 'password';
  static const String columnProfilePicture = 'profile_picture';
  static const String columnCreatedAt = 'created_at';

  // Notes Table Columns
  static const String columnNoteId = 'note_id';
  static const String columnUserId = 'user_id';
  static const String columnMoodIndex = 'mood_index';
  static const String columnContent = 'content';
  static const String columnDate = 'date';
  static const String columnTags = 'tags';
  static const String columnColor = 'color';

  // Face Authentication Table Columns
  static const String columnDescriptorPath = 'descriptor_path';

  // Database version - increment this when changing the database schema
  static const int _databaseVersion = 5;
  
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
    debugPrint('Upgrading database from version $oldVersion to $newVersion');
    
    if (oldVersion < 2) {
      // Add any necessary migrations for version 2
      await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_user_date ON $tableNotes($columnUserId, $columnDate)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_date ON $tableNotes($columnDate)');
      
      // Migrate existing passwords to use salt
      await migratePasswordsToUseSalt();
    }
    
    if (oldVersion < 3) {
      // Add color column to notes table
      try {
        await db.execute('ALTER TABLE $tableNotes ADD COLUMN color TEXT');
        debugPrint('Successfully added color column to notes table');
      } catch (e) {
        debugPrint('Error adding color column: $e');
        // If the column already exists, we can ignore the error
        if (!e.toString().contains('duplicate column name')) {
          rethrow;
        }
      }
    }
    
    if (oldVersion < 4) {
      // Add profile picture column to users table
      try {
        await db.execute('ALTER TABLE $tableUsers ADD COLUMN $columnProfilePicture TEXT');
        debugPrint('Successfully added profile_picture column to users table');
      } catch (e) {
        debugPrint('Error adding profile_picture column: $e');
        if (!e.toString().contains('duplicate column name')) {
          rethrow;
        }
      }
    }
    
    if (oldVersion < 5) {
      // Create face authentication table
      await db.execute('''
        CREATE TABLE $tableFaceAuth (
          $columnUserId INTEGER PRIMARY KEY,
          email TEXT NOT NULL,
          $columnDescriptorPath TEXT NOT NULL,
          $columnCreatedAt TEXT NOT NULL DEFAULT (datetime('now','localtime'))
        )
      ''');
    }
    
    debugPrint('Database upgrade completed');
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('Creating database tables');
    
    // Create users table
    await db.execute('''
      CREATE TABLE $tableUsers (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnName TEXT NOT NULL,
        $columnEmail TEXT UNIQUE NOT NULL,
        $columnPassword TEXT NOT NULL,
        $columnProfilePicture TEXT,
        $columnCreatedAt TEXT NOT NULL DEFAULT (datetime('now','localtime'))
      )
    ''');

    // Create notes table
    await db.execute('''
      CREATE TABLE $tableNotes (
        $columnNoteId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnUserId INTEGER NOT NULL,
        $columnMoodIndex INTEGER NOT NULL,
        $columnContent TEXT NOT NULL,
        $columnDate TEXT NOT NULL,
        $columnTags TEXT,
        $columnColor TEXT,
        FOREIGN KEY ($columnUserId) REFERENCES $tableUsers ($columnId) ON DELETE CASCADE
      )
    ''');
    
    // Create face authentication table
    await db.execute('''
      CREATE TABLE $tableFaceAuth (
        $columnUserId INTEGER PRIMARY KEY,
        email TEXT NOT NULL,
        $columnDescriptorPath TEXT NOT NULL,
        $columnCreatedAt TEXT NOT NULL DEFAULT (datetime('now','localtime'))
      )
    ''');
    
    // Create indexes
    await db.execute('CREATE INDEX idx_notes_user_date ON $tableNotes($columnUserId, $columnDate)');
    await db.execute('CREATE INDEX idx_notes_date ON $tableNotes($columnDate)');
    
    debugPrint('Database tables created successfully');
  }

  // User CRUD Operations
  Future<int> insertUser(Map<String, dynamic> user) async {
    try {
      if (user[columnEmail] == null || user[columnPassword] == null) {
        throw ArgumentError('Email and password are required');
      }
      
      final db = await database;
      
      // Generate a unique salt for this user
      final salt = _generateSalt();
      
      // Hash password with the generated salt
      user[columnPassword] = _hashPasswordWithSalt(user[columnPassword], salt);
      
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

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      if (userId.isEmpty) {
        throw ArgumentError('User ID cannot be empty');
      }
      
      final db = await database;
      final result = await db.query(
        tableUsers,
        where: '$columnId = ?',
        whereArgs: [int.tryParse(userId) ?? 0],
      );
      
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      debugPrint('Error getting user by ID: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserByName(String name) async {
    try {
      if (name.isEmpty) {
        throw ArgumentError('Name cannot be empty');
      }
      
      final db = await database;
      final result = await db.query(
        tableUsers,
        where: '$columnName = ?',
        whereArgs: [name],
      );
      
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      debugPrint('Error getting user by name: $e');
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
      
      // Extract stored hash and salt
      final storedPassword = user.first[columnPassword] as String?;
      if (storedPassword == null) {
        debugPrint('No password found for user');
        return false;
      }
      final hashAndSalt = _extractHashAndSalt(storedPassword);
      
      // Hash provided password with the stored salt
      final providedHash = _hashPasswordWithSalt(password, hashAndSalt['salt']!);
      
      // Compare the hashes
      return providedHash == storedPassword;
    } catch (e, stackTrace) {
      debugPrint('Error validating user: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  Future<int> updateUser(int userId, {
    String? name,
    String? email,
    String? password,
    String? profilePicture, String? profileImage,
  }) async {
    try {
      final db = await database;
      final data = <String, dynamic>{};
      
      if (name != null) data[columnName] = name;
      if (email != null) {
        // Check if email is already in use by another user
        final existingUser = await getUserByEmail(email);
        if (existingUser != null && existingUser[columnId] != userId) {
          throw Exception('El correo electrónico ya está en uso por otra cuenta');
        }
        data[columnEmail] = email;
      }
      if (password != null) {
        final salt = _generateSalt();
        data[columnPassword] = _hashPasswordWithSalt(password, salt);
      }
      if (profilePicture != null) data[columnProfilePicture] = profilePicture;
      
      if (data.isEmpty) return 0; // No updates needed
      
      return await db.update(
        tableUsers,
        data,
        where: '$columnId = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }

  Future<bool> deleteUser(int userId) async {
    try {
      if (userId <= 0) {
        throw ArgumentError('Invalid user ID');
      }
      
      final db = await database;
      final count = await db.delete(
        tableUsers,
        where: '$columnId = ?',
        whereArgs: [userId],
      );
      
      return count > 0;
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
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
      if (userId <= 0) {
        throw ArgumentError('Invalid user ID: $userId');
      }
      
      final db = await database;
      debugPrint('Fetching notes for user ID: $userId' + (date != null ? ' on date: $date' : ''));
      
      if (date != null) {
        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final notes = await db.query(
          tableNotes,
          where: '$columnUserId = ? AND date($columnDate) = date(?)',
          whereArgs: [userId, dateStr],
        );
        debugPrint('Found ${notes.length} notes for the specified date');
        return notes;
      }
      
      final notes = await db.query(
        tableNotes,
        where: '$columnUserId = ?',
        whereArgs: [userId],
        orderBy: '$columnDate DESC',
      );
      
      debugPrint('Successfully loaded ${notes.length} notes for user ID: $userId');
      return notes;
    } catch (e, stackTrace) {
      debugPrint('Error in getNotes: $e\n$stackTrace');
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

  Future<int> deleteNote(int noteId) async {
    try {
      final db = await database;
      debugPrint('Deleting note with ID: $noteId');
      final result = await db.delete(
        tableNotes,
        where: '$columnNoteId = ?',
        whereArgs: [noteId],
      );
      debugPrint('Successfully deleted $result note(s)');
      return result;
    } catch (e) {
      debugPrint('Error deleting note: $e');
      rethrow;
    }
  }

  Future<int> deleteNoteWithUserId(int id, {required int userId}) async {
    try {
      if (id <= 0 || userId <= 0) {
        throw ArgumentError('Invalid note ID or user ID');
      }
      
      final db = await database;
      return await db.delete(
        tableNotes,
        where: '$columnNoteId = ? AND $columnUserId = ?',
        whereArgs: [id, userId],
      );
    } catch (e) {
      debugPrint('Error deleting note: $e');
      rethrow;
    }
  }

  /// Deletes all notes for a specific user
  Future<int> deleteAllNotesForUser(int userId) async {
    try {
      if (userId <= 0) {
        throw ArgumentError('Invalid user ID');
      }
      
      final db = await database;
      return await db.delete(
        tableNotes,
        where: '$columnUserId = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      debugPrint('Error deleting all notes for user: $e');
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

  // Migrate existing users to use password hashes with salt
  Future<void> migratePasswordsToUseSalt() async {
    try {
      final db = await database;
      final users = await db.query(tableUsers);
      
      for (var user in users) {
        final password = user[columnPassword] as String?;
        if (password != null && !password.contains(':')) {
          debugPrint('Migrating password for user ID: ${user[columnId]}');
          
          // Generate a new salt and create the new hash
          final salt = _generateSalt();
          final newHash = _hashPasswordWithSalt(password, salt);
          
          // Update the user with the new hashed password
          await db.update(
            tableUsers,
            {columnPassword: newHash},
            where: '$columnId = ?',
            whereArgs: [user[columnId]],
          );
          
          debugPrint('Successfully migrated password for user ID: ${user[columnId]}');
        }
      }
      
      debugPrint('Password migration completed successfully');
    } catch (e, stackTrace) {
      debugPrint('Error during password migration: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Generate a unique salt for each user
  String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(saltBytes);
  }

  // Hash password with user-specific salt
  String _hashPasswordWithSalt(String password, String salt) {
    try {
      final key = utf8.encode(password + salt);
      final bytes = sha256.convert(key);
      return '${bytes.toString()}:$salt'; // Store hash and salt together
    } catch (e) {
      debugPrint('Error hashing password: $e');
      rethrow;
    }
  }

  // Extract hash and salt from stored value
  Map<String, String> _extractHashAndSalt(String storedPassword) {
    final parts = storedPassword.split(':');
    if (parts.length != 2) {
      // For backward compatibility with existing passwords
      return {'hash': storedPassword, 'salt': ''};
    }
    return {'hash': parts[0], 'salt': parts[1]};
  }

  // Verificar el estado de la base de datos
  Future<Map<String, dynamic>> checkDatabaseStatus() async {
    try {
      final db = await database;
      
      // Verificar si la tabla de notas existe
      final notesTable = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableNotes'"
      );
      
      // Verificar si la tabla de usuarios existe
      final usersTable = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableUsers'"
      );
      
      // Verificar si la tabla de autenticación facial existe
      final faceAuthTable = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableFaceAuth'"
      );
      
      // Verificar restricciones de clave foránea
      final foreignKeys = await db.rawQuery('PRAGMA foreign_keys');
      
      // Obtener información de la base de datos
      final dbInfo = await db.rawQuery('PRAGMA database_list');
      
      return {
        'database_path': db.path,
        'notes_table_exists': notesTable.isNotEmpty,
        'users_table_exists': usersTable.isNotEmpty,
        'face_auth_table_exists': faceAuthTable.isNotEmpty,
        'foreign_keys_enabled': foreignKeys.first['foreign_keys'] == 1,
        'database_info': dbInfo,
        'is_database_open': db.isOpen,
      };
    } catch (e) {
      debugPrint('Error al verificar el estado de la base de datos: $e');
      rethrow;
    }
  }
  
  // Cerrar la base de datos correctamente
  Future<void> closeDatabase() async {
    try {
      final db = await database;
      if (db.isOpen) {
        await db.close();
        _database = null;
        debugPrint('Base de datos cerrada correctamente');
      }
    } catch (e) {
      debugPrint('Error al cerrar la base de datos: $e');
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

  // Create face authentication record
  Future<int> insertFaceAuthData({
    required String userId,
    required String email,
    required String descriptorPath,
  }) async {
    try {
      final db = await database;
      
      // First check if user already has a face auth record
      final existing = await db.query(
        tableFaceAuth,
        where: '$columnUserId = ?',
        whereArgs: [userId],
      );
      
      final data = {
        columnUserId: userId,
        'email': email,
        columnDescriptorPath: descriptorPath,
        columnCreatedAt: DateTime.now().toIso8601String(),
      };
      
      if (existing.isEmpty) {
        // Insert new record
        return await db.insert(
          tableFaceAuth,
          data,
          conflictAlgorithm: ConflictAlgorithm.fail,
        );
      } else {
        // Update existing record
        return await db.update(
          tableFaceAuth,
          data,
          where: '$columnUserId = ?',
          whereArgs: [userId],
        );
      }
    } catch (e) {
      debugPrint('Error saving face auth data: $e');
      rethrow;
    }
  }
}
