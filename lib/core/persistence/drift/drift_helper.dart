// Drift Database Helper
// Singleton database access for web platforms

import 'package:drift/native.dart';
import 'database.dart';

class DriftHelper {
  static AppDatabase? _database;
  static final DriftHelper instance = DriftHelper._init();

  DriftHelper._init();

  Future<AppDatabase> get database async {
    if (_database != null) return _database!;
    // For testing purposes, use in-memory database
    // In production, this would use WasmDatabase for web
    _database = AppDatabase(NativeDatabase.memory());
    return _database!;
  }

  Future close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}