// Native Database Factory
// Opens a persisted drift database on Android/iOS/desktop using a file in
// the application documents directory.
//
// `NativeDatabase.createInBackground` runs the database on a background
// isolate so that schema work (and future heavy queries) don't block the UI.
//
// Android note: on devices where the system `libsqlite3.so` isn't loadable
// (Android 6/7 in particular, but also intermittently on later versions),
// `DynamicLibrary.open('libsqlite3.so')` fails with "Failed to load dynamic
// library". `sqlite3_flutter_libs` ships a bundled `.so` per ABI; the call to
// `applyWorkaroundToOpenSqlite3OnOldAndroidVersions` forces a Java-side load
// of that bundled lib so the Dart FFI lookup succeeds. We run it in both the
// main isolate (so the MethodChannel fallback is available) and inside
// `isolateSetup` (so the spawned drift isolate finds the already-loaded lib).

import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'package:dart_lodge/core/utils/constants.dart';

Future<QueryExecutor> createDatabaseExecutor() async {
  if (Platform.isAndroid) {
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
  }

  final dir = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, DatabaseConstants.databaseName));

  return NativeDatabase.createInBackground(
    file,
    isolateSetup: _backgroundIsolateSetup,
  );
}

// Runs inside the drift background isolate. The main isolate has already
// triggered the Java-side load (process-wide), so a plain `DynamicLibrary.open`
// is enough here — no MethodChannel needed (and unavailable in a raw spawn).
Future<void> _backgroundIsolateSetup() async {
  if (!Platform.isAndroid) return;
  try {
    DynamicLibrary.open('libsqlite3.so');
  } catch (_) {
    // If this throws, the subsequent sqlite3 call will surface a clearer error.
  }
}
