Future<void> platformDownloadDatabase() async {
  throw UnsupportedError(
    'Database download is only implemented for the web build. On native '
    'targets the SQLite file lives at the platform app-documents path; '
    'use the OS file-share/export flow instead.',
  );
}
