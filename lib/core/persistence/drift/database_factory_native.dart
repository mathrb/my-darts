// Native Database Factory
// Platform-specific implementation for mobile and desktop platforms

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

Future<QueryExecutor> createDatabaseExecutor() async {
  // For testing, use in-memory database
  // In production, this would use a persistent database file
  return NativeDatabase.memory();
}
