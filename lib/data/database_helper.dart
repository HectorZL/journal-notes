import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
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

  // Database version
  static const int _databaseVersion = 1;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'mood_notes.db');
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
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
        FOREIGN KEY ($columnUserId) REFERENCES $tableUsers ($columnId) ON DELETE CASCADE
      )
    ''');
  }

  // User CRUD Operations
  Future<int> insertUser(Map<String, dynamic> user) async {
    Database db = await database;
    // Hash password before storing
    user[columnPassword] = _hashPassword(user[columnPassword]);
    user[columnCreatedAt] = DateTime.now().toIso8601String();
    return await db.insert(tableUsers, user);
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    Database db = await database;
    List<Map> result = await db.query(
      tableUsers,
      where: '$columnEmail = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty ? result.first as Map<String, dynamic> : null;
  }

  Future<bool> validateUser(String email, String password) async {
    Database db = await database;
    List<Map> result = await db.query(
      tableUsers,
      where: '$columnEmail = ? AND $columnPassword = ?',
      whereArgs: [email, _hashPassword(password)],
    );
    return result.isNotEmpty;
  }

  // Notes CRUD Operations
  Future<int> insertNote(Map<String, dynamic> note) async {
    Database db = await database;
    return await db.insert(tableNotes, note);
  }

  Future<List<Map<String, dynamic>>> getNotes(int userId, {DateTime? date}) async {
    Database db = await database;
    if (date != null) {
      String dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
  }

  Future<int> updateNote(Map<String, dynamic> note) async {
    Database db = await database;
    return await db.update(
      tableNotes,
      note,
      where: '$columnNoteId = ?',
      whereArgs: [note[columnNoteId]],
    );
  }

  Future<int> deleteNote(int id) async {
    Database db = await database;
    return await db.delete(
      tableNotes,
      where: '$columnNoteId = ?',
      whereArgs: [id],
    );
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

  // Helper method to hash passwords
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Close the database when done
  Future<void> close() async {
    Database db = await database;
    await db.close();
  }
}
