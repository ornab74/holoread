import 'package:flutter_test/flutter_test.dart';
import 'package:holoread/models/book.dart';
import 'package:holoread/models/recommendation.dart';
import 'package:holoread/models/user_preferences.dart';
import 'package:holoread/services/recommendations/mechanis_engine.dart';

void main() {
  test('Mechanis ranks a high-priority genre match above a poor match', () {
    final now = DateTime(2026, 8, 6);
    final library = <Book>[
      Book(
        id: 'favorite',
        title: 'Favorite',
        author: 'A',
        status: BookStatus.completed,
        dateAdded: now,
        updatedAt: now,
        rating: 5,
        genres: const <String>['Science Fiction'],
      ),
      Book(
        id: 'match',
        title: 'Strong Match',
        author: 'B',
        status: BookStatus.wishlist,
        dateAdded: now,
        updatedAt: now,
        priority: 5,
        totalPages: 320,
        genres: const <String>['Science Fiction'],
      ),
      Book(
        id: 'mismatch',
        title: 'Weak Match',
        author: 'C',
        status: BookStatus.wishlist,
        dateAdded: now,
        updatedAt: now,
        priority: 1,
        totalPages: 900,
        genres: const <String>['Unrelated'],
      ),
    ];

    final result = const MechanisEngine().recommend(
      library: library,
      preferences: const UserPreferences(
        preferredGenres: <String>['Science Fiction'],
      ),
      mode: RecommendationMode.basedOnFavorites,
    );

    expect(result.first.book.id, 'match');
    expect(result.first.explanation, contains('Mechanis recommends'));
  });
}
