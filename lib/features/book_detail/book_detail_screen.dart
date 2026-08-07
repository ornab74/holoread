import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/widgets/glass_panel.dart';
import '../../models/book.dart';
import '../../models/reading_session.dart';
import '../../shared/providers.dart';

class BookDetailScreen extends ConsumerWidget {
  const BookDetailScreen({required this.bookId, super.key});
  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksValue = ref.watch(booksProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Book signal'),
      ),
      body: booksValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (books) {
          final book = books.where((item) => item.id == bookId).firstOrNull;
          if (book == null) return const Center(child: Text('Book not found.'));
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 60),
            children: <Widget>[
              GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 92,
                          height: 132,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              colors: <Color>[Color(0xFF7B61FF), Color(0xFF16C7E8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(Icons.menu_book_rounded, size: 48),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                book.title,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(book.author),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: <Widget>[
                                  Chip(label: Text(book.status.label)),
                                  ...book.genres.take(3).map((genre) => Chip(label: Text(genre))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    LinearProgressIndicator(value: book.progress, minHeight: 10),
                    const SizedBox(height: 8),
                    Text('${(book.progress * 100).round()}% complete'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Progress control', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    _ProgressEditor(book: book),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Private notes', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(book.notes.isEmpty ? 'No encrypted notes yet.' : book.notes),
                    if (book.readingGoal.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 14),
                      Text('Goal: ${book.readingGoal}'),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressEditor extends ConsumerStatefulWidget {
  const _ProgressEditor({required this.book});
  final Book book;

  @override
  ConsumerState<_ProgressEditor> createState() => _ProgressEditorState();
}

class _ProgressEditorState extends ConsumerState<_ProgressEditor> {
  late double _page;

  @override
  void initState() {
    super.initState();
    _page = widget.book.currentPage.toDouble();
  }

  @override
  void didUpdateWidget(covariant _ProgressEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.book.id != widget.book.id ||
        oldWidget.book.currentPage != widget.book.currentPage) {
      _page = widget.book.currentPage.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final max = widget.book.totalPages <= 0 ? 1000.0 : widget.book.totalPages.toDouble();
    return Column(
      children: <Widget>[
        Slider(
          value: _page.clamp(0, max).toDouble(),
          max: max,
          divisions: max.round().clamp(1, 1000).toInt(),
          label: _page.round().toString(),
          onChanged: (value) => setState(() => _page = value),
        ),
        Row(
          children: <Widget>[
            Text('Page ${_page.round()}'),
            const Spacer(),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save session'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _save() async {
    final repository = await ref.read(bookRepositoryProvider.future);
    final pagesRead =
        (_page.round() - widget.book.currentPage).clamp(0, 1000000).toInt();
    await repository.updateProgress(widget.book.id, _page.round());
    if (pagesRead > 0) {
      final end = DateTime.now();
      await repository.addSession(
        ReadingSession(
          id: const Uuid().v4(),
          bookId: widget.book.id,
          startedAt: end.subtract(Duration(minutes: (pagesRead * 1.5).round())),
          endedAt: end,
          pagesRead: pagesRead,
          minutesRead: (pagesRead * 1.5).round().clamp(1, 10000).toInt(),
          focusScore: 4,
        ),
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Progress encrypted and saved.')),
      );
    }
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
