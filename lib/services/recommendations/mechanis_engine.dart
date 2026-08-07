import 'dart:math' as math;

import 'package:collection/collection.dart';

import '../../models/book.dart';
import '../../models/recommendation.dart';
import '../../models/user_preferences.dart';

class MechanisEngine {
  const MechanisEngine();

  List<Recommendation> recommend({
    required List<Book> library,
    required UserPreferences preferences,
    RecommendationMode mode = RecommendationMode.continueJourney,
    int limit = 12,
  }) {
    final candidates = library
        .where(
          (book) => !book.isDeleted &&
              book.status != BookStatus.completed &&
              book.status != BookStatus.abandoned &&
              book.status != BookStatus.archived,
        )
        .toList(growable: false);
    final favorites = library
        .where(
          (book) => book.status == BookStatus.completed && (book.rating ?? 0) >= 4,
        )
        .toList(growable: false);
    final disliked = library
        .where(
          (book) => book.status == BookStatus.abandoned || (book.rating ?? 5) <= 2,
        )
        .toList(growable: false);

    final scored = candidates.map((book) {
      final signals = <String, double>{};
      signals['priority'] = book.priority / 5;
      signals['genre affinity'] = _genreAffinity(book, favorites, preferences);
      signals['author affinity'] = _authorAffinity(book, favorites, preferences);
      signals['length fit'] = _lengthFit(book, preferences, mode);
      signals['difficulty fit'] = _difficultyFit(book, preferences, mode);
      signals['series continuity'] = _seriesContinuity(book, library, mode);
      signals['goal alignment'] = _goalAlignment(book, preferences, mode);
      signals['novelty'] = _novelty(book, favorites, mode);
      signals['completion likelihood'] = _completionLikelihood(book, mode);
      signals['negative history'] = -_negativeHistory(book, disliked);

      final weights = _weightsFor(mode);
      var weighted = 0.0;
      var denominator = 0.0;
      for (final entry in signals.entries) {
        final weight = weights[entry.key] ?? 0.5;
        weighted += entry.value * weight;
        denominator += weight.abs();
      }
      final normalized = denominator == 0 ? 0 : weighted / denominator;
      final score = (50 + normalized * 50).clamp(0, 100).toDouble();
      return Recommendation(
        book: book,
        score: score,
        explanation: _explain(book, signals, mode),
        signals: signals,
        sourceBookIds: favorites.take(3).map((book) => book.id).toList(),
        generatedAt: DateTime.now(),
      );
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));
    return _diversify(scored, limit);
  }

  double _genreAffinity(
    Book book,
    List<Book> favorites,
    UserPreferences preferences,
  ) {
    final target = book.genres.map((genre) => genre.toLowerCase()).toSet();
    if (target.isEmpty) return 0.15;
    final favoriteGenres = <String>{
      ...preferences.preferredGenres.map((genre) => genre.toLowerCase()),
      ...favorites.expand((book) => book.genres).map((genre) => genre.toLowerCase()),
    };
    final avoided = preferences.avoidedGenres
        .map((genre) => genre.toLowerCase())
        .toSet();
    if (target.intersection(avoided).isNotEmpty) return -1;
    return target.intersection(favoriteGenres).length / target.length;
  }

  double _authorAffinity(
    Book book,
    List<Book> favorites,
    UserPreferences preferences,
  ) {
    final author = book.author.toLowerCase();
    if (preferences.favoriteAuthors.any((item) => item.toLowerCase() == author)) {
      return 1;
    }
    return favorites.any((item) => item.author.toLowerCase() == author) ? 0.85 : 0;
  }

  double _lengthFit(
    Book book,
    UserPreferences preferences,
    RecommendationMode mode,
  ) {
    if (book.totalPages <= 0) return 0.2;
    final target = switch (mode) {
      RecommendationMode.quickRead => 220,
      RecommendationMode.deepStudy => 600,
      RecommendationMode.challengeMe => 700,
      _ => preferences.preferredBookLength,
    };
    final difference = (book.totalPages - target).abs();
    return math.max(0, 1 - difference / math.max(target, 1)).toDouble();
  }

  double _difficultyFit(
    Book book,
    UserPreferences preferences,
    RecommendationMode mode,
  ) {
    const levels = <String, int>{'Easy': 1, 'Medium': 2, 'Hard': 3, 'Expert': 4};
    final bookLevel = levels[book.difficulty] ?? 2;
    final target = switch (mode) {
      RecommendationMode.comfortRead => 1,
      RecommendationMode.challengeMe => 4,
      _ => levels[preferences.preferredDifficulty] ?? 2,
    };
    return 1 - ((bookLevel - target).abs() / 3);
  }

  double _seriesContinuity(
    Book book,
    List<Book> library,
    RecommendationMode mode,
  ) {
    if (book.series == null || book.series!.isEmpty) return 0;
    final completedInSeries = library.where(
      (item) =>
          item.series?.toLowerCase() == book.series!.toLowerCase() &&
          item.status == BookStatus.completed,
    );
    if (completedInSeries.isEmpty) return 0.15;
    return mode == RecommendationMode.finishSeries ? 1 : 0.65;
  }

  double _goalAlignment(
    Book book,
    UserPreferences preferences,
    RecommendationMode mode,
  ) {
    final corpus = '${book.readingGoal} ${book.tags.join(' ')} ${book.genres.join(' ')}'
        .toLowerCase();
    final goalTokens = preferences.learningGoal
        .toLowerCase()
        .split(RegExp(r'\W+'))
        .where((token) => token.length > 3)
        .toSet();
    if (goalTokens.isEmpty) return mode == RecommendationMode.reachGoal ? 0.1 : 0.25;
    final matches = goalTokens.where(corpus.contains).length;
    return (matches / goalTokens.length).clamp(0, 1).toDouble();
  }

  double _novelty(
    Book book,
    List<Book> favorites,
    RecommendationMode mode,
  ) {
    final favoriteGenres = favorites.expand((book) => book.genres).toSet();
    final overlap = book.genres.where(favoriteGenres.contains).length;
    if (mode == RecommendationMode.somethingDifferent) {
      return book.genres.isEmpty ? 0.4 : 1 - overlap / book.genres.length;
    }
    return overlap == 0 ? 0.35 : 0.65;
  }

  double _completionLikelihood(Book book, RecommendationMode mode) {
    if (book.status == BookStatus.currentlyReading) return 1;
    if (book.status == BookStatus.paused) return 0.55;
    if (mode == RecommendationMode.quickRead && book.totalPages <= 250) return 0.9;
    if (book.priority >= 4) return 0.75;
    return 0.5;
  }

  double _negativeHistory(Book book, List<Book> disliked) {
    final dislikedGenres = disliked.expand((item) => item.genres).toSet();
    final overlap = book.genres.where(dislikedGenres.contains).length;
    return book.genres.isEmpty ? 0.0 : overlap / book.genres.length;
  }

  Map<String, double> _weightsFor(RecommendationMode mode) {
    final weights = <String, double>{
      'priority': 1.0,
      'genre affinity': 1.4,
      'author affinity': 1.0,
      'length fit': 0.9,
      'difficulty fit': 0.7,
      'series continuity': 0.7,
      'goal alignment': 0.9,
      'novelty': 0.5,
      'completion likelihood': 1.1,
      'negative history': 1.3,
    };
    switch (mode) {
      case RecommendationMode.quickRead:
        weights['length fit'] = 2.4;
        weights['completion likelihood'] = 1.8;
        break;
      case RecommendationMode.deepStudy:
        weights['goal alignment'] = 2.2;
        weights['difficulty fit'] = 1.5;
        break;
      case RecommendationMode.finishSeries:
        weights['series continuity'] = 3;
        break;
      case RecommendationMode.somethingDifferent:
        weights['novelty'] = 2.8;
        weights['genre affinity'] = 0.5;
        break;
      case RecommendationMode.challengeMe:
        weights['difficulty fit'] = 2.2;
        break;
      case RecommendationMode.basedOnFavorites:
        weights['genre affinity'] = 2.1;
        weights['author affinity'] = 1.8;
        break;
      case RecommendationMode.reachGoal:
        weights['goal alignment'] = 2.8;
        break;
      default:
        break;
    }
    return weights;
  }

  String _explain(
    Book book,
    Map<String, double> signals,
    RecommendationMode mode,
  ) {
    final rankedSignals = signals.entries
        .where((entry) => entry.value > 0.45)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final positives = rankedSignals
        .take(3)
        .map((entry) => entry.key)
        .toList();
    final reasons = positives.isEmpty
        ? 'it adds useful variety to your library'
        : positives.join(', ');
    return 'Mechanis recommends ${book.title} for “${mode.label}” because of '
        '$reasons. The score is explainable and uses only your local library profile.';
  }

  List<Recommendation> _diversify(
    List<Recommendation> ranked,
    int limit,
  ) {
    final result = <Recommendation>[];
    final authorCounts = <String, int>{};
    final genreCounts = <String, int>{};
    for (final recommendation in ranked) {
      final author = recommendation.book.author.toLowerCase();
      final primaryGenre = recommendation.book.genres.firstOrNull?.toLowerCase();
      if ((authorCounts[author] ?? 0) >= 2) continue;
      if (primaryGenre != null && (genreCounts[primaryGenre] ?? 0) >= 3) continue;
      result.add(recommendation);
      authorCounts[author] = (authorCounts[author] ?? 0) + 1;
      if (primaryGenre != null) {
        genreCounts[primaryGenre] = (genreCounts[primaryGenre] ?? 0) + 1;
      }
      if (result.length >= limit) break;
    }
    return result;
  }
}
