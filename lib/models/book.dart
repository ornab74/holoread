enum BookStatus {
  wishlist,
  planned,
  currentlyReading,
  paused,
  completed,
  abandoned,
  rereading,
  archived;

  String get label => switch (this) {
        BookStatus.wishlist => 'Wishlist',
        BookStatus.planned => 'Planned',
        BookStatus.currentlyReading => 'Currently Reading',
        BookStatus.paused => 'Paused',
        BookStatus.completed => 'Completed',
        BookStatus.abandoned => 'Abandoned',
        BookStatus.rereading => 'Re-Reading',
        BookStatus.archived => 'Archived',
      };

  static BookStatus parse(String? value) {
    final normalized = (value ?? '').trim().toLowerCase().replaceAll('-', ' ');
    return switch (normalized) {
      'planned' || 'plan' || 'to read' => BookStatus.planned,
      'currently reading' || 'reading' || 'current' =>
        BookStatus.currentlyReading,
      'paused' || 'on hold' => BookStatus.paused,
      'completed' || 'finished' || 'read' => BookStatus.completed,
      'abandoned' || 'dnf' || 'did not finish' => BookStatus.abandoned,
      're reading' || 'rereading' => BookStatus.rereading,
      'archived' || 'archive' => BookStatus.archived,
      _ => BookStatus.wishlist,
    };
  }
}

class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.status,
    required this.dateAdded,
    required this.updatedAt,
    this.series,
    this.seriesNumber,
    this.isbn10,
    this.isbn13,
    this.dateStarted,
    this.dateFinished,
    this.currentPage = 0,
    this.totalPages = 0,
    this.priority = 3,
    this.rating,
    this.genres = const <String>[],
    this.tags = const <String>[],
    this.format = 'Unknown',
    this.language = 'English',
    this.difficulty = 'Medium',
    this.readingGoal = '',
    this.estimatedMinutes = 0,
    this.reminderPreference = 'Smart',
    this.notes = '',
    this.favoriteQuotes = const <String>[],
    this.recommendationSource = '',
    this.syncVersion = 1,
    this.isDeleted = false,
  });

  final String id;
  final String title;
  final String author;
  final String? series;
  final double? seriesNumber;
  final String? isbn10;
  final String? isbn13;
  final BookStatus status;
  final DateTime dateAdded;
  final DateTime? dateStarted;
  final DateTime? dateFinished;
  final int currentPage;
  final int totalPages;
  final int priority;
  final double? rating;
  final List<String> genres;
  final List<String> tags;
  final String format;
  final String language;
  final String difficulty;
  final String readingGoal;
  final int estimatedMinutes;
  final String reminderPreference;
  final String notes;
  final List<String> favoriteQuotes;
  final String recommendationSource;
  final DateTime updatedAt;
  final int syncVersion;
  final bool isDeleted;

  double get progress => totalPages <= 0
      ? (status == BookStatus.completed ? 1 : 0)
      : (currentPage / totalPages).clamp(0, 1).toDouble();

  int get pagesRemaining =>
      (totalPages - currentPage).clamp(0, totalPages).toInt();

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? series,
    double? seriesNumber,
    String? isbn10,
    String? isbn13,
    BookStatus? status,
    DateTime? dateAdded,
    DateTime? dateStarted,
    DateTime? dateFinished,
    int? currentPage,
    int? totalPages,
    int? priority,
    double? rating,
    List<String>? genres,
    List<String>? tags,
    String? format,
    String? language,
    String? difficulty,
    String? readingGoal,
    int? estimatedMinutes,
    String? reminderPreference,
    String? notes,
    List<String>? favoriteQuotes,
    String? recommendationSource,
    DateTime? updatedAt,
    int? syncVersion,
    bool? isDeleted,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      series: series ?? this.series,
      seriesNumber: seriesNumber ?? this.seriesNumber,
      isbn10: isbn10 ?? this.isbn10,
      isbn13: isbn13 ?? this.isbn13,
      status: status ?? this.status,
      dateAdded: dateAdded ?? this.dateAdded,
      dateStarted: dateStarted ?? this.dateStarted,
      dateFinished: dateFinished ?? this.dateFinished,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      priority: priority ?? this.priority,
      rating: rating ?? this.rating,
      genres: genres ?? this.genres,
      tags: tags ?? this.tags,
      format: format ?? this.format,
      language: language ?? this.language,
      difficulty: difficulty ?? this.difficulty,
      readingGoal: readingGoal ?? this.readingGoal,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      reminderPreference: reminderPreference ?? this.reminderPreference,
      notes: notes ?? this.notes,
      favoriteQuotes: favoriteQuotes ?? this.favoriteQuotes,
      recommendationSource: recommendationSource ?? this.recommendationSource,
      updatedAt: updatedAt ?? this.updatedAt,
      syncVersion: syncVersion ?? this.syncVersion,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
