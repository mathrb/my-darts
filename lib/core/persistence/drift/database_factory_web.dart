// Web Database Factory
// Platform-specific implementation for web platforms using SQLite WASM

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/foundation.dart';

Future<QueryExecutor> createDatabaseExecutor() async {
  // Use WasmDatabase for real SQLite in the browser
  // This provides cross-platform consistency with native SQLite
  final db = await WasmDatabase.open(
    databaseName: 'darts_db',
    sqlite3Uri: Uri.parse('sqlite3.wasm'),
    driftWorkerUri: Uri.parse('drift_worker.dart.js'),
  );

  if (db.missingFeatures.isNotEmpty) {
    // Log which storage features are unavailable in this browser
    // Drift automatically falls back to the best available backend
    debugPrint(
      'drift: running with degraded web features: ${db.missingFeatures}',
    );
  }

  // Return the resolved executor that uses the best available storage
  return db.resolvedExecutor;
}
