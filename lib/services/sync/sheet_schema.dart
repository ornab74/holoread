import '../../models/book.dart';

class SheetSchema {
  const SheetSchema._();

  static const List<String> headers = <String>[
    'Book ID','Title','Author','Series','Series Number','ISBN-10','ISBN-13','Status','Date Added','Date Started','Date Finished','Current Page','Total Pages','Progress Percentage','Priority','Rating','Genres','Tags','Format','Language','Difficulty','Reading Goal','Estimated Reading Time','Reminder Preference','Personal Notes','Favorite Quotes','Recommendation Source','Last Updated','Deleted','Sync Version',
  ];

  static List<Object?> toRow(Book book) => <Object?>[
        book.id, book.title, book.author, book.series ?? '', book.seriesNumber ?? '', book.isbn10 ?? '', book.isbn13 ?? '', book.status.label, book.dateAdded.toUtc().toIso8601String(), book.dateStarted?.toUtc().toIso8601String() ?? '', book.dateFinished?.toUtc().toIso8601String() ?? '', book.currentPage, book.totalPages, (book.progress * 100).toStringAsFixed(1), book.priority, book.rating ?? '', book.genres.join('|'), book.tags.join('|'), book.format, book.language, book.difficulty, book.readingGoal, book.estimatedMinutes, book.reminderPreference, book.notes, book.favoriteQuotes.join(' ⟡ '), book.recommendationSource, book.updatedAt.toUtc().toIso8601String(), book.isDeleted ? 'TRUE' : 'FALSE', book.syncVersion,
      ];

  static Book fromRow(List<Object?> row) {
    String text(int index) => index < row.length ? '${row[index] ?? ''}'.trim() : '';
    int integer(int index, [int fallback = 0]) => int.tryParse(text(index)) ?? fallback;
    double? decimal(int index) => double.tryParse(text(index));
    DateTime? date(int index) {
      final value = text(index);
      return value.isEmpty ? null : DateTime.tryParse(value)?.toLocal();
    }

    List<String> list(int index, [Pattern separator = '|']) => text(index)
        .split(separator)
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    final now = DateTime.now();
    return Book(
      id: text(0),
      title: text(1).isEmpty ? 'Untitled' : text(1),
      author: text(2).isEmpty ? 'Unknown author' : text(2),
      series: text(3).isEmpty ? null : text(3),
      seriesNumber: decimal(4),
      isbn10: text(5).isEmpty ? null : text(5),
      isbn13: text(6).isEmpty ? null : text(6),
      status: BookStatus.parse(text(7)),
      dateAdded: date(8) ?? now,
      dateStarted: date(9),
      dateFinished: date(10),
      currentPage: integer(11),
      totalPages: integer(12),
      priority: integer(14, 3).clamp(1, 5).toInt(),
      rating: decimal(15),
      genres: list(16),
      tags: list(17),
      format: text(18).isEmpty ? 'Unknown' : text(18),
      language: text(19).isEmpty ? 'English' : text(19),
      difficulty: text(20).isEmpty ? 'Medium' : text(20),
      readingGoal: text(21),
      estimatedMinutes: integer(22),
      reminderPreference: text(23).isEmpty ? 'Smart' : text(23),
      notes: text(24),
      favoriteQuotes: list(25, ' ⟡ '),
      recommendationSource: text(26),
      updatedAt: date(27) ?? now,
      isDeleted: const <String>{'true', '1', 'yes'}.contains(text(28).toLowerCase()),
      syncVersion: integer(29, 1),
    );
  }
}
