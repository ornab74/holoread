import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../models/book.dart';
import '../../models/reading_session.dart';
import '../config/app_config.dart';

class AppDatabase {
  AppDatabase._(this._db);

  final Database _db;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  static Future<AppDatabase> open() async {
    final directory = await getApplicationSupportDirectory();
    final databasePath = p.join(directory.path, AppConfig.databaseName);

    final db = sqlite3.open(databasePath);
    db.execute('PRAGMA foreign_keys = ON;');
    db.execute('PRAGMA journal_mode = WAL;');
    db.execute('PRAGMA synchronous = NORMAL;');

    final instance = AppDatabase._(db);
    instance._migrate();
    await instance._seedIfEmpty();
    return instance;
  }

  Stream<void> get changes => _changes.stream;

  void _migrate() {
    final version = _db.userVersion;
    if (version < 1) {
      _db.execute('''
        CREATE TABLE books (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          author TEXT NOT NULL,
          series TEXT,
          series_number REAL,
          isbn10 TEXT,
          isbn13 TEXT,
          status TEXT NOT NULL,
          date_added TEXT NOT NULL,
          date_started TEXT,
          date_finished TEXT,
          current_page INTEGER NOT NULL DEFAULT 0,
          total_pages INTEGER NOT NULL DEFAULT 0,
          priority INTEGER NOT NULL DEFAULT 3,
          rating REAL,
          genres_json TEXT NOT NULL DEFAULT '[]',
          tags_json TEXT NOT NULL DEFAULT '[]',
          format TEXT NOT NULL DEFAULT 'Unknown',
          language TEXT NOT NULL DEFAULT 'English',
          difficulty TEXT NOT NULL DEFAULT 'Medium',
          reading_goal TEXT NOT NULL DEFAULT '',
          estimated_minutes INTEGER NOT NULL DEFAULT 0,
          reminder_preference TEXT NOT NULL DEFAULT 'Smart',
          notes TEXT NOT NULL DEFAULT '',
          quotes_json TEXT NOT NULL DEFAULT '[]',
          recommendation_source TEXT NOT NULL DEFAULT '',
          updated_at TEXT NOT NULL,
          sync_version INTEGER NOT NULL DEFAULT 1,
          is_deleted INTEGER NOT NULL DEFAULT 0
        );
      ''');
      _db.execute('CREATE INDEX idx_books_status ON books(status);');
      _db.execute('CREATE INDEX idx_books_updated ON books(updated_at);');
      _db.execute('CREATE INDEX idx_books_isbn13 ON books(isbn13);');

      _db.execute('''
        CREATE TABLE reading_sessions (
          id TEXT PRIMARY KEY,
          book_id TEXT NOT NULL,
          started_at TEXT NOT NULL,
          ended_at TEXT NOT NULL,
          pages_read INTEGER NOT NULL,
          minutes_read INTEGER NOT NULL,
          mood TEXT NOT NULL,
          location_category TEXT NOT NULL,
          focus_score INTEGER NOT NULL,
          notes TEXT NOT NULL,
          FOREIGN KEY(book_id) REFERENCES books(id) ON DELETE CASCADE
        );
      ''');
      _db.execute('CREATE INDEX idx_sessions_book ON reading_sessions(book_id);');
      _db.execute('CREATE INDEX idx_sessions_start ON reading_sessions(started_at);');

      _db.execute('''
        CREATE TABLE reminders (
          id TEXT PRIMARY KEY,
          book_id TEXT,
          reminder_type TEXT NOT NULL,
          scheduled_at TEXT NOT NULL,
          recurrence_rule TEXT,
          snooze_count INTEGER NOT NULL DEFAULT 0,
          is_completed INTEGER NOT NULL DEFAULT 0,
          adaptive_weight REAL NOT NULL DEFAULT 1.0,
          last_interaction TEXT,
          notification_id INTEGER NOT NULL,
          FOREIGN KEY(book_id) REFERENCES books(id) ON DELETE CASCADE
        );
      ''');

      _db.execute('''
        CREATE TABLE recommendation_feedback (
          id TEXT PRIMARY KEY,
          book_id TEXT NOT NULL,
          feedback TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY(book_id) REFERENCES books(id) ON DELETE CASCADE
        );
      ''');

      _db.execute('''
        CREATE TABLE sync_journal (
          entity_id TEXT PRIMARY KEY,
          last_synced_version INTEGER NOT NULL DEFAULT 0,
          last_remote_hash TEXT,
          synced_at TEXT
        );
      ''');

      _db.execute('''
        CREATE TABLE settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        );
      ''');
      _db.userVersion = AppConfig.databaseSchemaVersion;
    }
  }

  Future<void> _seedIfEmpty() async {
    final count = _db.select('SELECT COUNT(*) AS count FROM books;').first['count'] as int;
    if (count > 0) return;
    final now = DateTime.now();
    final samples = <Book>[
      Book(
        id: 'demo-dune',
        title: 'Dune',
        author: 'Frank Herbert',
        status: BookStatus.currentlyReading,
        dateAdded: now.subtract(const Duration(days: 20)),
        dateStarted: now.subtract(const Duration(days: 8)),
        currentPage: 186,
        totalPages: 688,
        priority: 5,
        rating: 4.8,
        genres: const <String>['Science Fiction', 'Politics', 'Adventure'],
        tags: const <String>['world-building', 'classic'],
        estimatedMinutes: 920,
        readingGoal: 'Finish this month',
        updatedAt: now,
      ),
      Book(
        id: 'demo-left-hand',
        title: 'The Left Hand of Darkness',
        author: 'Ursula K. Le Guin',
        status: BookStatus.wishlist,
        dateAdded: now.subtract(const Duration(days: 12)),
        totalPages: 304,
        priority: 4,
        genres: const <String>['Science Fiction', 'Society'],
        tags: const <String>['classic', 'thoughtful'],
        estimatedMinutes: 430,
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      Book(
        id: 'demo-atomic-habits',
        title: 'Atomic Habits',
        author: 'James Clear',
        status: BookStatus.completed,
        dateAdded: now.subtract(const Duration(days: 120)),
        dateStarted: now.subtract(const Duration(days: 80)),
        dateFinished: now.subtract(const Duration(days: 60)),
        currentPage: 320,
        totalPages: 320,
        priority: 3,
        rating: 4.6,
        genres: const <String>['Self Development', 'Psychology'],
        tags: const <String>['habits', 'practical'],
        estimatedMinutes: 410,
        updatedAt: now.subtract(const Duration(days: 60)),
      ),
      Book(
        id: 'demo-deep-work',
        title: 'Deep Work',
        author: 'Cal Newport',
        status: BookStatus.planned,
        dateAdded: now.subtract(const Duration(days: 30)),
        totalPages: 296,
        priority: 4,
        genres: const <String>['Productivity', 'Psychology'],
        tags: const <String>['focus', 'work'],
        estimatedMinutes: 380,
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
    ];
    for (final book in samples) {
      upsertBook(book, notify: false);
    }
    _notify();
  }

  List<Book> listBooks({bool includeDeleted = false}) {
    final rows = _db.select(
      'SELECT * FROM books ${includeDeleted ? '' : 'WHERE is_deleted = 0'} '
      'ORDER BY priority DESC, updated_at DESC;',
    );
    return rows.map(_bookFromRow).toList(growable: false);
  }

  Book? getBook(String id) {
    final rows = _db.select('SELECT * FROM books WHERE id = ?;', <Object?>[id]);
    return rows.isEmpty ? null : _bookFromRow(rows.first);
  }

  void upsertBook(Book book, {bool notify = true}) {
    _db.execute('''
      INSERT INTO books (
        id, title, author, series, series_number, isbn10, isbn13, status,
        date_added, date_started, date_finished, current_page, total_pages,
        priority, rating, genres_json, tags_json, format, language, difficulty,
        reading_goal, estimated_minutes, reminder_preference, notes, quotes_json,
        recommendation_source, updated_at, sync_version, is_deleted
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        title=excluded.title, author=excluded.author, series=excluded.series,
        series_number=excluded.series_number, isbn10=excluded.isbn10,
        isbn13=excluded.isbn13, status=excluded.status,
        date_added=excluded.date_added, date_started=excluded.date_started,
        date_finished=excluded.date_finished, current_page=excluded.current_page,
        total_pages=excluded.total_pages, priority=excluded.priority,
        rating=excluded.rating, genres_json=excluded.genres_json,
        tags_json=excluded.tags_json, format=excluded.format,
        language=excluded.language, difficulty=excluded.difficulty,
        reading_goal=excluded.reading_goal,
        estimated_minutes=excluded.estimated_minutes,
        reminder_preference=excluded.reminder_preference, notes=excluded.notes,
        quotes_json=excluded.quotes_json,
        recommendation_source=excluded.recommendation_source,
        updated_at=excluded.updated_at, sync_version=excluded.sync_version,
        is_deleted=excluded.is_deleted;
    ''', <Object?>[
      book.id,
      book.title,
      book.author,
      book.series,
      book.seriesNumber,
      book.isbn10,
      book.isbn13,
      book.status.label,
      book.dateAdded.toUtc().toIso8601String(),
      book.dateStarted?.toUtc().toIso8601String(),
      book.dateFinished?.toUtc().toIso8601String(),
      book.currentPage,
      book.totalPages,
      book.priority,
      book.rating,
      jsonEncode(book.genres),
      jsonEncode(book.tags),
      book.format,
      book.language,
      book.difficulty,
      book.readingGoal,
      book.estimatedMinutes,
      book.reminderPreference,
      book.notes,
      jsonEncode(book.favoriteQuotes),
      book.recommendationSource,
      book.updatedAt.toUtc().toIso8601String(),
      book.syncVersion,
      book.isDeleted ? 1 : 0,
    ]);
    if (notify) _notify();
  }

  List<ReadingSession> listSessions({String? bookId}) {
    final rows = bookId == null
        ? _db.select('SELECT * FROM reading_sessions ORDER BY started_at DESC;')
        : _db.select(
            'SELECT * FROM reading_sessions WHERE book_id = ? ORDER BY started_at DESC;',
            <Object?>[bookId],
          );
    return rows
        .map(
          (row) => ReadingSession(
            id: row['id'] as String,
            bookId: row['book_id'] as String,
            startedAt: DateTime.parse(row['started_at'] as String).toLocal(),
            endedAt: DateTime.parse(row['ended_at'] as String).toLocal(),
            pagesRead: row['pages_read'] as int,
            minutesRead: row['minutes_read'] as int,
            mood: row['mood'] as String,
            locationCategory: row['location_category'] as String,
            focusScore: row['focus_score'] as int,
            notes: row['notes'] as String,
          ),
        )
        .toList(growable: false);
  }

  void addSession(ReadingSession session) {
    _db.execute('''
      INSERT INTO reading_sessions (
        id, book_id, started_at, ended_at, pages_read, minutes_read, mood,
        location_category, focus_score, notes
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    ''', <Object?>[
      session.id,
      session.bookId,
      session.startedAt.toUtc().toIso8601String(),
      session.endedAt.toUtc().toIso8601String(),
      session.pagesRead,
      session.minutesRead,
      session.mood,
      session.locationCategory,
      session.focusScore,
      session.notes,
    ]);
    _notify();
  }

  int lastSyncedVersion(String entityId) {
    final rows = _db.select(
      'SELECT last_synced_version FROM sync_journal WHERE entity_id = ?;',
      <Object?>[entityId],
    );
    return rows.isEmpty ? 0 : rows.first['last_synced_version'] as int;
  }

  void markSynced(String entityId, int version, String remoteHash) {
    _db.execute('''
      INSERT INTO sync_journal(entity_id, last_synced_version, last_remote_hash, synced_at)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(entity_id) DO UPDATE SET
        last_synced_version=excluded.last_synced_version,
        last_remote_hash=excluded.last_remote_hash,
        synced_at=excluded.synced_at;
    ''', <Object?>[
      entityId,
      version,
      remoteHash,
      DateTime.now().toUtc().toIso8601String(),
    ]);
  }

  String? getSetting(String key) {
    final rows = _db.select('SELECT value FROM settings WHERE key = ?;', <Object?>[key]);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  void setSetting(String key, String value) {
    _db.execute('''
      INSERT INTO settings(key, value) VALUES (?, ?)
      ON CONFLICT(key) DO UPDATE SET value=excluded.value;
    ''', <Object?>[key, value]);
    _notify();
  }

  Book _bookFromRow(Row row) {
    List<String> decodeList(Object? value) {
      if (value is! String || value.isEmpty) return const <String>[];
      return (jsonDecode(value) as List<dynamic>).cast<String>();
    }

    DateTime? optionalDate(Object? value) =>
        value is String && value.isNotEmpty ? DateTime.parse(value).toLocal() : null;

    return Book(
      id: row['id'] as String,
      title: row['title'] as String,
      author: row['author'] as String,
      series: row['series'] as String?,
      seriesNumber: (row['series_number'] as num?)?.toDouble(),
      isbn10: row['isbn10'] as String?,
      isbn13: row['isbn13'] as String?,
      status: BookStatus.parse(row['status'] as String?),
      dateAdded: DateTime.parse(row['date_added'] as String).toLocal(),
      dateStarted: optionalDate(row['date_started']),
      dateFinished: optionalDate(row['date_finished']),
      currentPage: row['current_page'] as int,
      totalPages: row['total_pages'] as int,
      priority: row['priority'] as int,
      rating: (row['rating'] as num?)?.toDouble(),
      genres: decodeList(row['genres_json']),
      tags: decodeList(row['tags_json']),
      format: row['format'] as String,
      language: row['language'] as String,
      difficulty: row['difficulty'] as String,
      readingGoal: row['reading_goal'] as String,
      estimatedMinutes: row['estimated_minutes'] as int,
      reminderPreference: row['reminder_preference'] as String,
      notes: row['notes'] as String,
      favoriteQuotes: decodeList(row['quotes_json']),
      recommendationSource: row['recommendation_source'] as String,
      updatedAt: DateTime.parse(row['updated_at'] as String).toLocal(),
      syncVersion: row['sync_version'] as int,
      isDeleted: (row['is_deleted'] as int) == 1,
    );
  }

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  void dispose() {
    _changes.close();
    _db.close();
  }
}
