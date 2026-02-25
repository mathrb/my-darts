// Native Database Factory
// Platform-specific implementation for mobile and desktop platforms

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

Future<QueryExecutor> createDatabaseExecutor() async {
  // For testing, use in-memory database
  // In production, this would use a persistent database file
  final executor = NativeDatabase.memory();
  
  // Enable foreign key constraints as required by AGENTS.md
  await executor.runCustom('PRAGMA foreign_keys = ON;', []);
  
  return executor;
}
