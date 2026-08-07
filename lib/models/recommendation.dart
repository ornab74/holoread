import 'book.dart';

enum RecommendationMode {
  continueJourney,
  quickRead,
  deepStudy,
  comfortRead,
  challengeMe,
  somethingDifferent,
  finishSeries,
  basedOnFavorites,
  rediscoverLibrary,
  currentMood,
  reachGoal;

  String get label => switch (this) {
        RecommendationMode.continueJourney => 'Continue My Journey',
        RecommendationMode.quickRead => 'Quick Read',
        RecommendationMode.deepStudy => 'Deep Study',
        RecommendationMode.comfortRead => 'Comfort Read',
        RecommendationMode.challengeMe => 'Challenge Me',
        RecommendationMode.somethingDifferent => 'Something Different',
        RecommendationMode.finishSeries => 'Finish a Series',
        RecommendationMode.basedOnFavorites => 'Based on Favorites',
        RecommendationMode.rediscoverLibrary => 'Rediscover My Library',
        RecommendationMode.currentMood => 'Match My Mood',
        RecommendationMode.reachGoal => 'Reach My Goal',
      };
}

class Recommendation {
  const Recommendation({
    required this.book,
    required this.score,
    required this.explanation,
    required this.signals,
    required this.generatedAt,
    this.sourceBookIds = const <String>[],
  });

  final Book book;
  final double score;
  final String explanation;
  final Map<String, double> signals;
  final List<String> sourceBookIds;
  final DateTime generatedAt;
}
