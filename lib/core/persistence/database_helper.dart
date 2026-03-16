// Database Helper
// Singleton database access with SQLite for mobile platforms

import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:path/path.dart' as path;

import '../../core/utils/constants.dart';
import 'database_migrations.dart';

class DatabaseHelper {
  static sqflite.Database? _database;
  static final DatabaseHelper instance = DatabaseHelper._init();

  DatabaseHelper._init();

  Future<sqflite.Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(DatabaseConstants.databaseName);
    return _database!;
  }

  Future<sqflite.Database> _initDB(String filePath) async {
    final dbPath = await sqflite.getDatabasesPath();
    final fullPath = path.join(dbPath, filePath);

    return await sqflite.openDatabase(
      fullPath,
      version: DatabaseConstants.databaseVersion,
      onCreate: _createDB,
      onOpen: (db) async {
        // Enable foreign key constraints
        await db.execute('PRAGMA foreign_keys = ON;');
      },
    );
  }

  Future _createDB(sqflite.Database db, int version) async {
    await DatabaseMigrations.createSchema(db);
  }

  Future close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      for (final table in const [
        'sync_queue',
        'game_sessions',
        'dart_throws',
        'game_events',
        'competitor_players',
        'competitors',
        'games',
        'players',
        'accounts',
      ]) {
        await txn.execute('DELETE FROM $table;');
      }
    });
  }
}



extension DatabaseExceptionExtensions on sqflite.DatabaseException {
  bool isUniqueConstraintError() {
    return result == 1555 || // SQLITE_CONSTRAINT_PRIMARYKEY
        result == 2067 || // SQLITE_CONSTRAINT_UNIQUE
        toString().toLowerCase().contains('unique constraint failed') ||
        toString().toLowerCase().contains('primary key constraint failed');
  }

  bool isForeignKeyConstraintError() {
    return result == 787 || // SQLITE_CONSTRAINT_FOREIGNKEY
        toString().toLowerCase().contains('foreign key constraint failed');
  }
}
