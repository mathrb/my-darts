// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:sqlite3/wasm.dart';
import 'drift_web_constants.dart';

Future<void> platformDownloadDatabase() async {
  final vfs = await IndexedDbFileSystem.open(dbName: kDriftWebDbName);

  if (vfs.xAccess(kDriftWebDbPath, 0) == 0) {
    await vfs.close();
    throw StateError('Database file not found in IndexedDB — has the app been run yet?');
  }

  final Uint8List bytes;
  try {
    final (:file, outFlags: _) = vfs.xOpen(Sqlite3Filename(kDriftWebDbPath), 0);
    bytes = Uint8List(file.xFileSize());
    file.xRead(bytes, 0);
    file.xClose();
  } finally {
    await vfs.close();
  }

  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute(
      'download',
      'darts_db_${DateTime.now().millisecondsSinceEpoch}.sqlite3',
    )
    ..click();
  html.Url.revokeObjectUrl(url);
}
