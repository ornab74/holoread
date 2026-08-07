import 'dart:async';

import '../core/database/app_database.dart';
import '../models/book.dart';
import '../models/reading_session.dart';
import 'book_repository.dart';

class SqliteBookRepository implements BookRepository {
  const SqliteBookRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<List<Book>> watchBooks() async* {
    yield _database.listBooks();
    await for (final _ in _database.changes) {
      yield _database.listBooks();
    }
  }

  @override
  Future<List<Book>> listBooks({bool includeDeleted = false}) async =>
      _database.listBooks(includeDeleted: includeDeleted);

  @override
  Future<Book?> getBook(String id) async => _database.getBook(id);

  @override
  Future<void> saveBook(Book book) async => _database.upsertBook(book);

  @override
  Future<void> updateProgress(String id, int currentPage) async {
    final existing = _database.getBook(id);
    if (existing == null) return;
    final safePage = existing.totalPages <= 0
        ? currentPage.clamp(0, 1000000).toInt()
        : currentPage.clamp(0, existing.totalPages).toInt();
    final completed = existing.totalPages > 0 && safePage >= existing.totalPages;
    _database.upsertBook(
      existing.copyWith(
        currentPage: safePage,
        status: completed ? BookStatus.completed : BookStatus.currentlyReading,
        dateStarted: existing.dateStarted ?? DateTime.now(),
        dateFinished: completed ? DateTime.now() : existing.dateFinished,
        updatedAt: DateTime.now(),
        syncVersion: existing.syncVersion + 1,
      ),
    );
  }

  @override
  Future<void> softDelete(String id) async {
    final existing = _database.getBook(id);
    if (existing == null) return;
    _database.upsertBook(
      existing.copyWith(
        isDeleted: true,
        updatedAt: DateTime.now(),
        syncVersion: existing.syncVersion + 1,
      ),
    );
  }

  @override
  Future<List<ReadingSession>> listSessions({String? bookId}) async =>
      _database.listSessions(bookId: bookId);

  @override
  Future<void> addSession(ReadingSession session) async =>
      _database.addSession(session);
}
