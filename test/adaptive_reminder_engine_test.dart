import 'package:flutter_test/flutter_test.dart';
import 'package:holoread/models/book.dart';
import 'package:holoread/models/reading_session.dart';
import 'package:holoread/models/user_preferences.dart';
import 'package:holoread/services/reminders/adaptive_reminder_engine.dart';

void main() {
  test('reminder avoids configured quiet hours', () {
    final now = DateTime(2026, 8, 6, 20);
    final book = Book(
      id: 'book',
      title: 'Test Book',
      author: 'Author',
      status: BookStatus.currentlyReading,
      dateAdded: now,
      updatedAt: now,
      currentPage: 50,
      totalPages: 300,
    );
    final sessions = <ReadingSession>[
      ReadingSession(
        id: 'session',
        bookId: 'book',
        startedAt: DateTime(2026, 8, 5, 23, 30),
        endedAt: DateTime(2026, 8, 5, 23, 50),
        pagesRead: 12,
        minutesRead: 20,
      ),
    ];

    final result = const AdaptiveReminderEngine().suggest(
      books: <Book>[book],
      sessions: sessions,
      preferences: const UserPreferences(
        quietStartHour: 23,
        quietEndHour: 8,
      ),
      now: now,
    );

    expect(result, isNotNull);
    expect(result!.scheduledAt.hour, 8);
  });
}
