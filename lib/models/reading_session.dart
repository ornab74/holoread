class ReadingSession {
  const ReadingSession({
    required this.id,
    required this.bookId,
    required this.startedAt,
    required this.endedAt,
    required this.pagesRead,
    required this.minutesRead,
    this.mood = 'Neutral',
    this.locationCategory = 'Unknown',
    this.focusScore = 3,
    this.notes = '',
  });

  final String id;
  final String bookId;
  final DateTime startedAt;
  final DateTime endedAt;
  final int pagesRead;
  final int minutesRead;
  final String mood;
  final String locationCategory;
  final int focusScore;
  final String notes;
}
