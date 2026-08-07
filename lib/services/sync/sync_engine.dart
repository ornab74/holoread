import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../core/database/app_database.dart';
import '../../models/book.dart';
import '../../models/sync_models.dart';
import '../../repositories/book_repository.dart';
import 'google_sheets_service.dart';
import 'sheet_schema.dart';

class SyncEngine {
  const SyncEngine({required AppDatabase database, required BookRepository repository, required GoogleSheetsService sheetsService})
      : _database = database, _repository = repository, _sheetsService = sheetsService;

  final AppDatabase _database;
  final BookRepository _repository;
  final GoogleSheetsService _sheetsService;

  Future<SyncReport> synchronize(String spreadsheetId) async {
    final localBooks = await _repository.listBooks(includeDeleted: true);
    final remoteBooks = await _sheetsService.pullBooks(spreadsheetId);
    final localById = <String, Book>{for (final book in localBooks) book.id: book};
    final remoteById = <String, Book>{for (final book in remoteBooks) book.id: book};
    final ids = <String>{...localById.keys, ...remoteById.keys};
    final toPush = <Book>[];
    final conflicts = <SyncConflict>[];
    var pulled = 0;
    var skipped = 0;

    for (final id in ids) {
      final local = localById[id];
      final remote = remoteById[id];
      if (local == null && remote != null) {
        await _repository.saveBook(remote);
        _database.markSynced(id, remote.syncVersion, _hash(remote));
        pulled++;
        continue;
      }
      if (local != null && remote == null) { toPush.add(local); continue; }
      if (local == null || remote == null) continue;
      final localHash = _hash(local);
      final remoteHash = _hash(remote);
      if (localHash == remoteHash) {
        _database.markSynced(id, local.syncVersion, remoteHash);
        skipped++;
        continue;
      }
      final baseline = _database.lastSyncedVersion(id);
      final localChanged = local.syncVersion > baseline;
      final remoteChanged = remote.syncVersion > baseline;
      if (localChanged && remoteChanged) {
        conflicts.add(SyncConflict(local: local, remote: remote, reason: 'Both the encrypted local record and the sheet row changed after version $baseline.'));
      } else if (remoteChanged || remote.updatedAt.isAfter(local.updatedAt)) {
        await _repository.saveBook(remote);
        _database.markSynced(id, remote.syncVersion, remoteHash);
        pulled++;
      } else {
        toPush.add(local);
      }
    }

    await _sheetsService.upsertBooks(spreadsheetId, toPush);
    for (final book in toPush) {
      _database.markSynced(book.id, book.syncVersion, _hash(book));
    }
    return SyncReport(pulled: pulled, pushed: toPush.length, skipped: skipped, conflicts: conflicts, completedAt: DateTime.now());
  }

  String _hash(Book book) {
    final canonical = jsonEncode(SheetSchema.toRow(book));
    return sha256.convert(utf8.encode(canonical)).toString();
  }
}
