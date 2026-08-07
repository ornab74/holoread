import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/glass_panel.dart';
import '../../models/book.dart';
import '../../models/reading_session.dart';
import '../../shared/providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(booksProvider);
    final sessions = ref.watch(sessionsProvider);
    if (books is AsyncLoading || sessions is AsyncLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (books.hasError) return Center(child: Text('${books.error}'));
    if (sessions.hasError) return Center(child: Text('${sessions.error}'));
    final library = books.asData?.value ?? const <Book>[];
    final history = sessions.asData?.value ?? const <ReadingSession>[];
    final completed = library.where((book) => book.status == BookStatus.completed).length;
    final minutes = history.fold<int>(0, (sum, item) => sum + item.minutesRead);
    final pages = history.fold<int>(0, (sum, item) => sum + item.pagesRead);
    final averageSession = history.isEmpty ? 0 : minutes / history.length;
    final genreCounts = <String, int>{};
    for (final book in library) {
      for (final genre in book.genres) {
        genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
      }
    }
    final sortedGenres = genreCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      children: <Widget>[
        Text(
          'Reading telemetry',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            _Stat(label: 'Books completed', value: '$completed'),
            _Stat(label: 'Focused minutes', value: '$minutes'),
            _Stat(label: 'Pages in sessions', value: '$pages'),
            _Stat(label: 'Average session', value: '${averageSession.round()} min'),
          ],
        ),
        const SizedBox(height: 16),
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Genre field', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              if (sortedGenres.isEmpty)
                const Text('Add genres to reveal your reading distribution.')
              else
                ...sortedGenres.take(8).map(
                  (entry) {
                    final max = sortedGenres.first.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(child: Text(entry.key)),
                              Text('${entry.value}'),
                            ],
                          ),
                          const SizedBox(height: 5),
                          LinearProgressIndicator(value: entry.value / max),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassPanel(
          child: Text(
            history.isEmpty
                ? 'Start recording reading sessions to let HoloRead infer your strongest reading windows.'
                : 'You have recorded ${history.length} sessions. Mechanis uses their time and pace locally to make reminder timing more realistic.',
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: GlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(label),
          ],
        ),
      ),
    );
  }
}
