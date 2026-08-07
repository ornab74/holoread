import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/glass_panel.dart';
import '../../models/recommendation.dart';
import '../../shared/providers.dart';

class RecommendationsScreen extends ConsumerWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(recommendationModeProvider);
    final recommendations = ref.watch(recommendationsProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      children: <Widget>[
        Text(
          'Mechanis chamber',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Every recommendation is scored locally and includes the reasons behind it.',
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: RecommendationMode.values
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(item.label),
                      selected: mode == item,
                      onSelected: (_) => ref
                          .read(recommendationModeProvider.notifier)
                          .select(item),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 18),
        recommendations.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => GlassPanel(child: Text('$error')),
          data: (items) => Column(
            children: items
                .map(
                  (recommendation) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: GlassPanel(
                      onTap: () => context.push('/book/${recommendation.book.id}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              CircleAvatar(
                                radius: 24,
                                child: Text('${recommendation.score.round()}'),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      recommendation.book.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    Text(recommendation.book.author),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_rounded),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(recommendation.explanation),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: recommendation.signals.entries
                                .where((entry) => entry.value > 0.4)
                                .take(4)
                                .map(
                                  (entry) => Chip(
                                    label: Text(
                                      '${entry.key} ${(entry.value * 100).round()}%',
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
