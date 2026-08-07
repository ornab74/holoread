import '../models/book.dart';
import '../models/reading_session.dart';

abstract interface class BookRepository {
  Stream<List<Book>> watchBooks();
  Future<List<Book>> listBooks({bool includeDeleted = false});
  Future<Book?> getBook(String id);
  Future<void> saveBook(Book book);
  Future<void> updateProgress(String id, int currentPage);
  Future<void> softDelete(String id);
  Future<List<ReadingSession>> listSessions({String? bookId});
  Future<void> addSession(ReadingSession session);
}
