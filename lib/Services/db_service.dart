import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/Reminder.dart';

/// Service for managing local database operations
/// Uses SQLite via sqflite for persistent storage
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  static DatabaseService get instance => _instance;

  // Table and column names
  static const String tableName = 'reminders';
  static const String columnId = 'id';
  static const String columnTitle = 'title';
  static const String columnDescription = 'description';
  static const String columnReminderTime = 'reminderTime';
  static const String columnCategory = 'category';
  static const String columnIsCompleted = 'isCompleted';
  static const String columnCreatedAt = 'createdAt';

  /// Get database instance with lazy initialization
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    try {
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, 'reminder_app.db');

      return openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
    } catch (e) {
      debugPrint('❌ Error initializing database: $e');
      rethrow;
    }
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE $tableName (
          $columnId TEXT PRIMARY KEY,
          $columnTitle TEXT NOT NULL,
          $columnDescription TEXT NOT NULL,
          $columnReminderTime TEXT NOT NULL,
          $columnCategory TEXT NOT NULL,
          $columnIsCompleted INTEGER NOT NULL DEFAULT 0,
          $columnCreatedAt TEXT NOT NULL
        )
      ''');
      debugPrint('✅ Database table created successfully');
    } catch (e) {
      debugPrint('❌ Error creating database table: $e');
      rethrow;
    }
  }

  /// Insert a new reminder
  Future<void> insertReminder(Reminder reminder) async {
    try {
      final db = await database;
      await db.insert(
        tableName,
        reminder.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('✅ Reminder inserted: ${reminder.id}');
    } catch (e) {
      debugPrint('❌ Error inserting reminder: $e');
      rethrow;
    }
  }

  /// Get all reminders
  Future<List<Reminder>> getAllReminders() async {
    try {
      final db = await database;
      final maps = await db.query(
        tableName,
        orderBy: '$columnReminderTime ASC',
      );

      return List.generate(
        maps.length,
        (i) => Reminder.fromJson(maps[i]),
      );
    } catch (e) {
      debugPrint('❌ Error getting reminders: $e');
      return [];
    }
  }

  /// Get reminder by ID
  Future<Reminder?> getReminderById(String id) async {
    try {
      final db = await database;
      final maps = await db.query(
        tableName,
        where: '$columnId = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) return null;
      return Reminder.fromJson(maps.first);
    } catch (e) {
      debugPrint('❌ Error getting reminder: $e');
      return null;
    }
  }

  /// Update a reminder
  Future<void> updateReminder(Reminder reminder) async {
    try {
      final db = await database;
      await db.update(
        tableName,
        reminder.toJson(),
        where: '$columnId = ?',
        whereArgs: [reminder.id],
      );
      debugPrint('✅ Reminder updated: ${reminder.id}');
    } catch (e) {
      debugPrint('❌ Error updating reminder: $e');
      rethrow;
    }
  }

  /// Delete a reminder
  Future<void> deleteReminder(String id) async {
    try {
      final db = await database;
      await db.delete(
        tableName,
        where: '$columnId = ?',
        whereArgs: [id],
      );
      debugPrint('✅ Reminder deleted: $id');
    } catch (e) {
      debugPrint('❌ Error deleting reminder: $e');
      rethrow;
    }
  }

  /// Delete all reminders
  Future<void> deleteAllReminders() async {
    try {
      final db = await database;
      await db.delete(tableName);
      debugPrint('✅ All reminders deleted');
    } catch (e) {
      debugPrint('❌ Error deleting all reminders: $e');
      rethrow;
    }
  }

  /// Get reminders by category
  Future<List<Reminder>> getRemindersByCategory(String category) async {
    try {
      final db = await database;
      final maps = await db.query(
        tableName,
        where: '$columnCategory = ?',
        whereArgs: [category],
        orderBy: '$columnReminderTime ASC',
      );

      return List.generate(
        maps.length,
        (i) => Reminder.fromJson(maps[i]),
      );
    } catch (e) {
      debugPrint('❌ Error getting reminders by category: $e');
      return [];
    }
  }

  /// Get pending reminders (not completed)
  Future<List<Reminder>> getPendingReminders() async {
    try {
      final db = await database;
      final maps = await db.query(
        tableName,
        where: '$columnIsCompleted = ?',
        whereArgs: [0],
        orderBy: '$columnReminderTime ASC',
      );

      return List.generate(
        maps.length,
        (i) => Reminder.fromJson(maps[i]),
      );
    } catch (e) {
      debugPrint('❌ Error getting pending reminders: $e');
      return [];
    }
  }

  /// Close database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
      debugPrint('✅ Database closed');
    }
  }
}

void debugPrint(String message) {
  print(message);
}
