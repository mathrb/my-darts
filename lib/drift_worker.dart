// Drift Web Worker
// Web worker implementation for SQLite WASM database operations

import 'package:drift/web/worker.dart';

/// Entry point for the Drift web worker
/// 
/// This function is called when the worker is initialized and sets up
/// the SQLite WASM database connection for use with Drift.
void main() => driftWorkerMain();
