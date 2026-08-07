import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/glass_panel.dart';
import '../../models/book.dart';
import '../../shared/providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksValue = ref.watch(booksProvider);
    final recommendationValue = ref.watch(recommendationsProvider);
    final reminderValue = ref.watch(reminderSuggestionProvider);

    return booksValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorState(message: '$error'),
      data: (books) {
        final current = books
            .where((book) => book.status == BookStatus.currentlyReading)
            .firstOrNull;
        final completed = books
            .where((book) => book.status == BookStatus.completed)
            .length;
        final totalPages = books.fold<int>(0, (sum, book) => sum + book.currentPage);
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
          children: <Widget>[
            Text(
              'Reading intelligence online',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your encrypted library, adaptive rhythm, and Mechanis suggestions.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 22),
            if (current != null)
              GlassPanel(
                onTap: () => context.push('/book/${current.id}'),
                child: Row(
                  children: <Widget>[
                    _BookGlyph(progress: current.progress),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text('CURRENT SIGNAL'),
                          const SizedBox(height: 6),
                          Text(
                            current.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(current.author),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: current.progress,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(current.progress * 100).round()}% • '
                            '${current.pagesRemaining} pages remaining',
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              )
            else
              const GlassPanel(
                child: Text('Choose a book from your library to begin a reading signal.'),
              ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 720;
                final cards = <Widget>[
                  _MetricCard(
                    label: 'Completed',
                    value: '$completed',
                    icon: Icons.auto_stories_rounded,
                  ),
                  _MetricCard(
                    label: 'Pages traversed',
                    value: '$totalPages',
                    icon: Icons.insights_rounded,
                  ),
                  _MetricCard(
                    label: 'Library nodes',
                    value: '${books.length}',
                    icon: Icons.hub_rounded,
                  ),
                ];
                return wide
                    ? Row(
                        children: cards
                            .map(
                              (card) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: card,
                                ),
                              ),
                            )
                            .toList(),
                      )
                    : Column(
                        children: cards
                            .map(
                              (card) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: card,
                              ),
                            )
                            .toList(),
                      );
              },
            ),
            const SizedBox(height: 4),
            reminderValue.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (suggestion) => suggestion == null
                  ? const SizedBox.shrink()
                  : GlassPanel(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Icon(Icons.notifications_active_rounded, size: 30),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Adaptive reminder',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 5),
                                Text(suggestion.body),
                                const SizedBox(height: 8),
                                Text(
                                  'Confidence ${(suggestion.confidence * 100).round()}%',
                                  style: Theme.of(context).textTheme.labelMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            recommendationValue.when(
              loading: () => const GlassPanel(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => GlassPanel(child: Text('$error')),
              data: (items) {
                if (items.isEmpty) return const SizedBox.shrink();
                final recommendation = items.first;
                return GlassPanel(
                  onTap: () => context.push('/book/${recommendation.book.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(Icons.psychology_alt_rounded),
                          const SizedBox(width: 8),
                          Text(
                            'MECHANIS TOP MATCH',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const Spacer(),
                          Text('${recommendation.score.round()}%'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        recommendation.book.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(recommendation.book.author),
                      const SizedBox(height: 10),
                      Text(recommendation.explanation),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _BookGlyph extends StatelessWidget {
  const _BookGlyph({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 78,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 7,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
          ),
          const Icon(Icons.menu_book_rounded, size: 34),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Row(
        children: <Widget>[
          Icon(icon, size: 30),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              Text(label),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('HoloRead could not initialize: $message'),
        ),
      );
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
