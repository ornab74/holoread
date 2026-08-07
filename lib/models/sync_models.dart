import 'book.dart';

class SyncConflict {
  const SyncConflict({
    required this.local,
    required this.remote,
    required this.reason,
  });

  final Book local;
  final Book remote;
  final String reason;
}

class SyncReport {
  const SyncReport({
    required this.pulled,
    required this.pushed,
    required this.skipped,
    required this.conflicts,
    required this.completedAt,
  });

  final int pulled;
  final int pushed;
  final int skipped;
  final List<SyncConflict> conflicts;
  final DateTime completedAt;
}
