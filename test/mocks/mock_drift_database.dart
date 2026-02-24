// Mock Drift Database for Testing
// Provides a test-friendly implementation without native dependencies

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:my_darts/core/persistence/drift/database.dart';

class MockDriftDatabase extends AppDatabase {
  MockDriftDatabase() : super(_openMockConnection());

  static QueryExecutor _openMockConnection() {
    // Use in-memory database for testing
    return NativeDatabase.memory();
  }
}