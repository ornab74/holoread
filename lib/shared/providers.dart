import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../models/book.dart';
import '../models/reading_session.dart';
import '../models/recommendation.dart';
import '../models/user_preferences.dart';
import '../repositories/book_repository.dart';
import '../repositories/sqlite_book_repository.dart';
import '../services/recommendations/mechanis_engine.dart';
import '../services/reminders/adaptive_reminder_engine.dart';
import '../services/reminders/notification_service.dart';
import '../services/sync/google_auth_service.dart';
import '../services/sync/google_sheets_service.dart';
import '../services/sync/sync_engine.dart';

final databaseProvider = FutureProvider<AppDatabase>((ref) async {
  final database = await AppDatabase.open();
  ref.onDispose(database.dispose);
  return database;
});

final bookRepositoryProvider = FutureProvider<BookRepository>((ref) async {
  final database = await ref.watch(databaseProvider.future);
  return SqliteBookRepository(database);
});

final booksProvider = StreamProvider<List<Book>>((ref) async* {
  final repository = await ref.watch(bookRepositoryProvider.future);
  yield* repository.watchBooks();
});

final sessionsProvider = StreamProvider<List<ReadingSession>>((ref) async* {
  final database = await ref.watch(databaseProvider.future);
  yield database.listSessions();
  await for (final _ in database.changes) {
    yield database.listSessions();
  }
});

final userPreferencesProvider = Provider<UserPreferences>((ref) {
  return const UserPreferences(
    preferredGenres: <String>['Science Fiction', 'Psychology', 'Technology'],
    favoriteAuthors: <String>[],
    preferredBookLength: 360,
    learningGoal: 'Build deeper focus and understand intelligent systems',
  );
});

final mechanisProvider = Provider<MechanisEngine>((ref) => const MechanisEngine());

final recommendationModeProvider = NotifierProvider<RecommendationModeController, RecommendationMode>(RecommendationModeController.new);

class RecommendationModeController extends Notifier<RecommendationMode> {
  @override
  RecommendationMode build() => RecommendationMode.continueJourney;

  void select(RecommendationMode mode) => state = mode;
}

final recommendationsProvider = Provider<AsyncValue<List<Recommendation>>>((ref) {
  final books = ref.watch(booksProvider);
  final mode = ref.watch(recommendationModeProvider);
  return books.whenData((library) => ref.read(mechanisProvider).recommend(library: library, preferences: ref.read(userPreferencesProvider), mode: mode));
});

final adaptiveReminderEngineProvider = Provider<AdaptiveReminderEngine>((ref) => const AdaptiveReminderEngine());

final reminderSuggestionProvider = Provider<AsyncValue<ReminderSuggestion?>>((ref) {
  final books = ref.watch(booksProvider);
  final sessions = ref.watch(sessionsProvider);
  if (books is AsyncLoading || sessions is AsyncLoading) return const AsyncLoading();
  if (books.hasError) return AsyncError<ReminderSuggestion?>(books.error!, books.stackTrace!);
  if (sessions.hasError) return AsyncError<ReminderSuggestion?>(sessions.error!, sessions.stackTrace!);
  return AsyncData(ref.read(adaptiveReminderEngineProvider).suggest(books: books.asData?.value ?? const <Book>[], sessions: sessions.asData?.value ?? const <ReadingSession>[], preferences: ref.read(userPreferencesProvider)));
});

final notificationServiceProvider = FutureProvider<NotificationService>((ref) async {
  final service = NotificationService();
  await service.initialize();
  return service;
});

final googleAuthProvider = Provider<GoogleAuthService>((ref) {
  final service = GoogleAuthService();
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

final googleSheetsProvider = Provider<GoogleSheetsService>((ref) => GoogleSheetsService(ref.watch(googleAuthProvider)));

final syncEngineProvider = FutureProvider<SyncEngine>((ref) async {
  return SyncEngine(database: await ref.watch(databaseProvider.future), repository: await ref.watch(bookRepositoryProvider.future), sheetsService: ref.watch(googleSheetsProvider));
});
