import 'dart:math' as math;

import '../../models/book.dart';
import '../../models/reading_session.dart';
import '../../models/user_preferences.dart';

class ReminderSuggestion {
  const ReminderSuggestion({
    required this.book,
    required this.scheduledAt,
    required this.title,
    required this.body,
    required this.confidence,
  });

  final Book book;
  final DateTime scheduledAt;
  final String title;
  final String body;
  final double confidence;
}

class AdaptiveReminderEngine {
  const AdaptiveReminderEngine();

  ReminderSuggestion? suggest({
    required List<Book> books,
    required List<ReadingSession> sessions,
    required UserPreferences preferences,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final active = books
        .where(
          (book) =>
              book.status == BookStatus.currentlyReading ||
              book.status == BookStatus.rereading ||
              book.status == BookStatus.paused,
        )
        .toList();
    if (active.isEmpty) return null;
    active.sort((a, b) {
      final statusA = a.status == BookStatus.currentlyReading ? 2 : 0;
      final statusB = b.status == BookStatus.currentlyReading ? 2 : 0;
      return (statusB + b.priority).compareTo(statusA + a.priority);
    });
    final book = active.first;

    final history = sessions.where((session) => session.bookId == book.id).toList();
    final inferredHour = history.isEmpty
        ? preferences.preferredReminderHour
        : (history.map((session) => session.startedAt.hour).reduce((a, b) => a + b) /
                history.length)
            .round();
    var scheduled = DateTime(clock.year, clock.month, clock.day, inferredHour);
    if (!scheduled.isAfter(clock.add(const Duration(minutes: 10)))) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    scheduled = _moveOutsideQuietHours(scheduled, preferences);

    final pagesPerMinute = _pagesPerMinute(history);
    final sessionMinutes = preferences.dailyMinutesGoal.clamp(10, 60);
    final projectedPages = math.max(1, (pagesPerMinute * sessionMinutes).round());
    final remaining = book.pagesRemaining;
    final confidence = history.isEmpty ? 0.58 : (0.68 + history.length * 0.03).clamp(0, 0.92);

    return ReminderSuggestion(
      book: book,
      scheduledAt: scheduled,
      title: 'Your HoloRead window is approaching',
      body: remaining > 0
          ? 'A $sessionMinutes-minute session with ${book.title} could move you '
              'about $projectedPages pages closer, with $remaining pages remaining.'
          : 'A focused $sessionMinutes-minute session with ${book.title} fits your '
              'usual reading rhythm.',
      confidence: confidence.toDouble(),
    );
  }

  DateTime _moveOutsideQuietHours(
    DateTime value,
    UserPreferences preferences,
  ) {
    final start = preferences.quietStartHour;
    final end = preferences.quietEndHour;
    final isQuiet = start > end
        ? value.hour >= start || value.hour < end
        : value.hour >= start && value.hour < end;
    if (!isQuiet) return value;
    final next = DateTime(value.year, value.month, value.day, end);
    return next.isAfter(value) ? next : next.add(const Duration(days: 1));
  }

  double _pagesPerMinute(List<ReadingSession> history) {
    final totalMinutes = history.fold<int>(0, (sum, item) => sum + item.minutesRead);
    final totalPages = history.fold<int>(0, (sum, item) => sum + item.pagesRead);
    if (totalMinutes <= 0 || totalPages <= 0) return 0.65;
    return (totalPages / totalMinutes).clamp(0.05, 3).toDouble();
  }
}
